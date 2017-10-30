
DEFAULT_GAME_MODE = "survival" --only used when we can't actually find the game mode of a saved server slot

GAME_MODES =
{
	survival	= { text = "",	description = "",	level_type = LEVELTYPE.SURVIVAL,	mod_game_mode = false,	spawn_mode = "fixed",	resource_renewal = false, ghost_sanity_drain = true,	ghost_enabled = true,	portal_rez = false,	reset_time = { time = 120, loadingtime = 180 },	invalid_recipes = {} },
	wilderness	= { text = "",	description = "",	level_type = LEVELTYPE.SURVIVAL,	mod_game_mode = false,	spawn_mode = "scatter", resource_renewal = true,  ghost_sanity_drain = false,	ghost_enabled = false,	portal_rez = false,	reset_time = nil,								invalid_recipes = { "lifeinjector", "resurrectionstatue", "reviver" } },
	endless		= { text = "",	description = "",	level_type = LEVELTYPE.SURVIVAL,	mod_game_mode = false,	spawn_mode = "fixed",	resource_renewal = true,  ghost_sanity_drain = false,	ghost_enabled = true,	portal_rez = true,	reset_time = nil,								invalid_recipes = {} },
}



function AddGameMode( game_mode, game_mode_text )
	GAME_MODES[game_mode] = { modded_mode = true, text = game_mode_text, description = "", level_type = LEVELTYPE.SURVIVAL, mod_game_mode = true, spawn_mode = "fixed", resource_renewal = false, ghost_sanity_drain = false, ghost_enabled = true, portal_rez = false, reset_time = nil, invalid_recipes = {} } 
	return GAME_MODES[game_mode]
end

function GetGameModesSpinnerData( enabled_mods )
	local spinner_data = {}
	for k,v in pairs( GAME_MODES ) do
		if not v.modded_mode then
			table.insert( spinner_data, { text = STRINGS.UI.GAMEMODES[string.upper(k)] or "blank", data = k } )
		end
	end
	
	if enabled_mods ~= nil then 
		--add game modes from mods
		for _,modname in pairs(enabled_mods) do
			local modinfo = KnownModIndex:GetModInfo(modname)
			if modinfo and modinfo.game_modes then
				for _,game_mode in pairs(modinfo.game_modes) do	
					table.insert( spinner_data, { text = game_mode.label or "blank", data = game_mode.name } )
				end
			end
		end
	end

	local function mode_cmp(a,b)
		if a.data == "survival" then
			return true
		elseif a.data == "wilderness" and b.data ~= "survival" then
			return true
		elseif a.data == "endless" and b.data ~= "survival" and b.data ~= "wilderness" then
			return true
		else
			return false
		end
	end
	table.sort(spinner_data, mode_cmp)

	return spinner_data
end

function GetGameModeString( game_mode )
	if game_mode == "" then
		return STRINGS.UI.GAMEMODES.UNKNOWN
	else
		if GAME_MODES[game_mode] then
			return STRINGS.UI.GAMEMODES[string.upper(game_mode)] or GAME_MODES[game_mode].text
		end
		return STRINGS.UI.GAMEMODES.CUSTOM
	end
end

-- For backwards compatibility
function GetGameModeHoverTextString( game_mode )
	return GetGameModeDescriptionString( game_mode )
end

function GetGameModeDescriptionString( game_mode )
	if game_mode == "" then
		return ""
	else
		if GAME_MODES[game_mode] then
			if GAME_MODES[game_mode].hover_text then
				return GAME_MODES[game_mode].hover_text
			else
				return STRINGS.UI.GAMEMODES[string.upper(game_mode).."_DESCRIPTION"] or GAME_MODES[game_mode].description
			end
		end
		return ""
	end
end

function GetIsModGameMode( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].mod_game_mode
	end
	return true	
end

function GetGhostSanityDrain( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].ghost_sanity_drain
	end
	return false
end

function GetIsSpawnModeFixed( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].spawn_mode == "fixed"
	end
	return true
end

function GetSpawnMode( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].spawn_mode
	end
	return "fixed"
end

function GetHasResourceRenewal( game_mode )
    if GAME_MODES[game_mode] then
        return GAME_MODES[game_mode].resource_renewal
    end
    return false
end

function GetGhostEnabled( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].ghost_enabled
	end
	return true
end

function GetPortalRez( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].portal_rez
	end
	return false
end

function GetResetTime( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].reset_time
	end
	return nil
end

function IsRecipeValidInGameMode( game_mode, recipe_name )
	if GAME_MODES[game_mode] ~= nil and GAME_MODES[game_mode].invalid_recipes then
		for _,value in pairs( GAME_MODES[game_mode].invalid_recipes ) do
			if value == recipe_name then
				return false
			end
		end
	end
	return true
end

function GetLevelType( game_mode )
	if GAME_MODES[game_mode] then
		return GAME_MODES[game_mode].level_type
	end
	moderror( string.format("game_mode '%s' not found in GAME_MODES, return default level type", tostring(game_mode)) )
	return LEVELTYPE.SURVIVAL
end
