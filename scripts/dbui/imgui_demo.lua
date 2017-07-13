-- Demonstration of how to use imgui
--
-- To run the test, add inside an OnUpdate loop:
--      local imgui_demo = require("dbui/imgui_demo")
--      imgui_demo.CreateImguiTestWindow()

-- We generally pass imgui around as a variable called dbui.
local dbui = require("dbui/imgui")
local DebugPanel = require("dbui/debug_panel")



-- Call the functions that we remapped for simulated overloading to exercise
-- the different branches. Code pulled from imgui_demo.
local radio_selection1 = 0
local radio_selection2 = 0
local dont_ask_me_next_time = false
local function AddImguiTestSection_Remap()
    local _ = nil

    if dbui.TreeNode("RadioButton") then
        dbui.Text("RadioButton that returns item selected")
        _, radio_selection1 = dbui.RadioButton("radio a", radio_selection1, 0) ; dbui.SameLine()
        _, radio_selection1 = dbui.RadioButton("radio b", radio_selection1, 1) ; dbui.SameLine()
        _, radio_selection1 = dbui.RadioButton("radio c", radio_selection1, 2)

        dbui.Text("RadioButton that returns is button selected")
        local is_selected = false

        for i=0,2 do
            is_selected = dbui.RadioButton("radio ".. i, radio_selection2 == i)
            if is_selected then
                radio_selection2 = i
            end
            dbui.SameLine()
        end
        dbui.Text("")

        _, dont_ask_me_next_time = dbui.Checkbox("Normal button", dont_ask_me_next_time)
        dbui.PushStyleVar(dbui.constant.StyleVar.FramePadding, 0,0)
        _, dont_ask_me_next_time = dbui.Checkbox("ImGuiStyleVar_FramePadding button", dont_ask_me_next_time)
        dbui.PopStyleVar()

        dbui.TreePop()
    end

    if dbui.TreeNode("Text styling") then 

        dbui.Value("Value", false)
        dbui.Value("Value", 3.4) -- without format string, value is truncated!
        dbui.Value("Value", 3.4, "%0.3f")
        dbui.Value("Value", 3)
        dbui.Text("Normal text")
        dbui.Indent() do
            dbui.Text("Normal indented text")
        end
        dbui.Unindent()
        dbui.Text("Before ImGuiStyleVar_IndentSpacing")
        dbui.PushStyleVar(dbui.constant.StyleVar.IndentSpacing, dbui.GetFontSize()*3) do
            dbui.Text("Increase spacing to differentiate leaves from expanded contents.")
            dbui.Indent() do
                dbui.Text("Increase spacing to differentiate leaves from expanded contents.")
            end
            dbui.Unindent()
        end
        dbui.PopStyleVar()
        dbui.Text("After ImGuiStyleVar_IndentSpacing")

        dbui.TreePop()
    end

    dbui.ValueColor("Color", dbui.GetColorU32(dbui.constant.Col.Text))

    dbui.PushItemWidth(80)
    for i=0,7 do
        if i > 0 then dbui.SameLine() end
        dbui.PushID(i)
        dbui.PushStyleColor(dbui.constant.Col.Button, i/7.0, 0.6, 0.6, 1)
        dbui.PushStyleColor(dbui.constant.Col.ButtonHovered, i/7.0, 0.7, 0.7, 1)
        dbui.PushStyleColor(dbui.constant.Col.ButtonActive, i/7.0, 0.8, 0.8, 1)
        dbui.Button("Click")
        dbui.PopStyleColor(3)
        dbui.PopID()
    end
    dbui.PopItemWidth()
end

local function _ShowExampleMenuFile()
    dbui.MenuItem("(dummy menu)", "", false, false)
    if (dbui.MenuItem("New")) then end
    if (dbui.MenuItem("Open", "Ctrl+O")) then end
    if (dbui.BeginMenu("Open Recent")) then 
        dbui.MenuItem("fish_hat.c")
        dbui.MenuItem("fish_hat.inl")
        dbui.MenuItem("fish_hat.h")
        if (dbui.BeginMenu("More..")) then 
            dbui.MenuItem("Hello")
            dbui.MenuItem("Sailor")
            if (dbui.BeginMenu("Recurse..")) then 
                _ShowExampleMenuFile()
                dbui.EndMenu()
            end
            dbui.EndMenu()
        end
        dbui.EndMenu()
    end
    if (dbui.MenuItem("Save", "Ctrl+S")) then end
    if (dbui.MenuItem("Save As..")) then end
    dbui.Separator()
    if (dbui.BeginMenu("Disabled", false)) then -- Disabled
        assert(false)
    end
    if (dbui.MenuItem("Checked", "", true)) then end
    if (dbui.MenuItem("Quit", "Alt+F4")) then end
end

local function any(items)
    local any_clicked = false
    for k,was_clicked in pairs(items) do
        if was_clicked then
            return true
        end
    end
    return false
end

local function all(items)
    local any_clicked = false
    for k,was_clicked in pairs(items) do
        if not was_clicked then
            return false
        end
    end
    return true
end

local function AddImguiTestSection_Enum()
    dbui.Value("dbui.constant.SelectableFlags.AllowDoubleClick", dbui.constant.SelectableFlags.AllowDoubleClick)
    dbui.Value("dbui.constant.StyleVar.FramePadding ", dbui.constant.StyleVar.FramePadding)
    dbui.Value("dbui.constant.StyleVar.IndentSpacing", dbui.constant.StyleVar.IndentSpacing)
    dbui.Value("dbui.constant.Col.Text              ", dbui.constant.Col.Text)
    dbui.Value("dbui.constant.Col.Button            ", dbui.constant.Col.Button)
    dbui.Value("dbui.constant.Col.ButtonHovered     ", dbui.constant.Col.ButtonHovered)
    dbui.Value("dbui.constant.Col.ButtonActive      ", dbui.constant.Col.ButtonActive)


    dbui.BeginChild("#colors", 0, 300, true, dbui.constant.WindowFlags.AlwaysVerticalScrollbar)
    dbui.PushItemWidth(-160)
    for i=0,dbui.constant.Col.COUNT-1 do
        local name = dbui.GetStyleColName(i)
        dbui.Text(name)
    end
    dbui.PopItemWidth()
    dbui.EndChild()
end

-- Call functions with similar signatures where it didn't seem useful to
-- provide both. Validate that the one we selected is the more useful one.
local selected = { false, true, false, false }
local function AddImguiTestSection_Differentiation()
    local _ = nil

    -- Selectable should return the new state of the selection and not just
    -- whether it was pressed.
    dbui.SetNextWindowCollapsed(false)
    if dbui.TreeNode("Basic - first") then 
        _, selected[1] = dbui.Selectable("1. I am selectable", selected[1])
        _, selected[2] = dbui.Selectable("2. I am selectable", selected[2])
        dbui.Text("3. I am not selectable")
        _, selected[3] = dbui.Selectable("4. I am selectable", selected[3])

        local was_pressed, was_selected = dbui.Selectable("5. I am double clickable", selected[4], dbui.constant.SelectableFlags.AllowDoubleClick)
        -- This code from imgui_demo doesn't work: if was_pressed and dbui.IsMouseDoubleClicked(0) then
        -- This works instead:
        if selected[4] == was_selected and dbui.IsMouseDoubleClicked(0) then
            selected[4] = not selected[4]
        end
        dbui.TreePop()
    end

    -- MenuItem returns whether it was selected.
    if (dbui.BeginMainMenuBar()) then 
        if (dbui.BeginMenu("File")) then 
            _ShowExampleMenuFile()
            dbui.EndMenu()
        end
        if (dbui.BeginMenu("Edit")) then 
            if (dbui.MenuItem("Undo", "CTRL+Z")) then end
            if (dbui.MenuItem("Redo", "CTRL+Y", false, false)) then end  -- Disabled item
            dbui.Separator()
            if (dbui.MenuItem("Cut", "CTRL+X")) then end
            if (dbui.MenuItem("Copy", "CTRL+C")) then end
            if (dbui.MenuItem("Paste", "CTRL+V")) then end
            dbui.EndMenu()
        end
        dbui.EndMainMenuBar()
    end
end


function AddImguiTestSection_Input()
    dbui.Value("WantCaptureMouse", dbui.WantCaptureMouse())
    dbui.Value("WantCaptureKeyboard", dbui.WantCaptureKeyboard())
    dbui.Value("WantTextInput", dbui.WantTextInput())
end

local vec4 = { 0.10, 0.20, 0.30, 0.44 }
local selected_greeting_idx = nil
local single_line = "blank"
local multi_line = "put\ntext\nhere"
local tick = 0
local color = { 1, 0, 0.5, 1 }
local edit_mode = dbui.constant.ColorEditMode.RGB
function AddImguiTestSection_ImguiLuaProxy()
    local _ = nil

    if dbui.CollapsingHeader("Floats") then
        local a,b,c = dbui.DragFloat3("drag", vec4[1], vec4[2], vec4[3],0.1,0,100)
        if a then
            vec4[1] = a
            vec4[2] = b
            vec4[3] = c
        end
        local a,b,c = dbui.InputFloat3("input", vec4[1], vec4[2], vec4[3],0.1,0,100)
        if a then
            vec4[1] = a
            vec4[2] = b
            vec4[3] = c
        end
    end

    local GREETING_LIST = {"hi", "hello", "yo"}
    local new_sel_idx = dbui.ListBox("Greeting", GREETING_LIST, math.clamp(selected_greeting_idx or 1, 1, #GREETING_LIST))
    if new_sel_idx and new_sel_idx ~= selected_greeting_idx then
        selected_greeting_idx = new_sel_idx
    end

    if dbui.CollapsingHeader("Text") then
        local a = dbui.InputText("UTF-8 input", single_line)
        if a then
            single_line = a
        end
        local a = dbui.InputTextMultiline("lines of input", multi_line)
        if a then
            multi_line = a
        end
    end

    if dbui.CollapsingHeader("Cool Graphs") then
        tick = math.fmod(tick + 1, 1000)
        local arr = {}
        local v = tick / 10
        for i=1,100 do
            v = v + 1
            table.insert(arr, math.sin(v))
        end
        dbui.PlotLines("Curve", "", arr)
    end

    if dbui.CollapsingHeader("Color") then
        dbui.Text("Global color edit mode:")

        _, edit_mode = dbui.RadioButton("RGB", edit_mode, dbui.constant.ColorEditMode.RGB) ; dbui.SameLine()
        _, edit_mode = dbui.RadioButton("HSV", edit_mode, dbui.constant.ColorEditMode.HSV) ; dbui.SameLine()
        _, edit_mode = dbui.RadioButton("HEX", edit_mode, dbui.constant.ColorEditMode.HEX) ; dbui.SameLine()
        _, edit_mode = dbui.RadioButton("disabled", edit_mode, -1)

        if edit_mode ~= -1 then
            dbui.ColorEditMode(edit_mode)
        end
        local r,g,b,a = dbui.ColorEdit4("##edit", unpack(color))
        if r then
            color = { r,g,b,a }
        end

        local r,g,b,a = dbui.ColorEdit3("##edit", unpack(color))
        if r then
            color = { r,g,b,a }
        end

        if dbui.ColorButton(unpack(color)) then
            color[1] = color[1] * 0.5
        end
        dbui.SameLine() ; dbui.Text("ColorButton")
    end
end


local panel = DebugPanel()
local function AddImguiTestSection_DebugPanel()
    local function SortMenuByName( x, y )
        return x.Text < y.Text
    end

    local function MakeSpawnMenu()
        local spawn_menu = {}
        local limiter = 100
        for k, v in pairs(Prefabs) do
            limiter = limiter - 1
            if limiter < 0 then
                -- We can't handle too many menu items.
                break
            end
            table.insert(spawn_menu, 
                {
                    Text = v.name,
                    Do = function( wx, wz )
                            local entity = DebugSpawn( v.name )
                            print("SPAWN PREFAB:", v.name, entity)
                        end
                    })
                table.sort( spawn_menu, SortMenuByName )
            end
            return spawn_menu
        end

    -- Important! Must call at beginning of frame for each panel!
    panel:StartFrame()

    panel:AppendTable(dbui, TheFrontEnd, "TheFrontEnd")
    dbui.Separator()
    panel:AppendKeyValue(dbui, "ThePlayer as keyvalues", ThePlayer)
    dbui.Separator()
    panel:AppendTable(dbui, ThePlayer, "ThePlayer as table")
    dbui.Separator()
    panel:AppendKeyValue(dbui, "imgui constant", dbui.constant)

    dbui.Separator()
    dbui.Text("TabularData")
    panel:AppendTabularData(dbui, {"name", "age"}, { {'wilson', 2 }, {'wes', 6} })

    dbui.Separator()
    dbui.Text("Menus")


    local LOOT_TABLE =
    {
        name = "Toggles",
    }
    for loot, data in pairs(TUNING.WINTERS_FEAST_TREE_DECOR_LOOT) do
        local menu_item =
        {
            Text = loot,
            Checked = function()
                return data.special
            end,
            Do = function()
                data.special = not data.special
                print(loot, "has the type", data.basic)
            end,
        }
        table.insert( LOOT_TABLE, menu_item )
    end

    if dbui.BeginMenu( "winters feast tree decor loot" ) then
        panel:AddDebugMenu( dbui, LOOT_TABLE )
        dbui.EndMenu()
    end

    local wx,wz = 3,4
    local DEBUG_CONTEXT_MENU =
    {
        {
            Text = "Spawn Prefab",
            Menu = MakeSpawnMenu,
        },
    }
    panel:AddDebugMenu( dbui, DEBUG_CONTEXT_MENU, { wx, wz } )
end


local function AddImguiTestSections()
    if dbui.CollapsingHeader("Remap") then
        AddImguiTestSection_Remap()
    end

    if dbui.CollapsingHeader("Differentiation") then
        AddImguiTestSection_Differentiation()
    end

    if dbui.CollapsingHeader("Enum") then
        AddImguiTestSection_Enum()
    end

    if dbui.CollapsingHeader("Input") then
        AddImguiTestSection_Input()
    end

    if dbui.CollapsingHeader("ImguiLuaProxy") then
        AddImguiTestSection_ImguiLuaProxy()
    end

    if dbui.CollapsingHeader("DebugPanel") then
        AddImguiTestSection_DebugPanel()
    end
end

local function CreateImguiTestWindow()
    dbui.Begin("imgui_demo") do
        AddImguiTestSections()
    end
    dbui.End()
end

return {
    AddImguiTestSections = AddImguiTestSections,
    CreateImguiTestWindow = CreateImguiTestWindow,
}
