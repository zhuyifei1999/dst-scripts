require "constants"
local DebugPanel = require("dbui/debug_panel")

local EntityDebug = Class(function(self, owner)
    self.owner = owner

    -- I've seen occasional crashes that the imgui lua bindings do not exist
    -- from loading imgui on startup (when it's require'd at the top of this
    -- file). Disabling it on start and hotloading later show the bindings are
    -- loaded. So let's defer loading.
    self.imgui = require("dbui/imgui")

    self.is_debugging_entity = false

    self.panel = DebugPanel()
end)

function EntityDebug:EnableEntityDebugging()
    self.is_debugging_entity = true
end

function EntityDebug:Update(dt)
    if self.is_debugging_entity then
        self.panel:StartFrame()

        local dbui = self.imgui
        local ent = GetDebugEntity()
        local should_draw
        should_draw, self.is_debugging_entity = dbui.Begin("Entity Data", true)
        if should_draw then
            if ent then
                dbui.SetNextTreeNodeOpen(true, dbui.constant.SetCond.Appearing)
                self.panel:AppendEditableTable(dbui, ent, tostring(ent))
            else
                dbui.Text("Selected: <nil>")
                dbui.Text("Mouse over an object and press F1 to select it.")
            end
        end
        dbui.End()
    end
end

return EntityDebug
