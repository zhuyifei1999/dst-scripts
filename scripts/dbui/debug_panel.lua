-------------------------------------------------
-- Renders a debug panel with immediate mode GUI.
--
-- This is an extremely cut down version from Caravan (no DebugNodes). Consider
-- looking there to pull stuff rather than just adding more functionality here.

local next_uid = 1

local DebugPanel = Class(function(self)
    self.uid = next_uid
    next_uid = next_uid + 1

    self:StartFrame()
end)

-- You must call StartFrame before other functions!
function DebugPanel:StartFrame()
    -- For ensuring ID uniqueness of different widgets with the same values.
    self.frame_uid = self.uid * 1000
end

----------------------------------------------------------------------
-- Helper wrappers for composite imgui rendering.

function DebugPanel:CollapsingHeader( ui, title, flags )
    return ui.CollapsingHeader( title, flags or ui.constant.TreeNodeFlags.DefaultOpen )
end

function DebugPanel:AddDebugMenu( ui, menu, menu_params )
    menu_params = menu_params or {}
    for i, option in ipairs( menu ) do
        if option.Visible == false or (type(option.Visible) == "function" and not option.Visible( unpack( menu_params ))) then
            -- Invalid for this thingy.
        else
            local txt
            if type(option.Text) == "string" then
                txt = option.Text
            elseif type(option.Text) == "function" then
                txt = option.Text( unpack( menu_params ) )
            else
                ui.Separator()
            end

            if txt then
                local checked = type(option.Checked) == "function" and option.Checked( unpack( menu_params ))
                local enabled, tt = true
                if type(option.Enabled) == "function" then
                    enabled, tt = option.Enabled( unpack( menu_params ))
                end
                if option.Menu then
                    local menu = type(option.Menu) == "function" and option.Menu( unpack( menu_params) ) or option.Menu
                    if ui.BeginMenu( txt, enabled ) then
                        self:AddDebugMenu( ui, menu, menu_params )
                        ui.EndMenu()
                    end

                elseif option.CustomMenu then
                    if ui.BeginMenu( txt, enabled ) then
                        option:CustomMenu( ui, unpack( menu_params ))
                        ui.EndMenu()
                    end

                elseif ui.MenuItem( txt, nil, checked, enabled ) then
                    -- TODO(dbriscoe): This is somewhat dangerous. Using xpcall
                    -- would be safer. (Would be good to have a central
                    -- DebugManager.)
                    option.Do(unpack(menu_params))
                end
                if tt and ui.IsItemHovered() then
                    ui.SetTooltip( tt )
                end
            end
        end
    end
end

function DebugPanel:_AppendNonTableValue( ui, v )
    if type(v) == "string" then
        ui.TextColored( 0.46, 0.46, 1.0, 1.0, v )

    elseif type(v) == "function" then
        ui.TextColored( 1.0, 0.46, 0.33, 1.0, tostring(v) )

    elseif type(v) == "userdata" then
        ui.TextColored( 0.33, 0.8, 0.73, 1.0, tostring(v) )

    else
        ui.Text( tostring(v) )

    end
end

function DebugPanel:AppendTable( ui, t, name )
    -- We need to push a unique ID to support multiple tables with the same
    -- name.
    ui.PushID( self.frame_uid )
    if ui.TreeNode( name or tostring(t) ) then
        for k, v in pairs(t) do
            if type(v) == "table" then
                self:AppendTable( ui, v, tostring(k) )
            else
                -- Key
                ui.Text( tostring(k)..":" )
                ui.SameLine( nil, 10 )
                -- Value
                self:_AppendNonTableValue(ui, v)
            end
        end
        ui.TreePop()
    end
    ui.PopID()
    self.frame_uid = self.frame_uid + 1
end

function DebugPanel:AppendEditableTable( ui, t, name )
    -- We need to push a unique ID to support multiple tables with the same
    -- name.
    ui.PushID( self.frame_uid )
    if ui.TreeNode( name or tostring(t) ) then
        for k, v in pairs(t) do
            if type(v) == "table" then
                self:AppendEditableTable( ui, v, tostring(k) )
            else
                local _ = nil
                if type(v) == "string" then
                    local new_value = ui.InputText(tostring(k), v)
                    if new_value then
                        t[k] = new_value
                    end

                elseif type(v) == "number" then
                    local was_modified, new_value = ui.InputFloat(tostring(k), v, 0.1, 10)
                    if was_modified then
                        t[k] = new_value
                    end

                elseif type(v) == "boolean" then
                    local was_modified, new_value = ui.Checkbox(tostring(k), v)
                    if was_modified then
                        t[k] = new_value
                    end

                else
                    ui.Text( tostring(k)..":" )
                    ui.SameLine( nil, 10 )
                    self:_AppendNonTableValue(ui, v)

                end
            end
        end
        ui.TreePop()
    end
    ui.PopID()
    self.frame_uid = self.frame_uid + 1
end

function DebugPanel:AppendKeyValue( ui, key, v )
    -- Key
    if type(key) == "table" then
        self:AppendTable( ui, key )
    else
        ui.Text( tostring(key) )
    end
    ui.NextColumn()
    -- Value
    if type(v) == "table" then
        self:AppendTable( ui, v )

    else
        self:_AppendNonTableValue(ui, v)

    end

    ui.NextColumn()
end

-- Helper for creating tabular data.
--
-- column_headers is an array of strings: {"name", "age"}
-- data is an array of arrays containing values: { {'wilson', 2 }, {'wes', 6} })
function DebugPanel:AppendTabularData( ui, column_headers, data)
    ui.Columns( #column_headers, "tabular", true )
    for k, v in ipairs(column_headers) do
        ui.TextColored(0.33, 0.8, 0.73, 1.0, tostring(v))
        ui.NextColumn()
    end
    ui.Separator()
    for k, v in ipairs(data) do
        for c = 1, #column_headers do
            if c <= #v then
                if type(v[c]) == "table" and v[c].name and v[c].table then
                    self:AppendTable(ui, v[c].table, v[c].name)
                else
                    ui.Text(tostring(v[c]))
                end
            end
            ui.NextColumn()
        end
    end
    ui.Separator()
    ui.Columns(1)
end

return DebugPanel
