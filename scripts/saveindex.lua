SaveIndex = Class(function(self)
    self:Init()
end)

function SaveIndex:Init()
    self.data = { slots = {} }
    self:GuaranteeMinNumSlots(NUM_SAVE_SLOTS)
    self.current_slot = 1
end

local function NewSlotData()
    return
    {
        world = {},
        server = {},
        session_id = nil,
        enabled_mods = {},
    }
end

local function ResetSlotData(data)
    data.world = {}
    data.server = {}
    data.session_id = nil
    data.enabled_mods = {}
end

local function GetWorldgenOverride(cb)
    local filename = "../worldgenoverride.lua"
    TheSim:GetPersistentString( filename,
        function(load_success, str)
            if load_success == true then
                local success, savedata = RunInSandboxSafe(str)
                if success and string.len(str) > 0 then
                    print("Found a worldgen override file with these contents:")
                    dumptable(savedata)
                    if savedata ~= nil and savedata.override_enabled then
                        print("Loaded and applied world gen overrides from "..filename)
                        local preset = savedata.preset
                        savedata.override_enabled = nil --remove this so the rest of the table can be interpreted as a tweak table
                        savedata.preset = nil
                        cb( preset, savedata )
                        return
                    else
                        print("Found world gen overrides but not enabled.")
                    end
                else
                    print("ERROR: Failed to load "..filename)
                end
            end
            print("Not applying world gen overrides.")
            cb( nil, nil )
        end)
end

function SaveIndex:GuaranteeMinNumSlots(numslots)
    for i = #self.data.slots + 1, numslots do
        table.insert(self.data.slots, NewSlotData())
    end
end

function SaveIndex:GetSaveIndexName()
    return (TheSim:IsLegacyClientHosting() and "saveindex_legacy" or "saveindex")..(BRANCH ~= "dev" and "" or ("_"..BRANCH))
end

function SaveIndex:Save(callback)
    local data = DataDumper(self.data, nil, false)
    local insz, outsz = TheSim:SetPersistentString(self:GetSaveIndexName(), data, false, callback)
end

local function OnLoad(self, filename, callback, load_success, str)
    local success, savedata = RunInSandbox(str)

    -- If we are on steam cloud this will stop a currupt saveindex file from
    -- ruining everyones day..
    if success and
        string.len(str) > 0 and
        savedata ~= nil and
        savedata.slots ~= nil and
        type(savedata.slots) == "table" then

        self:GuaranteeMinNumSlots(#savedata.slots)
        self.data.last_used_slot = savedata.last_used_slot

        for i, v in ipairs(self.data.slots) do
            ResetSlotData(v)
            local v2 = savedata.slots[i]
            if v2 ~= nil then
                v.world = v2.world or v.world
                v.server = v2.server or v.server
                v.session_id = v2.session_id or v.session_id
                v.enabled_mods = v2.enabled_mods or v.enabled_mods

                -- FIXME: this upgrades custom data to multilevel. Can remove this at some point. Added 23/11/2015 ~gjans
                if v.world and v.world.options and v.world.options.supportsmultilevel ~= true then
                    local data = v.world.options
                    v.world.options = { supportsmultilevel = true }
                    v.world.options[1] = data
                end
            end
        end

        if filename ~= nil then
            print("loaded "..filename)
        end
    elseif filename ~= nil then
        print("Could not load "..filename)
    end

    if callback ~= nil then
        callback()
    end
end

function SaveIndex:Load(callback)
    --This happens on game start.
    local filename = self:GetSaveIndexName()
    TheSim:GetPersistentString(filename,
        function(load_success, str)
            OnLoad(self, filename, callback, load_success, str)
        end)
end

function SaveIndex:LoadClusterSlot(slot, shard, callback)
    --This happens in FE when we need data from cluster slots
    --Don't pass filename to OnLoad, so we don't print errors
    --for attempting to load empty slots
    TheSim:GetPersistentStringInClusterSlot(slot, shard, self:GetSaveIndexName(),
        function(load_success, str)
            OnLoad(self, nil, callback, load_success, str)
        end)
end

function SaveIndex:GetSaveDataFile(file, cb)
    TheSim:GetPersistentString(file, function(load_success, str)
        if not load_success then
            if TheNet:GetIsClient() then
                assert(load_success, "SaveIndex:GetSaveData: Load failed for file ["..file.."] Please try joining again.")
            else
                assert(load_success, "SaveIndex:GetSaveData: Load failed for file ["..file.."] please consider deleting this save slot and trying again.")
            end
        end
        assert(str, "SaveIndex:GetSaveData: Encoded Savedata is NIL on load ["..file.."]")
        assert(#str>0, "SaveIndex:GetSaveData: Encoded Savedata is empty on load ["..file.."]")

        print("Loading world: "..file)
        local success, savedata = RunInSandbox(str)

        assert(success, "Corrupt Save file ["..file.."]")
        assert(savedata, "SaveIndex:GetSaveData: Savedata is NIL on load ["..file.."]")
        assert(GetTableSize(savedata) > 0, "SaveIndex:GetSaveData: Savedata is empty on load ["..file.."]")

        cb(savedata)
    end)
end

function SaveIndex:GetSaveData(slot, cb)
    self.current_slot = slot
    local file = TheNet:GetWorldSessionFile(self.data.slots[slot].session_id)
    if file ~= nil then
        self:GetSaveDataFile(file, cb)
    elseif cb ~= nil then
        cb()
    end
end

function SaveIndex:DeleteSlot(slot, cb, save_options)
    local slotdata = slot ~= nil and self.data.slots[slot] or nil
    if slotdata ~= nil then
        local server = slotdata.server
        local options = slotdata.world.options

        --DST session file stuff
        if slotdata.session_id ~= nil then
            TheNet:DeleteSession(slotdata.session_id)
        end

        if not TheNet:IsDedicated() then
            TheNet:DeleteCluster(slot)
        end

        ResetSlotData(slotdata)

        if save_options then
            slotdata.server = server
            slotdata.world.options = options
        end

        self:Save(cb)
    elseif cb ~= nil then
        cb()
    end
end

--isshutdown means players have been cleaned up by OnDespawn()
--and the sim will shutdown after saving
function SaveIndex:SaveCurrent(onsavedcb, isshutdown)
    -- Only servers save games in DST
    if TheNet:GetIsClient() then
        return
    end

    assert(TheWorld ~= nil, "missing world?")

    local slotdata = self.data.slots[self.current_slot]
    slotdata.session_id = TheNet:GetSessionIdentifier()
    slotdata.world.day = TheWorld.state.cycles + 1

    SaveGame(isshutdown, onsavedcb)
end

function SaveIndex:SetCurrentIndex(saveslot)
    self.current_slot = saveslot
end

function SaveIndex:GetCurrentSaveSlot()
    return self.current_slot
end

--called upon relaunch when a new level needs to be loaded
function SaveIndex:OnGenerateNewWorld(saveslot, savedata, session_identifier, cb)
    self.current_slot = saveslot

    local function onsavedatasaved()
        local slotdata = self.data.slots[self.current_slot]
        slotdata.session_id = session_identifier
        slotdata.world.day = 1

        self:Save(cb)
    end

    SerializeWorldSession(savedata, session_identifier, onsavedatasaved)
end

function SaveIndex:UpdateServerData(saveslot, serverdata, onsavedcb)
    self.current_slot = saveslot

    local slotdata = self.data.slots[saveslot]
    if slotdata ~= nil and serverdata ~= nil then
        slotdata.server = deepcopy(serverdata)
    end

    self.data.last_used_slot = saveslot

    self:Save(onsavedcb)
end

--call after you have worldgen data to initialize a new survival save slot
function SaveIndex:StartSurvivalMode(saveslot, customoptions, serverdata, onsavedcb)
    local starts = Profile:GetValue("starts") or 0
    Profile:SetValue("starts", starts + 1)
    Profile:Save()

    self.current_slot = saveslot

    local slot = self.data.slots[saveslot]
    slot.session_id = TheNet:GetSessionIdentifier()
    slot.world.day = 1
    slot.world.options = customoptions
    slot.server = {}

    if slot.world.options == nil then
        slot.world.options = { supportsmultilevel = true }
    end

    -- FIXME: this upgrades custom data to multilevel. Can remove this at some point. Added 23/11/2015 ~gjans
    if slot.world.options.supportsmultilevel ~= true then
        local data = slot.world.options
        slot.world.options = { supportsmultilevel = true }
        slot.world.options[1] = data
    end

    GetWorldgenOverride(function(preset, overrideoptions)
        -- note: Always overrides layer 1, as that's what worldgen will generate
        if slot.world.options == nil then
            slot.world.options = { supportsmultilevel = true }
        end
        if slot.world.options[1] == nil then
            slot.world.options[1] = {}
        end
        if preset then
            slot.world.options[1].actualpreset = preset
        end
        if overrideoptions then
            slot.world.options[1].tweak = overrideoptions
        end

        self:UpdateServerData(saveslot, serverdata, onsavedcb)
    end)
end

function SaveIndex:IsSlotEmpty(slot)
    return slot == nil or self.data.slots[slot] == nil or self.data.slots[slot].session_id == nil
end

function SaveIndex:GetLastUsedSlot()
    return self.data.last_used_slot or -1
end

function SaveIndex:GetSlotServerData(slot)
    return slot ~= nil and self.data.slots[slot] ~= nil and self.data.slots[slot].server or {}
end

function SaveIndex:GetSlotDay(slot)
    return self.data.slots[slot or self.current_slot].world.day
end

function SaveIndex:SetSlotDay(slot, day)
    self.data.slots[slot or self.current_slot].world.day = day
end

function SaveIndex:GetSlotGenOptions(slot)
    return self.data.slots[slot or self.current_slot].world.options
end

function SaveIndex:GetSlotSession(slot)
    return self.data.slots[slot or self.current_slot].session_id
end

--V2C: This is for FE use, as it handles checking the cluster session folders
function SaveIndex:GetClusterSlotSession(slot)
    if TheSim:IsLegacyClientHosting() then
        return self:GetSlotSession(slot)
    end
    local session_id = nil
    local clusterSaveIndex = SaveIndex()
    clusterSaveIndex:LoadClusterSlot(slot, "Master", function()
        session_id = clusterSaveIndex.data.slots[clusterSaveIndex.current_slot].session_id
    end)
    return session_id
end

function SaveIndex:CheckWorldFile(slot)
    local session_id = self:GetSlotSession(slot)
    return session_id ~= nil and TheNet:GetWorldSessionFile(session_id) ~= nil
end

--V2C: This is no longer cheap because it's not cached, but supports
--     dynamically switching user accounts locally, mmm'kay
function SaveIndex:LoadSlotCharacter(slot)
    local character = nil

    local function onreadusersession(success, str)
        if success and str ~= nil and #str > 0 then
            local success, savedata = RunInSandbox(str)
            if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                character = savedata.prefab
            end
        end
    end

    local slotdata = self.data.slots[slot or self.current_slot]
    if slotdata.session_id ~= nil then
        local online_mode = slotdata.server.online_mode ~= false
        if TheSim:IsLegacyClientHosting() then
            local file = TheNet:GetUserSessionFile(slotdata.session_id, nil, online_mode)
            if file ~= nil then
                TheSim:GetPersistentString(file, onreadusersession)
            end
        else
            local clusterSaveIndex = SaveIndex()
            clusterSaveIndex:LoadClusterSlot(slot, "Master", function()
                local slotdata = clusterSaveIndex.data.slots[clusterSaveIndex.current_slot]
                if slotdata.session_id ~= nil then
                    local shard, snapshot = TheNet:GetPlayerSaveLocationInClusterSlot(slot, slotdata.session_id, online_mode)
                    if shard ~= nil and snapshot ~= nil then
                        if shard ~= "Master" then
                            clusterSaveIndex = SaveIndex()
                            clusterSaveIndex:LoadClusterSlot(slot, shard, function()
                                slotdata = clusterSaveIndex.data.slots[clusterSaveIndex.current_slot]
                            end)
                        end
                        if slotdata.session_id ~= nil then
                            local file = TheNet:GetUserSessionFileInClusterSlot(slot, shard, slotdata.session_id, snapshot, online_mode)
                            if file ~= nil then
                                TheSim:GetPersistentStringInClusterSlot(slot, shard ,file, onreadusersession)
                            end
                        end
                    end
                end
            end)
        end
    end
    return character
end

function SaveIndex:LoadServerEnabledModsFromSlot(slot)
    local enabled_mods = self.data.slots[slot or self.current_slot].enabled_mods
    ModManager:DisableAllServerMods()
    for modname,mod_data in pairs(enabled_mods) do
        if mod_data.enabled then
			KnownModIndex:Enable(modname)
		end
		
		local config_options = mod_data.config_data or mod_data.configuration_options --config_data is the legacy format
        for option_name,value in pairs(config_options) do
			KnownModIndex:SetConfigurationOption( modname, option_name, value )
        end
        KnownModIndex:SaveHostConfiguration(modname)
    end
end

function SaveIndex:SetServerEnabledMods(slot)
    --Save enabled server mods to the save index
    local server_enabled_mods = ModManager:GetEnabledServerModNames()
    
    local enabled_mods = {}
    for _,modname in pairs(server_enabled_mods) do
        local mod_data = { enabled = true } --Note(Peter): The format of mod_data now must match the format expected in modoverrides.lua. See ModIndex:ApplyEnabledOverrides
        mod_data.configuration_options = {}
        local force_local_options = true
        local config = KnownModIndex:LoadModConfigurationOptions(modname, false)
        if config and type(config) == "table" then
            for i,v in pairs(config) do
                if v.saved ~= nil then
                    mod_data.configuration_options[v.name] = v.saved 
                else 
                    mod_data.configuration_options[v.name] = v.default
                end
            end
        end
        enabled_mods[modname] = mod_data
    end
    self.data.slots[slot or self.current_slot].enabled_mods = enabled_mods
end

function SaveIndex:GetEnabledMods(slot)
    return self.data.slots[slot or self.current_slot].enabled_mods
end
