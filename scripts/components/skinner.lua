local Skinner = Class(function(self, inst) 
	self.inst = inst
	self.skin_name = ""
	self.clothing = { body = "", hand = "", legs = "", feet = "" }

	self.skintype = "normal_skin"
end)

local clothing_order = { "legs", "body", "feet", "hand" }

function SetSkinMode( anim_state, prefab, base_skin, clothing_names, skintype, default_build )
	skintype = skintype or "normal_skin"
	default_build = default_build or ""
	
	--print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	
	anim_state:SetSkin(base_skin, default_build)
	for _,sym in pairs(CLOTHING_SYMBOLS) do
		anim_state:ClearOverrideSymbol(sym)
	end
	
	anim_state:ClearSymbolExchange()
	for _,sym in pairs(HIDE_SYMBOLS) do
		anim_state:ShowSymbol(sym)
	end
					
	--if not ghost, then we need to apply the clothing
	if skintype ~= "ghost_skin" and skintype ~= "werebeaver_skin" then
		local needs_legacy_fixup = not anim_state:BuildHasSymbol( "torso_pelvis" ) --support clothing on legacy mod characters
		local torso_build = nil
		local pelvis_build = nil
		local skirt_build = nil
		
		local hidden_symbols = {}
		
		local tuck_torso = BASE_TORSO_TUCK[base_skin] or "skirt" --tucked into the skirt is the default
		--print( 	"tuck_torso is ", tuck_torso, base_skin )
		
		local allow_arms = true
		local allow_torso = true
		if prefab == "wolfgang" then
			if skintype == "wimpy_skin" then
				--allow clothing
			elseif skintype == "normal_skin" then
				allow_arms = false
			elseif skintype == "mighty_skin" then
				allow_arms = false
			
				--check to see if we're wearing a one piece clothing, if so, allow the torso
				local name = clothing_names["body"]
				if CLOTHING[name] ~= nil then
					local has_torso = false
					local has_pelvis = false
					for _,sym in pairs(CLOTHING[name].symbol_overrides) do
						if sym == "torso" then
							has_torso = true
						end
						if sym == "torso_pelvis" then
							has_pelvis = true
						end
					end
					if has_torso and has_pelvis then
						--one piece clothing, so allow the torso
						allow_torso = true
					else
						allow_torso = false
					end
				end
			end
		end
		
		for num,type in pairs( clothing_order ) do
			local name = clothing_names[type]
			if CLOTHING[name] ~= nil then
				local src_symbols = nil
				if skintype == "wimpy_skin" and CLOTHING[name].symbol_overrides_skinny then
					src_symbols = CLOTHING[name].symbol_overrides_skinny
					allow_arms = true
				elseif skintype == "normal_skin" and (CLOTHING[name].symbol_overrides_skinny or CLOTHING[name].symbol_overrides_mighty) then
					allow_arms = true
				elseif skintype == "mighty_skin" and CLOTHING[name].symbol_overrides_mighty then
					src_symbols = CLOTHING[name].symbol_overrides_mighty
					allow_arms = true
					allow_torso = true
				end

				for _,sym in pairs(CLOTHING[name].symbol_overrides) do
					if not ModManager:IsModCharacterClothingSymbolExcluded( prefab, sym ) then
						if (not allow_torso and sym == "torso") or (not allow_arms and (sym == "arm_upper" or sym == "arm_upper_skin" or sym == "arm_lower")) then
							--skip this symbol for wolfgang
						else
							if sym == "torso" then torso_build = CLOTHING[name].override_build end
							if sym == "torso_pelvis" then pelvis_build = CLOTHING[name].override_build end
							if sym == "skirt" then skirt_build = CLOTHING[name].override_build end
							
							local src_sym = sym
							if src_symbols then
								src_sym = src_symbols[sym] or sym
							end
							anim_state:ShowSymbol(sym)
							hidden_symbols[sym] = nil --remove it from the hidden list
							anim_state:OverrideSkinSymbol(sym, CLOTHING[name].override_build, src_sym )
							
							--print("setting skin", sym, CLOTHING[name].override_build )
								
							--override the base skin's torso_tuck value
							if CLOTHING[name].torso_tuck ~= nil then
								tuck_torso = CLOTHING[name].torso_tuck
								--print("setting tuck_torso to", tuck_torso, name )
							end
						end
					end
				end
				
				if CLOTHING[name].symbol_hides then
					for _,sym in pairs(CLOTHING[name].symbol_hides) do
						anim_state:HideSymbol(sym)
						hidden_symbols[sym] = true
					end
				end
			end
		end
		
		
		local torso_symbol = "torso"
		local pelvis_symbol = "torso_pelvis"
		
		--Certain builds need to use the wide versions to fit clothing, nil build indicates it will use the base
		if (BASE_ALTERNATE_FOR_BODY[base_skin] and torso_build == nil and pelvis_build ~= nil)
			or (BASE_ALTERNATE_FOR_SKIRT[base_skin] and torso_build == nil and skirt_build ~= nil) then
			torso_symbol = "torso_wide"
			--print("torso replaced with torso_wide")
			anim_state:OverrideSkinSymbol("torso", base_skin, torso_symbol )
		end
		
		if (BASE_ALTERNATE_FOR_BODY[base_skin] and torso_build ~= nil and pelvis_build == nil) 
			or (BASE_ALTERNATE_FOR_SKIRT[base_skin] and skirt_build ~= nil and pelvis_build == nil) then
			pelvis_symbol = "torso_pelvis_wide"
			if not hidden_symbols["torso_pelvis"] then
				--print("torso_pelvis replaced with torso_pelvis_wide")
				anim_state:OverrideSkinSymbol("torso_pelvis", base_skin, pelvis_symbol )
			end
		end
		
		if BASE_ALTERNATE_FOR_BODY[base_skin] and torso_build ~= nil and skirt_build == nil then
			if not hidden_symbols["skirt_wide"] then
				--print("skirt replaced with skirt_wide")
				anim_state:OverrideSkinSymbol("skirt", base_skin, "skirt_wide")
			end
		end
		
		
		--characters with skirts, and untucked torso clothing need to exchange the render order of the torso and skirt so that the torso is above the skirt
		if tuck_torso == "untucked" then
			--print("torso over the skirt")
			anim_state:SetSymbolExchange( "skirt", "torso" )
		end
		
		if tuck_torso == "full" then
			torso_build = torso_build or base_skin
			pelvis_build = pelvis_build or base_skin
			if not hidden_symbols["torso_pelvis"] and not hidden_symbols["torso"] then
				--print("put the pelvis on top of the base torso")
				anim_state:OverrideSkinSymbol("torso", pelvis_build, pelvis_symbol ) --put the pelvis on top of the base torso by putting it in the torso slot
				--print("put the torso in pelvis slot")
				anim_state:OverrideSkinSymbol("torso_pelvis", torso_build, torso_symbol ) --put the torso in pelvis slot to go behind			
			end
		elseif needs_legacy_fixup then
			if torso_build ~= nil and pelvis_build ~= nil then
				--fully clothed, no fixup required
			elseif torso_build == nil and pelvis_build ~= nil then
				--print("~~~~~ put base torso behind, [" .. base_skin .. "]")
				anim_state:OverrideSkinSymbol("torso_pelvis", base_skin, torso_symbol ) --put the base torso in pelvis slot to go behind
				anim_state:OverrideSkinSymbol("torso", pelvis_build, pelvis_symbol ) --put the clothing pelvis on top of the base torso by putting it in the torso slot
			elseif torso_build ~= nil and pelvis_build == nil then
				--print("~~~~~ fill in the missing pelvis, [" .. base_skin .. "]")
				anim_state:OverrideSkinSymbol("torso_pelvis", base_skin, "torso" ) --fill in the missing pelvis, with the base torso
			else
				--no clothing at all, nothing to fixup
			end
		end
	end
end

function ClearClothing( anim_state, clothing_names )
	for _,name in pairs(clothing_names) do
		if name ~= nil and name ~= "" and CLOTHING[name] ~= nil then
			for _,sym in pairs(CLOTHING[name].symbol_overrides) do
				anim_state:ClearOverrideSymbol(sym)
			end
		end
	end
end

function Skinner:ClearAllClothing(anim_state)
	ClearClothing(anim_state, self.clothing)
end

function Skinner:SetSkinMode(skintype, default_build)
	skintype = skintype or self.skintype
	local base_skin = ""

	self.skintype = skintype

	if self.skin_data == nil then
		--fix for legacy saved games with already spawned players that don't have a skin_name set
		self:SetSkinName(self.inst.prefab.."_none")
	end
	
	if skintype == "ghost_skin" then
		base_skin = self.skin_data[skintype] or self.inst.ghostbuild or default_build or "ghost_" .. self.inst.prefab .. "_build"
	else
		base_skin = self.skin_data[skintype] or default_build or self.inst.prefab
	end
	
	SetSkinMode( self.inst.AnimState, self.inst.prefab, base_skin, self.clothing, skintype, default_build )
	
	self.inst.Network:SetPlayerSkin( self.skin_name or "", self.clothing["body"] or "", self.clothing["hand"] or "", self.clothing["legs"] or "", self.clothing["feet"] or "" )
end

function Skinner:SetSkinName(skin_name)
	self.skin_name = skin_name
	self.skin_data = {}
	if self.skin_name ~= nil and self.skin_name ~= "" then
		local skin_prefab = Prefabs[skin_name] or nil
		if skin_prefab and skin_prefab.skins then
			for k,v in pairs(skin_prefab.skins) do
				self.skin_data[k] = v
			end
		end
	end
	self:SetSkinMode()
end

function Skinner:_InternalSetClothing( type, name )

	if self.clothing[type] and self.clothing[type] ~= "" then
		self.inst:PushEvent("unequipskinneditem", self.clothing[type])
	end
	
	self.clothing[type] = name
	
	if name and name ~= "" then
		self.inst:PushEvent("equipskinneditem", name)
	end
	
	self:SetSkinMode()
end

function IsValidClothing( name )
	return name ~= nil and name ~= "" and CLOTHING[name] ~= nil
end

function Skinner:SetClothing( name )
	if IsValidClothing(name) then
		self:_InternalSetClothing( CLOTHING[name].type, name )
	end
end

function Skinner:GetClothing()
	local temp_clothing = {}
	temp_clothing.base = self.skin_name
	temp_clothing.body = self.clothing.body
	temp_clothing.hand = self.clothing.hand
	temp_clothing.legs = self.clothing.legs
	temp_clothing.feet = self.clothing.feet
	return temp_clothing
end

function Skinner:ClearClothing(type)
	self:_InternalSetClothing( type, "" )
end

function Skinner:OnSave()
	return {skin_name = self.skin_name, clothing = self.clothing}
end

function Skinner:OnLoad(data)
	if data.clothing then
		self.clothing = data.clothing
		
		--it's possible that the clothing was traded away. Check to see if the player still owns it on load.
		for type,clothing in pairs( self.clothing ) do
			if clothing ~= "" and not TheInventory:CheckClientOwnership(self.inst.userid, clothing) then
				self.clothing[type] = ""
			end
		end
	end
	
	local skin_name = self.inst.prefab.."_none"
	if data.skin_name then
		skin_name = data.skin_name
		--clean up any traded away base skins
		if data.skin_name ~= self.inst.prefab.."_none" and not TheInventory:CheckClientOwnership(self.inst.userid, data.skin_name) then
			skin_name = self.inst.prefab.."_none"
		end
	end
	self:SetSkinName(skin_name)
end

return Skinner
