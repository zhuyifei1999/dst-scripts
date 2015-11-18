local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Puppet = require "widgets/skinspuppet"
local Spinner = require "widgets/spinner"
local AnimSpinner = require "widgets/animspinner"


local TEMPLATES = require "widgets/templates"

-------------------------------------------------------------------------------------------------------
-- onNextFn and onPrevFn are called when the base spinner is changed. They should be used to 
-- update the portrait picture.

-- See wardropepopup for definitions of recent_item_types and recent_item_ids
local DressupPanel = Class(Widget, function(self, owner, profile, onNextFn, onPrevFn, useCollectionTime, recent_item_types, recent_item_ids)
    self.owner = owner

    Widget._ctor(self, "DressupPanel")

    --print("DressupPanel constructor", self, owner, profile or "nil", onNextFn or "nil", onPrevFn or "nil")

    self.profile = profile
    self:GetClothingOptions()
    self:GetSkinsList()

    self.use_collection_time = useCollectionTime
    self.recent_item_types = recent_item_types
    -- ids can be ignored at least for now.

    self.onNextFn = onNextFn
    self.onPrevFn = onPrevFn

	self.dressup = self:AddChild(TEMPLATES.CurlyWindow(10, 450, .6, .6, 39, -25))
    self.dressup:SetPosition(RESOLUTION_X - 250,RESOLUTION_Y-330,0)

	self.dressup_bg = self.dressup:AddChild(Image("images/serverbrowser.xml", "side_panel.tex"))
	self.dressup_bg:SetScale(-.66, -.7)
	self.dressup_bg:SetPosition(5, 5)

	if not TheNet:IsOnlineMode() then
		self.dressup_hanger = self.dressup:AddChild(Image("images/lobbyscreen.xml", "customization_coming_image_all.tex"))
		self.dressup_hanger:SetScale(.66, .7)

		local text1 = self.dressup:AddChild(Text(TALKINGFONT, 30, STRINGS.UI.LOBBYSCREEN.CUSTOMIZE))
		text1:SetPosition(10,150) 
		text1:SetHAlign(ANCHOR_MIDDLE)
		text1:SetColour(unpack(GREY))

		local text2 = self.dressup:AddChild(Text(TALKINGFONT, 30, STRINGS.UI.LOBBYSCREEN.OFFLINE))
		text2:SetPosition(10,-100) 
		text2:SetHAlign(ANCHOR_MIDDLE)
		text2:SetColour(unpack(GREY))
	else

		self.dressup_frame = self.dressup:AddChild(Widget("frame"))

		local title_height = 190
		if not TUNING.SKINS_BASE_ENABLED then
			title_height = 110
		end


		self.puppet = self.dressup:AddChild(Puppet())
		self.puppet:SetPosition( 10, title_height - 35)
		self.puppet:SetScale(1.9)

		self.shadow = self.dressup:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
	    self.shadow:SetPosition(8, title_height - 40)
	    self.shadow:SetScale(.35)

	    self.random_avatar = self.dressup:AddChild(Image("images/lobbyscreen.xml", "randomskin.tex"))
		self.random_avatar:SetPosition(10, title_height + 40)
		self.random_avatar:SetScale(.38)
		self.random_avatar:Hide()

		
		local body_offset = 55
		local vert_scale = .56
		if not TUNING.SKINS_BASE_ENABLED then 
			body_offset = 55  -- use 145 to put it at the top. 
			vert_scale = .43
		end
		
		if TUNING.SKINS_BASE_ENABLED then 
			self.upper_horizontal_line = self.dressup_frame:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
		    self.upper_horizontal_line:SetScale(.19, .4)
		    self.upper_horizontal_line:SetPosition(10, 145, 0)
		end

	    self.mid_horizontal_line1 = self.dressup_frame:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
	    self.mid_horizontal_line1:SetScale(.19, .4)
	    self.mid_horizontal_line1:SetPosition(10, body_offset, 0)

	    self.mid_horizontal_line2 = self.dressup_frame:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
	    self.mid_horizontal_line2:SetScale(.19, .4)
	    self.mid_horizontal_line2:SetPosition(10, body_offset-90, 0)

	    self.mid_horizontal_line3 = self.dressup_frame:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
	    self.mid_horizontal_line3:SetScale(.19, .4)
	    self.mid_horizontal_line3:SetPosition(10, body_offset-180, 0)

	    self.lower_horizontal_line = self.dressup_frame:AddChild(Image("images/ui.xml", "line_horizontal_5.tex"))
	    self.lower_horizontal_line:SetScale(.19, .4)
	    self.lower_horizontal_line:SetPosition(10, body_offset-270, 0)

	    self.left_vertical_line = self.dressup_frame:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
	    self.left_vertical_line:SetScale(.45, vert_scale)
	    self.left_vertical_line:SetPosition(-100, -81, 0)

	    self.right_vertical_line = self.dressup_frame:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
	    self.right_vertical_line:SetScale(.45, vert_scale)
	    self.right_vertical_line:SetPosition(120, -81, 0)

	    if TUNING.SKINS_BASE_ENABLED then 
	    	self.left_vertical_line:SetPosition(-100, 45-81, 0)
	    	self.right_vertical_line:SetPosition(120, 45-81, 0)

		    self.base_title = self.dressup_frame:AddChild(Text(NEWFONT, 20, STRINGS.UI.LOBBYSCREEN.SKINS_BASE))
			self.base_title:SetColour(0, 0, 0, 1)
			self.base_title:SetPosition(-110, 100)
			self.base_title.inst.UITransform:SetRotation(90)

			self.base_spinner = self.dressup:AddChild(self:MakeSpinner("base"))
			self.base_spinner:SetPosition(0, 62)
		end

		self.body_title = self.dressup_frame:AddChild(Text(NEWFONT, 20, STRINGS.UI.LOBBYSCREEN.SKINS_BODY))
		self.body_title:SetColour(0, 0, 0, 1)
		self.body_title:SetPosition(-110, body_offset - 45)
		self.body_title.inst.UITransform:SetRotation(90)

		self.body_spinner = self.dressup:AddChild(self:MakeSpinner("body"))
		self.body_spinner:SetPosition(0, body_offset-82)

		self.hand_title = self.dressup_frame:AddChild(Text(NEWFONT, 20, STRINGS.UI.LOBBYSCREEN.SKINS_HANDS))
		self.hand_title:SetColour(0, 0, 0, 1)
		self.hand_title:SetPosition(-110, body_offset-55-80)
		self.hand_title.inst.UITransform:SetRotation(90)

		self.hand_spinner = self.dressup:AddChild(self:MakeSpinner("hand"))
		self.hand_spinner:SetPosition(0, body_offset-55-118)

		self.legs_title = self.dressup_frame:AddChild(Text(NEWFONT, 20, STRINGS.UI.LOBBYSCREEN.SKINS_LEGS))
		self.legs_title:SetColour(0, 0, 0, 1)
		self.legs_title:SetPosition(-110, body_offset-55-170)
		self.legs_title.inst.UITransform:SetRotation(90)

		self.legs_spinner = self.dressup:AddChild(self:MakeSpinner("legs"))
		self.legs_spinner:SetPosition(0, body_offset-55-208)

		self.default_focus = self.body_spinner.spinner
		self.focus_forward = self.body_spinner.spinner
	end

	self:DoFocusHookups()

end)

function DressupPanel:ReverseFocus()
	self.default_focus = self.legs_spinner.spinner
	self.focus_forward = self.legs_spinner.spinner
end

function DressupPanel:MakeSpinner(slot)

	local spinner_group = Widget("spinner group")

	local textures = {
		arrow_left_normal = "arrow2_left.tex",
		arrow_left_over = "arrow2_left_over.tex",
		arrow_left_disabled = "arrow_left_disabled.tex",
		arrow_left_down = "arrow2_left_down.tex",
		arrow_right_normal = "arrow2_right.tex",
		arrow_right_over = "arrow2_right_over.tex",
		arrow_right_disabled = "arrow_right_disabled.tex",
		arrow_right_down = "arrow2_right_down.tex",
		bg_middle = "blank.tex",
		bg_middle_focus = "spinner_focus.tex", --"box_2.tex",
		bg_middle_changing = "blank.tex",
		bg_end = "blank.tex",
		bg_end_focus = "blank.tex",
		bg_end_changing = "blank.tex",
	}


	local spinner_width = 220
	local spinner_height = 68
	

	local skin_options = self:GetSkinOptionsForSlot(slot)

	local bg = spinner_group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
	bg:SetSize(220, 28)
	bg:SetPosition(10, 6, 0)

	spinner_group.shadow = spinner_group:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
    spinner_group.shadow:SetPosition(10, 21)

    if slot == "base" then 
    	spinner_group.shadow:SetScale(.15)
    else 
    	spinner_group.shadow:SetScale(.25)
    end
  
    spinner_group.new_tag = spinner_group:AddChild(Image("images/ui.xml", "new_label.tex"))
    spinner_group.new_tag:SetScale(.8)
    spinner_group.new_tag:SetPosition(60, 63) 

    spinner_group.new_label = spinner_group.new_tag:AddChild(Text(BODYTEXTFONT, 20, STRINGS.UI.SKINSSCREEN.NEW))
    spinner_group.new_label.inst.UITransform:SetRotation(43)
    spinner_group.new_label:SetPosition(1, 4)
    spinner_group.new_label:SetColour(WHITE)

    spinner_group.new_tag:Hide()

	spinner_group.slot = slot

	spinner_group.spinner = spinner_group:AddChild(AnimSpinner( skin_options, spinner_width, nil, {font=NEWFONT_OUTLINE, size=24}, nil, nil, textures, true, 200, nil ))
	spinner_group.spinner:SetAnim("frames_comp", "fr", "icon", "SWAP_ICON", true)
	spinner_group.spinner:SetTextColour(0,0,0,1)
	spinner_group.spinner:SetPosition(10, 46, 0)
	spinner_group.spinner.text:SetPosition(0, -40)
	spinner_group.spinner.fganim:SetScale(.53)
	spinner_group.spinner.fganim:SetPosition(0, 6)
	spinner_group.spinner.background:ScaleToSize(spinner_width + 2, spinner_height)
	spinner_group.spinner.background:SetPosition(0, 4)

	if slot == "base" then 
		spinner_group.GetItem = 
			function() 
				local which = spinner_group.spinner:GetSelectedIndex()
				local name = skin_options[which].build
				return name
			end

		spinner_group.spinner.OnNext = function() if self.onNextFn then 
													self.onNextFn()
												  end
										end

		spinner_group.spinner:SetOnChangedFn(function()
												  local which = spinner_group.spinner:GetSelectedIndex()
												  if skin_options[which].new_indicator then 
												  	spinner_group.new_tag:Show()
												  	--print("Showing new tag", spinner_group.GetItem())
												  else
												  	spinner_group.new_tag:Hide()
												  	--print("Hiding new_tag", spinner_group.GetItem())
												  end
												  self.inst:DoTaskInTime(0, function() self:SetPuppetSkins() end)
										end)
		spinner_group.spinner.OnPrev = function() if self.onPrevFn then 
													self.onPrevFn()
												  end
										end
	else
		spinner_group.GetItem = 
			function() 
				local which = spinner_group.spinner:GetSelectedIndex()
				local name = skin_options[which].build
				return name
			end
		spinner_group.spinner:SetOnChangedFn(function() 
							if self.currentcharacter ~= "random" then 
								local which = spinner_group.spinner:GetSelectedIndex()
								if skin_options[which].new_indicator then 
								  	spinner_group.new_tag:Show()
								  	--print("Showing new tag", spinner_group.GetItem())
								else
								  	spinner_group.new_tag:Hide()
								  	--print("Hiding new_tag", spinner_group.GetItem())
								end
								self.inst:DoTaskInTime(0, function() self:SetPuppetSkins() end)
							end 
						end)
	end

	spinner_group.GetIndexForSkin = function(this, skin)

			local slot = this.slot
			--print("looking for ", skin, "for ", slot)
			local options = skin_options

			for i=1, #options do
				if options[i].build == skin then 
					return i
				end
			end

			return 1
		end

	spinner_group.focus_forward = spinner_group.spinner
	return spinner_group

end



function DressupPanel:GetSkinOptionsForSlot(slot)

	local skin_options = {}

	local dressup_timestamp = (self.use_collection_time and self.profile:GetCollectionTimestamp()) or self.profile:GetDressupTimestamp()

	local function IsInList(list, build)
		for k,v in pairs(list) do 
			--print("Checking for ", build, "in", dumptable(v))
			if v.build == build then 
				return k
			end
		end

		return nil
	end

		
	--print("Default string is ", default, " for ", slot)

	local image_name = nil

	if not image_name then 
		if slot == "body" then 
			image_name = "body_default1"
		elseif slot == "hand" then 
			image_name = "hand_default1"
		elseif slot == "legs" then 
			image_name = "legs_default1"
		else
			image_name = "default"
		end
	end

	local colour = SKIN_RARITY_COLORS["Common"]
	table.insert(skin_options, 
	{
		text = STRINGS.SKIN_NAMES["none"], 
		data = nil,
		build = image_name,
		symbol = "SWAP_ICON",
		colour = colour,
		new_indicator = false,
	})

	--print("Building skin_options")
	for which = 1, #self.skins_list do 
		if self.skins_list[which].type == slot then 
			--print(self.skins_list[which].item or "?", "Got timestamp", self.skins_list[which].timestamp or "nil", dressup_timestamp)
			local new_indicator = not self.skins_list[which].timestamp or (self.skins_list[which].timestamp > dressup_timestamp)
			image_name = self.skins_list[which].item
			local rarity = GetRarityForItem(slot, image_name)
			local colour = rarity and SKIN_RARITY_COLORS[rarity] or SKIN_RARITY_COLORS["Common"]
			local text_name = GetName(self.skins_list[which].item)
			local key = IsInList(skin_options, image_name)

			if new_indicator and key then 
				skin_options[key].new_indicator = true
				
			elseif new_indicator or not key then 

				table.insert(skin_options,  
				{
					text = text_name or STRINGS.SKIN_NAMES["missing"], 
					data = nil,
					build = image_name,
					symbol = "SWAP_ICON",
					colour = colour,
					new_indicator = new_indicator,
				})
			end
		end
	end
	--print("done building skin options")
	

	return skin_options
end


function DressupPanel:UpdateSpinners()
	if self.currentcharacter == "random" then 
		--self:DisableSpinners()

		if TUNING.SKINS_BASE_ENABLED and self.base_spinner then 
			self.base_spinner.spinner:SetOptions(self:GetSkinOptionsForRandom())
			self.base_spinner.spinner:SetSelectedIndex(1)
		end

		if self.body_spinner then 
			self.body_spinner.spinner:SetOptions(self:GetSkinOptionsForRandom())
			self.body_spinner.spinner:SetSelectedIndex(1)
		end

		if self.hand_spinner then 
			self.hand_spinner.spinner:SetOptions(self:GetSkinOptionsForRandom())
			self.hand_spinner.spinner:SetSelectedIndex(1)
		end

		if self.legs_spinner then 
			self.legs_spinner.spinner:SetOptions(self:GetSkinOptionsForRandom())
			self.legs_spinner.spinner:SetSelectedIndex(1)
		end

		if self.owner.SetPortraitImage then 
			self.owner:SetPortraitImage(0)
		end
		return
	else
		self:EnableSpinners()
	end

	self:Reset(true)

end


function DressupPanel:DoFocusHookups()
    
	if self.base_spinner and self.body_spinner then 
        self.base_spinner:SetFocusChangeDir(MOVE_DOWN, self.body_spinner)
        self.body_spinner:SetFocusChangeDir(MOVE_UP, self.base_spinner)
    end

    if self.body_spinner and self.hand_spinner then 
        self.body_spinner:SetFocusChangeDir(MOVE_DOWN, self.hand_spinner)
        self.hand_spinner:SetFocusChangeDir(MOVE_UP, self.body_spinner)
    end

    if self.hand_spinner and self.legs_spinner then 
        self.hand_spinner:SetFocusChangeDir(MOVE_DOWN, self.legs_spinner)
        self.legs_spinner:SetFocusChangeDir(MOVE_UP, self.hand_spinner)
    end

end

function DressupPanel:Reset(set_spinner_to_new_item)

	local savedSkinsForCharacter = self.profile:GetSkinsForCharacter(self.currentcharacter)

	-- self.owner is WardrobePopup, self.owner.owner is the player
	local playerdata = self.owner.owner and TheNet:GetClientTableForUser(self.owner.owner.userid) or nil

	local recent_item_type = self.recent_item_types and GetTypeForItem(self.recent_item_types[1]) or nil


	--[[print("Updating spinners with ", self.currentcharacter)
	for k,v in pairs(savedSkinsForCharacter) do 
		print(k, v)
	end]]

	if self.base_spinner then 
		self.base_spinner.spinner:SetOptions(self:GetSkinOptionsForSlot("base"))

		if set_spinner_to_new_item and recent_item_type and recent_item_type == "base" then 
			self.base_spinner.spinner:SetSelectedIndex(self.base_spinner:GetIndexForSkin(self.recent_item_types[1]))
		elseif playerdata and playerdata.base_skin then 
			self.base_spinner.spinner:SetSelectedIndex(self.base_spinner:GetIndexForSkin(playerdata.base_skin))
		elseif savedSkinsForCharacter.base and savedSkinsForCharacter.base ~= "" then 
			self.base_spinner.spinner:SetSelectedIndex(self.base_spinner:GetIndexForSkin(savedSkinsForCharacter.base))
		else
			self.base_spinner.spinner:SetSelectedIndex(1)
		end
	end

	if self.body_spinner then 
		self.body_spinner.spinner:SetOptions(self:GetSkinOptionsForSlot("body"))

		if set_spinner_to_new_item and recent_item_type and recent_item_type == "body" then 
			self.body_spinner.spinner:SetSelectedIndex(self.body_spinner:GetIndexForSkin(self.recent_item_types[1]))
		elseif playerdata and playerdata.body_skin then 
			self.body_spinner.spinner:SetSelectedIndex(self.body_spinner:GetIndexForSkin(playerdata.body_skin))
		elseif savedSkinsForCharacter.body and savedSkinsForCharacter.body ~= "" then 
			self.body_spinner.spinner:SetSelectedIndex(self.body_spinner:GetIndexForSkin(savedSkinsForCharacter.body))
		else
			self.body_spinner.spinner:SetSelectedIndex(1)
		end
	end

	if self.hand_spinner then 
		self.hand_spinner.spinner:SetOptions(self:GetSkinOptionsForSlot("hand"))

		if set_spinner_to_new_item and recent_item_type and recent_item_type == "hand" then 
			self.hand_spinner.spinner:SetSelectedIndex(self.hand_spinner:GetIndexForSkin(self.recent_item_types[1]))
		elseif playerdata and playerdata.hand_skin then 
			self.hand_spinner.spinner:SetSelectedIndex(self.hand_spinner:GetIndexForSkin(playerdata.hand_skin))
		elseif  savedSkinsForCharacter.hand and savedSkinsForCharacter.hand ~= "" then 
			self.hand_spinner.spinner:SetSelectedIndex(self.hand_spinner:GetIndexForSkin(savedSkinsForCharacter.hand))
		else
			self.hand_spinner.spinner:SetSelectedIndex(1)
		end
	end

	if self.legs_spinner then 
		self.legs_spinner.spinner:SetOptions(self:GetSkinOptionsForSlot("legs"))

		if set_spinner_to_new_item and recent_item_type and recent_item_type == "legs" then 
			self.legs_spinner.spinner:SetSelectedIndex(self.legs_spinner:GetIndexForSkin(self.recent_item_types[1]))
		elseif playerdata and playerdata.legs_skin then 
			self.legs_spinner.spinner:SetSelectedIndex(self.legs_spinner:GetIndexForSkin(playerdata.legs_skin))
		elseif savedSkinsForCharacter.legs and savedSkinsForCharacter.legs ~= "" then 
			self.legs_spinner.spinner:SetSelectedIndex(self.legs_spinner:GetIndexForSkin(savedSkinsForCharacter.legs))
		else
			self.legs_spinner.spinner:SetSelectedIndex(1)
		end
	end

	if self.puppet then 
		self:UpdatePuppet()
	end

end

-- This is the full skins list, which is used to populate the spinners
-- (Duplicates are removed.)
function DressupPanel:GetSkinsList()
	--print("Getting skins list (full inventory)")

	local templist = TheInventory:GetFullInventory()
	self.skins_list = {}
	self.timestamp = 0

	for k,v in ipairs(templist) do 
		local type, item = GetTypeForItem(v.item_type)
		self.skins_list[k] = {}
		self.skins_list[k].type = type
		self.skins_list[k].item = item
		self.skins_list[k].timestamp = v.modified_time
		--self.skins_list[k].item_id = v.item_id

		if v.modified_time > self.timestamp then 
			self.timestamp = v.modified_time
		end
	end
end

-- These lists don't have duplicates, and are used for the random option
function DressupPanel:GetClothingOptions()
	self.clothing_options = {}
	self.clothing_options["body"] = self.profile:GetClothingOptionsForType("body")
	self.clothing_options["hand"] = self.profile:GetClothingOptionsForType("hand")
	self.clothing_options["legs"] = self.profile:GetClothingOptionsForType("legs")	
	--print("Got clothing options", #self.clothing_options["body"], #self.clothing_options["hand"], #self.clothing_options["legs"])
end

function DressupPanel:GetSkinOptionsForRandom()

	local skin_options = {}

	table.insert(skin_options,  
			{
				text = STRINGS.UI.LOBBYSCREEN.SKINS_PREVIOUS, 
				data = nil,
				build = "previous_skin",
				symbol = "SWAP_ICON",
				colour = SKIN_RARITY_COLORS["Common"],
				new_indicator = false,
			})

	table.insert(skin_options,  
			{
				text = STRINGS.UI.LOBBYSCREEN.SKINS_RANDOM, 
				data = nil,
				build = "random_skin",
				symbol = "SWAP_ICON",
				colour = SKIN_RARITY_COLORS["Common"],
				new_indicator = false,
			})

	return skin_options

end

function DressupPanel:GetSkinsForGameStart()
	local skins = {}

	if self.currentcharacter == "random" then 
		local all_chars = ExceptionArrays(GetActiveCharacterList(), MODCHARACTEREXCEPTIONS_DST)
		self.currentcharacter = all_chars[math.random(#all_chars)]

		self.currentcharacter_skins = self.profile:GetSkinsForPrefab(self.currentcharacter)

		local previous_skins = self.profile:GetSkinsForCharacter(self.currentcharacter)

		if TUNING.SKINS_BASE_ENABLED then 
			if self.base_spinner and self.base_spinner.spinner:GetSelectedIndex() == 1 then 
				skins.base = previous_skins.base
			else
				skins.base = GetRandomItem(this.currentcharacter_skins)
			end
		else
			skins.base = self.currentcharacter.."_none"
		end

		if self.body_spinner and self.body_spinner.spinner:GetSelectedIndex() == 1 then 
			skins.body = previous_skins.body
		else
			skins.body = GetRandomItem(self.clothing_options["body"])
		end

		if self.hand_spinner and self.hand_spinner.spinner:GetSelectedIndex() == 1 then 
			skins.hand = previous_skins.hand
		else
			skins.hand = GetRandomItem(self.clothing_options["hand"])
		end

		if self.legs_spinner and self.legs_spinner.spinner:GetSelectedIndex() == 1 then 
			skins.legs = previous_skins.legs
		else
			skins.legs = GetRandomItem(self.clothing_options["legs"])
		end

	else
		if self.dressup_frame then 
			local base_skin = self.currentcharacter.."_none"
			if TUNING.SKINS_BASE_ENABLED and self.base_spinner then 
				base_skin = self.base_spinner.GetItem()
			end

			skins = 
			{

				base = base_skin,
				hand = self.hand_spinner.GetItem(),
				legs = self.legs_spinner.GetItem(),
				body = self.body_spinner.GetItem(),
			}
			
		else
			skins = self.profile:GetSkinsForCharacter(self.currentcharacter)
		end

		--cleanup spinner items
		--skins.base doesn't need cleaning up
		if not IsValidClothing( skins.body ) then skins.body = "" end
		if not IsValidClothing( skins.hand ) then skins.hand = "" end
		if not IsValidClothing( skins.legs ) then skins.legs = "" end
		
		self.profile:SetSkinsForCharacter(self.currentcharacter, skins)

	end

	--print("Getting skins")
	--dumptable(skins)
	return skins
end

function DressupPanel:SetPuppetSkins()
	
	if self.currentcharacter == "random" then 
		return
	end

	local base_skin = nil
	if TUNING.SKINS_BASE_ENABLED then 
		local skin_item_name = self.base_spinner.GetItem()
		local skin_prefab = Prefabs[skin_item_name]
		if skin_prefab and skin_prefab.skins then
			base_skin = skin_prefab.skins.normal_skin
		end
	end
	
	local clothing_names = {}

	--print("Body item is ", self.body_spinner.GetItem())
	--print("Gloves item is ", self.gloves_spinner.GetItem())
	--print("Legs item is ", self.legs_spinner.GetItem())
	
	if self.hand_spinner.GetItem() ~= "" then
		table.insert(clothing_names, self.hand_spinner.GetItem())
	end
	if self.legs_spinner.GetItem() ~= "" then
		table.insert(clothing_names, self.legs_spinner.GetItem())
	end
	if self.body_spinner.GetItem() ~= "" then
		table.insert(clothing_names, self.body_spinner.GetItem())
	end
	
	self.puppet:SetSkins(self.currentcharacter, base_skin, clothing_names)
end

function DressupPanel:SetCurrentCharacter(character)

	self.currentcharacter = character

	self.currentcharacter_skins = self.profile:GetSkinsForPrefab(character)

	-- Note: these must be done in this order or the spinners and the puppet will be 
	-- out of sync.
	if self.dressup_frame then 
		self:UpdateSpinners()
		self:UpdatePuppet()
	end
end

function DressupPanel:UpdatePuppet()
	if self.puppet then 
		if self.currentcharacter == "random" then 
			self.puppet:Hide()
			self.random_avatar:Show()
			self.shadow:Hide()
		else
			self.puppet:Show()
			self.puppet:SetCharacter(self.currentcharacter)
			self:SetPuppetSkins()
			self.random_avatar:Hide()
			self.shadow:Show()
		end
	end
end


function DressupPanel:EnableSpinners()

	if self.dressup_frame then 
		if TUNING.SKINS_BASE_ENABLED and self.base_spinner then 
			self.base_spinner:Show()
		end

		if self.body_spinner then 
			self.body_spinner:Show()
		end

		if self.hand_spinner then 
			self.hand_spinner:Show()
		end

		if self.legs_spinner then 
			self.legs_spinner:Show()
		end

		self.dressup_frame:Show()
	end
end


function DressupPanel:DisableSpinners()
	if self.dressup_frame then 
		if TUNING.SKINS_BASE_ENABLED and self.base_spinner then 
			self.base_spinner:Hide()
		end

		if self.body_spinner then 
			self.body_spinner:Hide()
		end

		if self.hand_spinner then 
			self.hand_spinner:Hide()
		end

		if self.legs_spinner then 
			self.legs_spinner:Hide()
		end

		self.dressup_frame:Hide()
	end
end

function DressupPanel:OnClose()
	--print("Setting dressup timestamp from dressuppanel:OnClose", self.timestamp)
	self.profile:SetDressupTimestamp(self.timestamp)
end

return DressupPanel