require "constants"
local DebugPanel = require("dbui/debug_panel")

local WidgetDebug = Class(function(self, owner)
    self.owner = owner

    -- I've seen occasional crashes that the imgui lua bindings do not exist
    -- from loading imgui on startup (when it's require'd at the top of this
    -- file). Disabling it on start and hotloading later show the bindings are
    -- loaded. So let's defer loading until widgets are created.
    self.imgui = require("dbui/imgui")

    self.is_debugging_widgets = false
    self:_ClearState()

    self.panel = DebugPanel()
end)

function WidgetDebug:_ClearState()
    self.debug_widget_idx = -1
    self.debug_widget_candidates = {}
    self.debug_widget_target = nil
end

function WidgetDebug:EnableWidgetDebugging()
    self:_ClearState()
    self.is_debugging_widgets = true
end

function WidgetDebug:_CaptureAndAddDebugCandidates(dbui)
    if TheInput:IsKeyDown(KEY_CTRL) then
        self.debug_widget_candidates = {}

        local widget_options = self.owner:GetIntermediateFocusWidgets()
        -- We probably want the top of the stack.
        self.debug_widget_target = widget_options[#widget_options]
        -- Also include the current focus. However, this is often junk.
        table.insert(widget_options, self.owner:GetFocusWidget())
        for i,widget in ipairs(widget_options) do
            table.insert(self.debug_widget_candidates, widget)
        end
    end

    dbui.Text("Tap Ctrl to capture widgets under mouse.")
    dbui.Text("d_getwidget() returns captured widget in console.")

    -- Build list of widgets to select. (See Combo doc.)
    local widget_names = {}
    for i,widget in ipairs(self.debug_widget_candidates) do
        local name = widget.name
        if type(name) ~= "string" then
            -- Some widgets have tables in their name field (like PlayerList).
            name = "-unnamed widget-"
        end
        table.insert(widget_names, name)
        -- If the current target is in this list, select it.
        if widget == self.debug_widget_target then
            self.debug_widget_idx = i - 1
        end
    end
    local combo_widgets = table.concat(widget_names, "\0") .. "\0\0"

    local value_changed = false
    value_changed, self.debug_widget_idx = dbui.Combo("Capture Stack", self.debug_widget_idx, combo_widgets)
    if value_changed and self.debug_widget_idx > -1 then
        self.debug_widget_target = self.debug_widget_candidates[self.debug_widget_idx + 1]
    end

    dbui.Value("Found widgets", #self.debug_widget_candidates)
end

function WidgetDebug:_AppendChildren(dbui, widget, next_id)
    for k,child in pairs(widget:GetChildren()) do
        dbui.PushID(next_id)
        next_id = next_id + 1

        dbui.SetNextTreeNodeOpen(true, dbui.constant.SetCond.Appearing)
        if dbui.TreeNode(tostring(child)) then
            dbui.SameLine()
            if dbui.SmallButton("Debug me") then
                print(self.debug_widget_target ,child)
                self.debug_widget_target = child
                print(self.debug_widget_target ,child)
            end

            next_id = self:_AppendChildren(dbui, child, next_id)

            dbui.TreePop()
        end
        dbui.PopID()
    end

    return next_id
end

function WidgetDebug:Update(dt)
    if self.is_debugging_widgets then
        self.panel:StartFrame()

        local dbui = self.imgui
        local should_draw = true
        should_draw, self.is_debugging_widgets = dbui.Begin("Widget Selector", self.is_debugging_widgets) do
            if should_draw then
                self:_CaptureAndAddDebugCandidates(dbui)

                -- Spacer
                dbui.Text("")

                if self.debug_widget_target then
                    self.debug_widget_target:DebugDraw_AddSection(dbui)
                    self.panel:AppendEditableTable(dbui, self.debug_widget_target, "Widget Data")

                    if dbui.TreeNode("Child Picker") then
                        self:_AppendChildren(dbui, self.debug_widget_target, 0)
                        dbui.TreePop()
                    end
                end
            end
        end
        dbui.End()

    else
        self:_ClearState()
    end
end

return WidgetDebug
