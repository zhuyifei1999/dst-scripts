
-- These functions will be applied in order, starting with the one whose
-- version is higher than the current version in the save file. Version numbers
-- are declared explicitly to prevent the values from getting out of sync
-- somehow.

local t = {
    upgrades =
    {
        {
            version = 1,
            fn = function(savedata)
                if savedata == nil then
                    return
                end

                --Convert pre-RoG summer to RoG autumn
                print("Converting summer to autumn:")

                if savedata.world_network ~= nil and savedata.world_network.persistdata ~= nil then
                    local seasons = savedata.world_network.persistdata.seasons
                    if seasons ~= nil then
                        print(" -> Updating seasons component")
                        if seasons.season == "summer" then
                            seasons.season = "autumn"
                        end
                        if seasons.preendlessmode then
                            seasons.premode = true
                            seasons.preendlessmode = nil
                        end
                        if seasons.lengths ~= nil then
                            seasons.lengths.autumn = seasons.lengths.summer
                            seasons.lengths.summer = 0
                            seasons.lengths.spring = 0
                        end
                        if seasons.segs ~= nil then
                            seasons.segs.autumn = seasons.segs.summer
                            seasons.segs.summer = { day = 11, dusk = 1, night = 4 }
                            seasons.segs.spring = { day = 5, dusk = 8, night = 3 }
                        end
                    end
                    local weather = savedata.world_network.persistdata.weather
                    if weather ~= nil then
                        print(" -> Updating weather component")
                        if weather.season == "summer" then
                            weather.season = "autumn"
                        end
                    end
                end

                if savedata.map ~= nil and savedata.map.persistdata ~= nil then
                    local worldstate = savedata.map.persistdata.worldstate
                    if worldstate ~= nil then
                        print(" -> Updating worldstate component")
                        worldstate.autumnlength = worldstate.summerlength
                        worldstate.summerlength = 0
                        worldstate.springlength = 0
                        if worldstate.season == "summer" then
                            worldstate.season = "autumn"
                        end
                        worldstate.isautumn = worldstate.issummer
                        worldstate.issummer = false
                        worldstate.isspring = false
                    end

                    local monsters={
                        { "bearger", "never" },
                        { "goosemoose", "never" },
                        { "dragonfly", "never" },
                        { "deciduousmonster", "never" }
                    }
                    local misc={
                        { "frograin", "never" },
                        { "wildfires", "never" }
                    }
                    local original={
                        level_id=2,
                        preset="SURVIVAL_TOGETHER_CLASSIC",
                        tweak={
                            unprepared={
                                cactus="never"
                            },
                            misc={
                                cave_entrance="never",
                                spring="noseason",
                                world_size="large",
                                wildfires="never",
                                summer="noseason",
                                frograin="never",
                                start_setpeice="DefaultStart",
                                season_start="autumn",
                                start_node="Clearing"
                            },
                            animals={
                                moles="never",
                                lightninggoat="never",
                                buzzard="never",
                                catcoon="never"
                            },
                            monsters={
                                bearger="never",
                                deciduousmonster="never",
                                dragonfly="never",
                                goosemoose="never"
                            },
                            resources={
                                rock_ice="never"
                            }
                        }
                    }

                    local overrides = savedata.map.topology and savedata.map.topology.overrides
                    if overrides ~= nil then
                        print("Merging overrides with Vanilla versions")

                        if overrides.monsters then
                            overrides.monsters = MergeKeyValueList(monsters, overrides.monsters)
                        else
                            overrides.monsters = monsters
                        end

                        if overrides.misc then
                            overrides.misc = MergeKeyValueList(misc, overrides.misc)
                        else
                            overrides.misc = misc
                        end

                        if overrides.original then
                            overrides.original = MergeMapsDeep(original, overrides.original)
                        else
                            overrides.original = original
                        end
                        
                    else
                        print("No overrides found, supplying Vanilla versions")
                        savedata.map.topology.overrides = {
                            monsters,
                            misc,
                            original
                        }
                    end
                end

            end,
        }
    },
}

local highestversion = -1
for i,upgrade in ipairs(t.upgrades) do
    assert(upgrade.version > highestversion, string.format("Save file upgrades being applied in wrong order! %s followed %s!",upgrade.version, highestversion))
    highestversion = upgrade.version
end

t.VERSION = highestversion

return t
