local Skinner = Class(function(self, inst) 
	self.inst = inst
	self.skin_data = {}
	self.clothing = { body = "", hand = "", legs = "" }

	self.skintype = "normal_skin"
end)

function SetSkinMode( anim_state, prefab, base_skin, clothing_names, skintype, default_build )
	skintype = skintype or "normal_skin"
	default_build = default_build or ""
	
	anim_state:SetSkin(base_skin, default_build)
	for _,sym in pairs(CLOTHING_SYMBOLS) do
		anim_state:ClearOverrideSymbol(sym)
	end
	anim_state:ClearOverrideSymbol("skirt")--hack for wicker's skirt since it's not technically a clothing symbol yet	
	anim_state:ClearSymbolExchange()
	for _,sym in pairs(HIDE_SYMBOLS) do
		anim_state:Show(sym)
	end
	
	--if not ghost, then we need to apply the clothing
	if skintype ~= "ghost_skin" then
		local needs_legacy_fixup = not anim_state:BuildHasSymbol( "torso_pelvis" ) --support clothing on legacy mod characters
		local torso_build = nil
		local pelvis_build = nil
		local skirt_build = nil
		
		local hidden_symbols = {}
		
		local tuck_torso = BASE_TORSO_TUCK[base_skin] ~= nil
	
		local allow_arms = true
		local allow_torso = true
		if prefab == "wolfgang" then
			if skintype == "wimpy_skin" then
				--allow clothing
			elseif skintype == "normal_skin" then
				allow_arms = false
			elseif skintype == "mighty_skin" then
				allow_arms = false
				allow_torso = false
			end
		end
		
		for _,name in pairs( clothing_names ) do
			if CLOTHING[name] ~= nil then
				for _,sym in pairs(CLOTHING[name].symbol_overrides) do				
					if not ModManager:IsModCharacterClothingSymbolExcluded( prefab, sym ) then
						if (sym ~= "torso" and sym ~= "arm_upper" and sym ~= "arm_upper_skin" and sym ~= "arm_lower" )
						or (sym == "torso" and allow_torso)
						or ((sym == "arm_upper" or sym == "arm_upper_skin" or sym == "arm_lower") and allow_arms) then
							
							if sym == "torso" then torso_build = CLOTHING[name].override_build end
							if sym == "torso_pelvis" then pelvis_build = CLOTHING[name].override_build end
							if sym == "skirt" then skirt_build = CLOTHING[name].override_build end
							
							anim_state:OverrideSkinSymbol(sym, CLOTHING[name].override_build, sym )
							
							--override the base skin's torso_tuck value
							if CLOTHING[name].torso_tuck ~= nil then
								tuck_torso = CLOTHING[name].torso_tuck
							end
						end
					end
				end
				
				if CLOTHING[name].symbol_hides then
					for _,sym in pairs(CLOTHING[name].symbol_hides) do
						anim_state:Hide(sym)
						hidden_symbols[sym] = true
					end
				end
			end
		end
		
		for _,name in pairs( clothing_names ) do
			if CLOTHING[name] ~= nil then
				if CLOTHING[name].symbol_force_show	then
					for _,sym in pairs(CLOTHING[name].symbol_force_show) do
						anim_state:Show(sym)
					end
				end
			end
		end
		
		local torso_symbol = "torso"
		local pelvis_symbol = "torso_pelvis"
		
		--Wes and wicker need to use the wide versions of the base to fit clothing, nil build indicates it will use the base
		if (prefab == "wickerbottom" or prefab == "wes" or prefab == "wendy") and ((torso_build ~= pelvis_build) or (torso_build ~= skirt_build)) then
			if torso_build == nil then
				torso_symbol = "torso_wide"
				anim_state:OverrideSkinSymbol("torso", base_skin, torso_symbol )
			end
			if pelvis_build == nil then 
				pelvis_symbol = "torso_pelvis_wide"
				if not hidden_symbols["torso_pelvis"] then
					anim_state:OverrideSkinSymbol("torso_pelvis", base_skin, pelvis_symbol )
				end
				if prefab == "wickerbottom" and skirt_build == nil then
					anim_state:OverrideSkinSymbol("skirt", base_skin, "skirt_wide")
				end
			end
		end
		
		--characters with skirts, and untucked torso clothing need to exchange the render order of the torso and skirt
		if not tuck_torso and torso_build ~= nil then
			anim_state:SetSymbolExhange( "skirt", "torso" )
		end
		
		if tuck_torso then
			torso_build = torso_build or base_skin
			pelvis_build = pelvis_build or base_skin
			if not hidden_symbols["torso_pelvis"] then
				anim_state:OverrideSkinSymbol("torso", pelvis_build, pelvis_symbol ) --put the pelvis on top of the base torso by putting it in the torso slot
			end
			if not hidden_symbols["torso"] then
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

	if skintype ~= "ghost_skin" then
		base_skin = self.skin_data[skintype] or default_build or self.inst.prefab
	else
		base_skin = self.skin_data[skintype] or self.inst.ghostbuild or default_build or "ghost_" .. self.inst.prefab .. "_build"   
	end
	
	SetSkinMode( self.inst.AnimState, self.inst.prefab, base_skin, self.clothing, skintype, default_build )
	
	self.inst.Network:SetPlayerSkin( self.skin_name or "", self.clothing["body"] or "", self.clothing["hand"] or "", self.clothing["legs"] or "" )
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
	temp_clothing.base = self.skin_name and #self.skin_name > 0 and self.skin_name or (self.inst.prefab.."_none")
	temp_clothing.body = self.clothing.body
	temp_clothing.hand = self.clothing.hand
	temp_clothing.legs = self.clothing.legs
	return temp_clothing
end

function Skinner:ClearClothing(type)
	self:_InternalSetClothing( type, "" )
end

function Skinner:OnSave()
	return {skin_name = self.skin_name, clothing = self.clothing}
end

function Skinner:OnLoad(data)
	if data.skin_name then
		self:SetSkinName(data.skin_name)
	end
	if data.clothing then
		self.clothing = data.clothing
	end
end

return Skinner
