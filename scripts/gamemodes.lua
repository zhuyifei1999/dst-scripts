
DEFAULT_GAME_MODE = "survival" --only used when we can't actually find the game mode of a saved server slot

GAME_MODES =
{
	survival	= { text = STRINGS.UI.GAMEMODES.SURVIVAL,	hover_text = STRINGS.UI.GAMEMODES.SURVIVAL_TOOLTIP,		mod_game_mode = false,	spawn_mode = "fixed",	resource_renewal = false, ghost_sanity_drain = true,	ghost_enabled = true,	portal_rez = false,	reset_time = { time = 120, loadingtime = 180 },	invalid_recipes = {} },
	wilderness	= { text = STRINGS.UI.GAMEMODES.WILDERNESS,	hover_text = STRINGS.UI.GAMEMODES.WILDERNESS_TOOLTIP,	mod_game_mode = false,	spawn_mode = "scatter", resource_renewal = true,  ghost_sanity_drain = false,	ghost_enabled = false,	portal_rez = false,	reset_time = nil,								invalid_recipes = { "lifeinjector", "resurrectionstatue", "reviver" } },
	endless		= { text = STRINGS.UI.GAMEMODES.ENDLESS,	hover_text = STRINGS.UI.GAMEMODES.ENDLESS_TOOLTIP,		mod_game_mode = false,	spawn_mode = "fixed",	resource_renewal = true,  ghost_sanity_drain = false,	ghost_enabled = true,	portal_rez = true,	reset_time = nil,								invalid_recipes = {} },
}



function AddGameMode( game_mode, game_mode_text )
	GAME_MODES[game_mode] = { text = game_mode_text, hover_text = "", mod_game_mode = true, spawn_mode = "fixed", resource_renewal = false, ghost_sanity_drain = false, ghost_enabled = true, portal_rez = false, reset_time = nil, invalid_recipes = {} } 
	return GAME_MODES[game_mode]
end

function GetGameModesSpinnerData()
	local spinner_data = {}
	for k,v in pairs( GAME_MODES ) do
		table.insert( spinner_data, { text = v.text or "blank", data = k } )
	end
	return spinner_data
end

function GetGameModeString( game_mode )
	if game_mode == "" then
		return ""
	else
		if GAME_MODES[game_mode] then
			return GAME_MODES[game_mode].text
		end
		return STRINGS.UI.GAMEMODES.CUSTOM
	end
end

function GetGameModeHoverTextString( game_mode )
	if game_mode == "" then
		return ""
	else
		if GAME_MODES[game_mode] then
			return GAME_MODES[game_mode].hover_text
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

function GetGameModeStringWithDetails( game_mode, world, day )
	local gamemode_str = GetGameModeString( game_mode )
    return string.format( "%s %d-%d", gamemode_str, world, day )
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