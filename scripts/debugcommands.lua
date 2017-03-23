function d_decodedata(path)
    print("DECODING",path)
    TheSim:GetPersistentString(path, function(load_success, str)
        if load_success then
            print("LOADED...")
            TheSim:SetPersistentString(path.."_decoded", str, false, function()
                print("SAVED!")
            end)
        else
            print("ERROR LOADING FILE! (wrong path?)")
        end
    end)
end

function d_domesticatedbeefalo()
    c_give('whip')
    c_give('saddle_war')
    c_spawn('dummytarget')
    local beef = c_spawn('beefalo')
    for k, v in pairs(TENDENCY) do
        beef = c_spawn('beefalo')
        beef.components.domesticatable:DeltaDomestication(1)
        beef.components.domesticatable:DeltaObedience(0.5)
        beef.components.domesticatable:DeltaTendency(v, 1)
        beef:SetTendency()
        beef.components.domesticatable:BecomeDomesticated()
        beef.components.rideable:SetSaddle(nil, SpawnPrefab('saddle_basic'))
    end
end

function d_domestication(domestication, obedience)
    if c_sel().components.domesticatable == nil then
        print("Selected ent not domesticatable")
    end
    if domestication ~= nil then
        c_sel().components.domesticatable:DeltaDomestication(domestication - c_sel().components.domesticatable:GetDomestication())
    end
    if obedience ~= nil then
        c_sel().components.domesticatable:DeltaObedience(obedience - c_sel().components.domesticatable:GetObedience())
    end
end

function d_testwalls()
    local walls = {
        "stone",
        "wood",
        "hay",
        "ruins",
        "moonrock",
    }
    local sx,sy,sz = ConsoleCommandPlayer().Transform:GetWorldPosition()
    for i,mat in ipairs(walls) do
        for j = 0,4 do
            local wall = SpawnPrefab("wall_"..mat)
            wall.Transform:SetPosition(sx + (i*6), sy, sz + j)
            wall.components.health:SetPercent(j*0.25)
        end
        for j = 5,15 do
            local wall = SpawnPrefab("wall_"..mat)
            wall.Transform:SetPosition(sx + (i*6), sy, sz + j)
            wall.components.health:SetPercent(j <= 11 and 1 or 0.5)
        end
    end
end


function d_testruins()
    ConsoleCommandPlayer().components.builder:UnlockRecipesForTech({SCIENCE = 2, MAGIC = 2})
    c_give("log", 20)
    c_give("flint", 20)
    c_give("twigs", 20)
    c_give("cutgrass", 20)
    c_give("lightbulb", 5)
    c_give("healingsalve", 5)
    c_give("batbat")
    c_give("icestaff")
    c_give("firestaff")
    c_give("tentaclespike")
    c_give("slurtlehat")
    c_give("armorwood")
    c_give("minerhat")
    c_give("lantern")
    c_give("backpack")
end

function d_combatgear()
    c_give("armorwood")
    c_give("footballhat")
    c_give("spear")
end

function d_teststate(state)
    c_sel().sg:GoToState(state)
end

function d_anim(animname, loop)
    if GetDebugEntity() then
        GetDebugEntity().AnimState:PlayAnimation(animname, loop or false)
    else
        print("No DebugEntity selected")
    end
end

function d_light(c1, c2, c3)
    TheSim:SetAmbientColour(c1, c2 or c1, c3 or c1)
end

function d_combatsimulator(prefab, count, force)
    count = count or 1

    local x,y,z = ConsoleWorldPosition():Get()
    local MakeBattle = nil
    MakeBattle = function()
        local creature = DebugSpawn(prefab)
        creature:ListenForEvent("onremove", MakeBattle)
        creature.Transform:SetPosition(x,y,z)
        if creature.components.knownlocations then
            creature.components.knownlocations:RememberLocation("home", {x=x,y=y,z=z})
        end
        if force then
            local target = FindEntity(creature, 20, nil, {"_combat"})
            if target then
                creature.components.combat:SetTarget(target)
            end
            creature:ListenForEvent("droppedtarget", function()
                local target = FindEntity(creature, 20, nil, {"_combat"})
                if target then
                    creature.components.combat:SetTarget(target)
                end
            end)
        end
    end

    for i=1,count do
        MakeBattle()
    end
end

function d_spawn_ds(prefab, scenario)
    local inst = c_spawn(prefab)
    if not inst then
        print("Need to select an entity to apply the scenario to.")
        return
    end

    if inst.components.scenariorunner then
        inst.components.scenariorunner:ClearScenario()
    end

    -- force reload the script -- this is for testing after all!
    package.loaded["scenarios/"..scenario] = nil

    inst:AddComponent("scenariorunner")
    inst.components.scenariorunner:SetScript(scenario)
    inst.components.scenariorunner:Run()
end



---------------------------------------------------
------------ skins functions --------------------
---------------------------------------------------

local TEST_ITEM_NAME = "feet_bootie_black_scribble"
function d_test_skins_popup(param)
	local SkinsItemPopUp = require "screens/skinsitempopup"
	TheFrontEnd:PushScreen( SkinsItemPopUp(param or TEST_ITEM_NAME, "Peter", {1.0, 0.2, 0.6, 1.0}) )
end
function d_test_skins_announce(param)
	ThePlayer.HUD.eventannouncer:ShowSkinAnnouncement("Peter", {1.0, 0.2, 0.6, 1.0}, param or TEST_ITEM_NAME)
end
function d_test_skins_gift(param)
	local GiftItemPopUp = require "screens/giftitempopup"
	TheFrontEnd:PushScreen( GiftItemPopUp(ThePlayer, { param or TEST_ITEM_NAME }, { 0 }) )
end

function d_skin_mode(mode)
    ConsoleCommandPlayer().components.skinner:SetSkinMode(mode)
end

function d_skin_name(name)
    ConsoleCommandPlayer().components.skinner:SetSkinName(name)
end

function d_clothing(name)
    ConsoleCommandPlayer().components.skinner:SetClothing(name)
end
function d_clothing_clear(type)
    ConsoleCommandPlayer().components.skinner:ClearClothing(type)
end

function d_cycle_clothing()
    local skinslist = TheInventory:GetFullInventory()

    local idx = 1
    local task = nil

    ConsoleCommandPlayer().cycle_clothing_task = ConsoleCommandPlayer():DoPeriodicTask(10, 
        function() 
            local type, name = GetTypeForItem(skinslist[idx].item_type)
            --print("showing clothing idx ", idx, name, type, #skinslist) 
            if (type ~= "base" and type ~= "item") then 
                c_clothing(name) 
            end

            if idx < #skinslist then 
                idx = idx + 1 
            else
                print("Ending cycle")
                ConsoleCommandPlayer().cycle_clothing_task:Cancel()
            end
        end)

end

function d_sinkhole()
	c_spawn("antlion_sinkhole"):PushEvent("startcollapse")
end

function d_stalkersetup()
	local mound = c_spawn("fossil_stalker")
	--mound.components.workable:SetWorkLeft(mound.components.workable.maxwork - 1)
	for i = 1, (mound.components.workable.maxwork - 1) do
		mound.form = 1
		mound.components.repairable.onrepaired(mound)
	end
	
	c_give "shadowheart"
	c_give "atrium_key"
end