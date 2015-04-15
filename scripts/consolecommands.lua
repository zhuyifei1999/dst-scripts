-- not local - debugkeys use it too
function ConsoleCommandPlayer()
	return (c_sel() and c_sel():HasTag("player") and c_sel()) or ThePlayer or AllPlayers[1]
end

local function Spawn(prefab)
    --TheSim:LoadPrefabs({prefab})
    return SpawnPrefab(prefab)
end

local function ConsoleWorldPosition()
    return TheInput.overridepos or TheInput:GetWorldPosition()
end

local function ConsoleWorldEntityUnderMouse()
    if TheInput.overridepos == nil then
        return TheInput:GetWorldEntityUnderMouse()
    else
        local x, y, z = TheInput.overridepos:Get()
        local ents = TheSim:FindEntities(x, y, z, 1)
        for i, v in ipairs(ents) do
            if v.entity:IsVisible() then
                return v
            end
        end
    end
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Console Functions -- These are simple helpers made to be typed at the console.
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Show server announcements:
-- To send a one time announcement:   c_announce(msg)
-- To repeat a periodic announcement: c_announce(msg, interval)
-- To cancel a periodic announcement: c_announce()
function c_announce(msg, interval)
    if msg == nil then
        if TheWorld.__announcementtask ~= nil then
            TheWorld.__announcementtask:Cancel()
            TheWorld.__announcementtask = nil
        end
    elseif interval == nil then
        TheNet:Announce(msg)
    else
        if TheWorld.__announcementtask ~= nil then
            TheWorld.__announcementtask:Cancel()
        end
        TheWorld.__announcementtask = TheWorld:DoPeriodicTask(interval, function() TheNet:Announce(msg) end, 0)
    end
end

local function doreset()
    StartNextInstance({
        reset_action = RESET_ACTION.LOAD_SLOT,
        save_slot = SaveGameIndex:GetCurrentSaveSlot()
    })
end

-- Roll back *count* number of saves (default 1)
function c_rollback(count)
    if TheWorld ~= nil and TheWorld.ismastersim then
        count = math.max(0, count or 1) + 1
        TheNet:TruncateSnapshots(TheWorld.meta.session_identifier, -count)
        doreset()
    end
end

function c_save()
    if TheWorld ~= nil and TheWorld.ismastersim then
        TheWorld:PushEvent("save")
    end
end

-- Spawn At Cursor and select the new ent
-- Has a gimpy short name so it's easier to type from the console
function c_spawn(prefab, count)
	count = count or 1
	local inst = nil
	for i = 1, count do
		inst = DebugSpawn(prefab)
		inst.Transform:SetPosition(ConsoleWorldPosition():Get())
	end
	SetDebugEntity(inst)
    SuUsed("c_spawn_"..prefab , true)
	return inst
end

-- Shutdown the application, optionally close with out saving (saves by default)
function c_shutdown(save)
    print("c_shutdown", save)
    if not save or TheWorld == nil then
        Shutdown()
    elseif TheWorld.ismastersim then
        for i, v in ipairs(AllPlayers) do
            v:OnDespawn()
        end
        TheSystemService:EnableStorage(true)
        SaveGameIndex:SaveCurrent(Shutdown, true)
    else
        SerializeUserSession(ThePlayer)
        Shutdown()
    end
end

-- Restart the server, optionally save before restarting (does not save by default)
function c_reset(save)
    if TheWorld ~= nil and TheWorld.ismastersim then
		if save then
			for i, v in ipairs(AllPlayers) do
				v:OnDespawn()
			end
			TheSystemService:EnableStorage(true)
			SaveGameIndex:SaveCurrent(doreset, true)
		else
			doreset()
		end
    end
end

-- Permanently delete the game world, rengerates a new world afterwords
function c_regenerateworld()
    SaveGameIndex:DeleteSlot(
        SaveGameIndex:GetCurrentSaveSlot(),
        doreset,
        true -- true causes world gen options to be preserved
    )
end 

-- Remotely execute a lua string
function c_remote( fnstr )
    local x, y, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    TheNet:SendRemoteExecute(fnstr, x, z)
end

-- c_despawn helper
local function dodespawn(player)
    if TheWorld.ismastersim then
        TheNet:Announce(player:GetDisplayName().." "..STRINGS.UI.NOTIFICATION.LEFTGAME, player.entity, true)
        --Delete must happen when the player is actually removed
        --This is currently handled in playerspawner listening to ms_playerdespawnanddelete
        TheWorld:PushEvent("ms_playerdespawnanddelete", player)
    end
end

-- Despawn a player, returning to character select screen
function c_despawn(player)
    player = player or ConsoleCommandPlayer()
    if player ~= nil and player:IsValid() then
        --Queue it because remote command may currently be overriding
        --ThePlayer, which will get stomped during delete
        player:DoTaskInTime(0, dodespawn)
    end
end

-- Return a listing of currently active players
function c_listplayers()
	print( dumptable( TheNet:GetClientTable() ) )
end

-- Return a listing of AllPlayers table
function c_listallplayers()
    for i, v in ipairs(AllPlayers) do
        print(string.format("[%d] %s <%s>", i, v.name, v.prefab))
    end
end

-- Get the currently selected entity, so it can be modified etc.
-- Has a gimpy short name so it's easier to type from the console
function c_sel()
	return GetDebugEntity()
end

function c_select(inst)
	if not inst then
		inst = ConsoleWorldEntityUnderMouse()
	end
	return SetDebugEntity(inst)
end

-- Print the (visual) tile under the cursor
function c_tile()
	local s = ""

    local map = TheWorld.Map
	local mx, my, mz = ConsoleWorldPosition():Get()
	local tx, ty = map:GetTileCoordsAtPoint(mx,my,mz)
	s = s..string.format("world[%f,%f,%f] tile[%d,%d] ", mx,my,mz, tx,ty)

	local tile = map:GetTileAtPoint(ConsoleWorldPosition():Get())
	for k,v in pairs(GROUND) do
		if v == tile then
			s = s..string.format("ground[%s] ", k)
			break
		end
	end

	print(s)
end

-- Apply a scenario script to the selection and run it.
function c_doscenario(scenario)
	local inst = GetDebugEntity()
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
    SuUsed("c_doscenario_"..scenario, true)
end


-- Some helper shortcut functions
function c_sel_health()
	if c_sel() then
		local health = c_sel().components.health
		if health then
			return health
		else
			print("Gah! Selection doesn't have a health component!")
			return
		end
	else
		print("Gah! Need to select something to access it's components!")
	end
end

function c_sethealth(n)
    SuUsed("c_sethealth", true)
	ConsoleCommandPlayer().components.health:SetPercent(n)
end
function c_setminhealth(n)
    SuUsed("c_minhealth", true)
    ConsoleCommandPlayer().components.health:SetMinHealth(n)
end
function c_setsanity(n)
    SuUsed("c_setsanity", true)
	ConsoleCommandPlayer().components.sanity:SetPercent(n)
end
function c_sethunger(n)
    SuUsed("c_sethunger", true)
	ConsoleCommandPlayer().components.hunger:SetPercent(n)
end

-- Work in progress direct connect code.
-- Currently, to join an online server you must authenticate first.
-- In the future this authentication will be taken care of for you.
function c_connect( ip, port, password )
	local start_worked = TheNet:StartClient( ip, port, 0, password )
	if start_worked then
		DisableAllDLC()
	end
	ShowCancelTip()
	ShowLoading()
	TheFrontEnd:Fade(false, 1)
	return start_worked
end

-- Put an item(s) in the player's inventory
function c_give(prefab, count)
	count = count or 1

    local MainCharacter = ConsoleCommandPlayer()
    
	if MainCharacter then
		for i=1,count do
			local inst = DebugSpawn(prefab)
			if inst then
print("giving ",inst)
				MainCharacter.components.inventory:GiveItem(inst)
                SuUsed("c_give_" .. inst.prefab)
			end
		end
	end
end

function c_mat(recname)
    local player = ConsoleCommandPlayer()
    local recipe = AllRecipes[recname]
    if player.components.inventory and recipe then
      for ik, iv in pairs(recipe.ingredients) do
            for i = 1, iv.amount do
                local item = SpawnPrefab(iv.type)
                player.components.inventory:GiveItem(item)
                SuUsed("c_mat_" .. iv.type , true)
            end
        end
    end
end

function c_pos(inst)
	return inst and Point(inst.Transform:GetWorldPosition())
end

function c_printpos(inst)
	print(c_pos(inst))
end

function c_teleport(x, y, z, inst)
	inst = inst or ConsoleCommandPlayer()
	inst.Transform:SetPosition(x, y, z)
    SuUsed("c_teleport", true)
end

function c_move(inst)
	inst = inst or c_sel()
	inst.Transform:SetPosition(ConsoleWorldPosition():Get())
    SuUsed("c_move", true)
end

function c_goto(dest, inst)
	inst = inst or ConsoleCommandPlayer()
    if inst.Physics ~= nil then
        inst.Physics:Teleport(dest.Transform:GetWorldPosition())
    else
        inst.Transform:SetPosition(dest.Transform:GetWorldPosition())
    end
    SuUsed("c_goto", true)
    return dest
end

function c_inst(guid)
	return Ents[guid]
end

function c_list(prefab)
    local x,y,z = ConsoleCommandPlayer().Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 9001)
    for k,v in pairs(ents) do
    	if v.prefab == prefab then
	    	print(string.format("%s {%2.2f, %2.2f, %2.2f}", tostring(v), v.Transform:GetWorldPosition()))
    	end
    end
end

function c_listtag(tag)
    local tags = {tag}
    local x,y,z = ConsoleCommandPlayer().Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 9001, tags)
    for k,v in pairs(ents) do
    	print(string.format("%s {%2.2f, %2.2f, %2.2f}", tostring(v), v.Transform:GetWorldPosition()))
    end
end

local lastfound = -1
function c_findnext(prefab, radius, inst)
	inst = inst or ConsoleCommandPlayer()
	radius = radius or 9001

    local trans = inst.Transform
    local found = nil
	local foundlowestid = nil
	local reallowest = nil
	local reallowestid = nil

	print("Finding a ",prefab)

    local x,y,z = trans:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, radius)
    for k,v in pairs(ents) do
        if v ~= inst and v.prefab == prefab then
        	print(v.GUID,lastfound,foundlowestid )
			if v.GUID > lastfound and (foundlowestid == nil or v.GUID < foundlowestid) then
				found = v
				foundlowestid = v.GUID
			end
			if not reallowestid or v.GUID < reallowestid then
				reallowest = v
				reallowestid = v.GUID
			end
        end
    end
	if not found then
		found = reallowest
	end
	lastfound = found.GUID
    return found
end

function c_godmode()
	if ConsoleCommandPlayer() then
        SuUsed("c_godmode", true)
		if ConsoleCommandPlayer():HasTag("playerghost") then
			ConsoleCommandPlayer():PushEvent("respawnfromghost")
	        c_sethunger(1)
	        c_sethealth(1)
	        c_setsanity(1)
			print("Reviving",ConsoleCommandPlayer().name,"from ghost.")
			return
		else
			if ConsoleCommandPlayer().components.health ~= nil then
				local godmode = ConsoleCommandPlayer().components.health.invincible
				ConsoleCommandPlayer().components.health:SetInvincible(not godmode)
				print("God mode: ",not godmode) 
			end
		end
	end
end

function c_find(prefab, radius, inst)
	inst = inst or ConsoleCommandPlayer()
	radius = radius or 9001

    local trans = inst.Transform
    local found = nil
    local founddistsq = nil

    local x,y,z = trans:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, radius)
    for k,v in pairs(ents) do
        if v ~= inst and v.prefab == prefab then
            if not founddistsq or inst:GetDistanceSqToInst(v) < founddistsq then 
                found = v
                founddistsq = inst:GetDistanceSqToInst(v)
            end
        end
    end
    return found
end

function c_findtag(tag, radius, inst)
	return GetClosestInstWithTag(tag, inst or ConsoleCommandPlayer(), radius or 1000)
end

function c_gonext(name)
	return c_goto(c_findnext(name))
end

function c_printtextureinfo( filename )
	TheSim:PrintTextureInfo( filename )
end

function c_simphase(phase)
	TheWorld:PushEvent("phasechange", {newphase = phase})
end

function c_anim(animname, loop)
	if GetDebugEntity() then
		GetDebugEntity().AnimState:PlayAnimation(animname, loop or false)
	else
		print("No DebugEntity selected")
	end
end

function c_light(c1, c2, c3)
	TheSim:SetAmbientColour(c1, c2 or c1, c3 or c1)
end

function c_spawn_ds(prefab, scenario)
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


function c_countprefabs(prefab, noprint)
	local count = 0
	for k,v in pairs(Ents) do
		if v.prefab == prefab then
			count = count + 1
		end
	end
	if not noprint then
		print("There are ", count, prefab.."s in the world.")
	end
	return count
end

function c_counttagged(tag, noprint)
	local count = 0
	for k,v in pairs(Ents) do
		if v:HasTag(tag) then
			count = count + 1
		end
	end
	if not noprint then
		print("There are ", count, tag.."-tagged ents in the world.")
	end
	return count
end

function c_countallprefabs()
	local counted = {}
	for k,v in pairs(Ents) do
		if v.prefab and not table.findfield(counted, v.prefab) then 
			local num = c_countprefabs(v.prefab, true)
			counted[v.prefab] = num
		end
	end

    local function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

    for k,v in pairsByKeys(counted) do
    	print(k, v)
    end

	print("There are ", GetTableSize(counted), " different prefabs in the world.")
end

function c_speed(speed)
	ConsoleCommandPlayer().components.locomotor.bonusspeed = speed
end

function c_testruins()
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


function c_teststate(state)
	c_sel().sg:GoToState(state)
end

function c_combatgear()
    local function give(prefab)
		if ConsoleCommandPlayer() then
			local inst = DebugSpawn(prefab)
			if inst then
				print("giving ",inst)
				ConsoleCommandPlayer().components.inventory:GiveItem(inst)
				ConsoleCommandPlayer().components.inventory:Equip(inst)
	            SuUsed("c_give_" .. inst.prefab)
			end
		end
	end
	give("armorwood")
	give("footballhat")
	give("spear")
end

function c_dump()
	local ent = GetDebugEntity()
	if not ent then
		ent = ConsoleWorldEntityUnderMouse()
	end
	DumpEntity(ent)
end
