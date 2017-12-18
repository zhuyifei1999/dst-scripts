local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Image = require "widgets/image"
local TextEditLinked = require "widgets/texteditlinked"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local ThankYouPopup = require "screens/thankyoupopup"

local NUM_CODE_GROUPS = 5
local DIGITS_PER_GROUP = 4

local RedeemDialog = Class(Screen, function(self)
	Screen._ctor(self, "RedeemDialog")

    local buttons =
    {
        {text=STRINGS.UI.REDEEMDIALOG.SUBMIT, cb = function() self:DoSubmitCode() end },
        {text=STRINGS.UI.REDEEMDIALOG.CANCEL, cb = function() self:Close() end }  
    }

    self.root = self:AddChild(TEMPLATES.ScreenRoot())
    self.black = self.root:AddChild(TEMPLATES.BackgroundTint())
	self.dialog = self.root:AddChild(TEMPLATES.CurlyWindow(480, 220, STRINGS.UI.REDEEMDIALOG.TITLE, buttons, nil, ""))

    self.proot = self.root:AddChild(Widget("proot"))
    self.proot:SetPosition(0, 50)

    self.title = self.dialog.title

    self:MakeTextEntryBox(self.proot)

	-- server response text
    self.text = self.dialog.body
    self.text:SetPosition(0, 60)
    self.text:SetVAlign(ANCHOR_TOP)
    self.text:SetHAlign(ANCHOR_MIDDLE)
    self.text:Hide()

    self.fineprint = self.proot:AddChild(Text(CHATFONT, 17))
    self.fineprint:SetString(STRINGS.UI.REDEEMDIALOG.LEGALESE)
    self.fineprint:SetPosition(0, -75)
    self.fineprint:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
    self.fineprint:EnableWordWrap(true)
    self.fineprint:SetRegionSize(520, 160)
    self.fineprint:SetVAlign(ANCHOR_MIDDLE)

	self.redeem_in_progress = false

	self.buttons = buttons
    self.submit_btn = self.dialog.actions.items[1]
    self.submit_btn:Select()

    local function SequenceFocusVertical(up, down)
        up:SetFocusChangeDir(MOVE_DOWN, down)
        down:SetFocusChangeDir(MOVE_UP, up)
    end
    SequenceFocusVertical(self.entrybox, self.dialog.actions)

	self.default_focus = self.dialog    
end)

function RedeemDialog:OnBecomeActive()
    self._base.OnBecomeActive(self)
    self.entrybox.textboxes[1]:SetFocus()
    self.entrybox.textboxes[1]:SetEditing(true)
end

-- Codes are 5 groups of 4 characters (letters and numbers) separated by hyphens
-- i and o are not allowed
local VALID_CHARS = [[abcdefghjklmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ1234567890]]

function RedeemDialog:MakeTextEntryBox(parent)
    local entrybox = parent:AddChild(Widget("entrybox"))
    local box_size = 75
    local box_y = 40

   	entrybox.bgs = {}
    entrybox.textboxes = {}

    for i = 1, NUM_CODE_GROUPS do
		entrybox.textboxes[i] = parent:AddChild(TextEditLinked( CODEFONT, 32, nil, UICOLOURS.BLACK ) )
		entrybox.textboxes[i]:SetForceEdit(true)
		entrybox.textboxes[i]:SetRegionSize( box_size, box_y )
		entrybox.textboxes[i]:SetHAlign(ANCHOR_LEFT)
		entrybox.textboxes[i]:SetVAlign(ANCHOR_MIDDLE)
		entrybox.textboxes[i]:SetTextLengthLimit(DIGITS_PER_GROUP)
		entrybox.textboxes[i]:SetCharacterFilter( VALID_CHARS )
		entrybox.textboxes[i]:SetTextConversion( "i", "1" )
		entrybox.textboxes[i]:SetTextConversion( "I", "1" )
		entrybox.textboxes[i]:SetTextConversion( "o", "0" )
		entrybox.textboxes[i]:SetTextConversion( "O", "0" )
		entrybox.textboxes[i]:EnableWordWrap(false)
		entrybox.textboxes[i]:EnableScrollEditWindow(false)
		entrybox.textboxes[i]:SetForceUpperCase(true)
		entrybox.textboxes[i]:SetPosition(i*95 - (NUM_CODE_GROUPS/2+0.5)*95, 2, 0)

		entrybox.textboxes[i].bg = entrybox.textboxes[i]:AddChild( Image("images/global_redux.xml", "textbox3_gold_tiny_normal.tex") )
		entrybox.textboxes[i].bg:ScaleToSize( box_size + 23, box_y + 10 )
		entrybox.textboxes[i].bg:SetPosition(-1, 2)
		entrybox.textboxes[i].bg:MoveToBack()

		entrybox.textboxes[i]:SetFocusedImage( entrybox.textboxes[i].bg, "images/global_redux.xml", "textbox3_gold_tiny_normal.tex", "textbox3_gold_tiny_hover.tex", "textbox3_gold_tiny_focus.tex" )

		entrybox.textboxes[i].OnTextInputted = function()
			for i = 1, NUM_CODE_GROUPS do
				if string.len(entrybox.textboxes[i]:GetString()) ~= entrybox.textboxes[i].limit then
					-- if any box is full, we're not ready yet
					self.submit_btn:Select()
					return
				end
			end
			self.submit_btn:Unselect()
		end

		entrybox.textboxes[i].OnTextEntered = function()
			if not self.redeem_in_progress then
				local redeem_code = ""
				for i = 1, NUM_CODE_GROUPS do
					if i ~= 1 then
						redeem_code	= redeem_code .. "-"
					end
					redeem_code	= redeem_code .. entrybox.textboxes[i]:GetString() 
				end

				if string.len(redeem_code) == NUM_CODE_GROUPS * DIGITS_PER_GROUP + (NUM_CODE_GROUPS-1) then --(NUM_CODE_GROUPS-1) is for dashes
					self.text:SetString("")
					self.submit_btn:Select()
					self.redeem_in_progress = true
					TheItems:RedeemCode(redeem_code, function(success, status, item_type, category, message)
						self:DisplayResult(success, status, item_type, category, message)
					end)
				end
			end
		end

		entrybox.textboxes[i].OnLargePaste = function()
			local clipboard = TheSim:GetClipboardData()

			--clear invalid characters
			local res = ""
			for i=1,#clipboard do
				local char = clipboard:sub(i,i)
				if string.find(VALID_CHARS, char, 1, true) then
					res = res .. char
				end
			end
			clipboard = res

			local i = 1
			while #clipboard > 0 and i <= NUM_CODE_GROUPS do
				local seg = clipboard:sub(1,DIGITS_PER_GROUP)
				clipboard = clipboard:sub(DIGITS_PER_GROUP+1)
				entrybox.textboxes[i]:SetString(seg)
				entrybox.textboxes[i]:SetEditing(true)
				i = i + 1
			end

			return true
		end

		if i > 1 then
			entrybox.textboxes[i-1]:SetNextTextEdit(entrybox.textboxes[i])
			entrybox.textboxes[i]:SetLastTextEdit(entrybox.textboxes[i-1])
		end
   	end

    self.entrybox = entrybox
end

function RedeemDialog:DisplayResult(success, status, item_type, category, message) 
	-- Possible responses when attempting to query server:
	--success=true, status="ACCEPTED"
	--success=false, status="INVALID_CODE"
	--success=false, status="ALREADY_REDEEMED"
	--success=false, status="FAILED_TO_CONTACT"	

    self.submit_btn:Unselect()
    self.redeem_in_progress = false

	--DO WE DEAL WITH item_type = FROMNUM???
	print( "RedeemDialog:DisplayResult", success, status, item_type, category, message )
	if success then
		local items = {} -- early access thank you gifts
		table.insert(items, {item=item_type, item_id=0, gifttype=category, message=message})

		for i = 1, NUM_CODE_GROUPS do
			self.entrybox.textboxes[i]:SetString("")
		end

		self.title:Show()
		self.text:Hide()

        local thankyou_popup = ThankYouPopup(items)
        TheFrontEnd:PushScreen(thankyou_popup)
	else
		self.title:Hide()

		self.text:SetString(STRINGS.UI.REDEEMDIALOG[status] or STRINGS.UI.REDEEMDIALOG["FAILED_TO_CONTACT"])
		self.text:Show()
	end
end

function RedeemDialog:OnRawKey(key, down)
    if RedeemDialog._base.OnRawKey(self, key, down) then return true end

	if down and TheInput:IsPasteKey(key) then
		local clipboard = TheSim:GetClipboardData()
		if #clipboard > DIGITS_PER_GROUP then
			self.entrybox.textboxes[1]:OnLargePaste()
			return true
		else
			for i = 1, NUM_CODE_GROUPS do
				if #self.entrybox.textboxes[i]:GetString() < DIGITS_PER_GROUP then
					self.entrybox.textboxes[i]:SetEditing(true)
					self.entrybox.textboxes[i]:OnRawKey(key, down)
					return true
				end
			end
		end
	end
	return false
end

function RedeemDialog:OnControl(control, down)
    if RedeemDialog._base.OnControl(self,control, down) then return true end

    if control == CONTROL_CANCEL and not down then    
        if #self.buttons > 1 and self.buttons[#self.buttons] then
            self.buttons[#self.buttons].cb()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            return true
        end
    end
end

function RedeemDialog:DoSubmitCode()	
	self.entrybox.textboxes[1]:OnTextEntered()
end

function RedeemDialog:Close()
	TheFrontEnd:PopScreen(self)
end

function RedeemDialog:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)	
    end
	return table.concat(t, "  ")
end

return RedeemDialog
