local UIAnim = require("widgets/uianim")

--------------------------------------------------------------------------

local FLAGBITS =
{
	BIG = 0,
	SPRINT_DRAIN = 1, --V2C: is sprint hunger drain multiplier active; NOT just "is sprinting". (skills can let you sprint without the drain multiplier.)
	ENDURANCE = 2,
	LUNAR = 3,
	SHADOW = 4,
}

local SMALL_SYMBOLS =
{
	"body",
	"body_overlay",
	"chew",
	"eye",
	"face",
	"foot",
	"mouth",
	"tail",
	"tongue",
}

local BIG_SYMBOLS =
{
	"beefalo_body",
	"beefalo_facebase",
	"beefalo_headbase",
	"beefalo_hoof",
	"beefalo_jowls",
	"beefalo_mouthmouth",
	"beefalo_nose",
	"beefalo_tail",
	"beffalo_lips",
	"woby_fur_slider",
}

--------------------------------------------------------------------------

local COMMAND_NAMES =
{
	"PET",
	"MOUNT",
	"SHRINK",
	"SIT",
	"PICKUP",
	"FORAGING",
	"WORKING",
	"SPRINTING",
	"SHADOWDASH",
}
local COMMANDS = table.invert(COMMAND_NAMES)

--------------------------------------------------------------------------

local ICON_SCALE = 0.6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS-- + 2

local function MakeWobyCommand(cmd)
	return function(inst)
		if not (ThePlayer.woby_commands_classified and ThePlayer.woby_commands_classified:ExecuteCommand(cmd)) then
			TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative")
		end
	end
end

local function MakeAutocastToggle(name)
	return function(w)
		w.ring = w:AddChild(UIAnim())
		w.ring:GetAnimState():SetBank("spell_icons_woby")
		w.ring:GetAnimState():SetBuild("spell_icons_woby")
		w.ring:GetAnimState():PlayAnimation("autocast_ring", true)
		w.ring.OnUpdate = function(ring, dt)
			if ThePlayer and ThePlayer.woby_commands_classified and ThePlayer.woby_commands_classified:GetValue(name) then
				local anim =
					(w.animstate:IsCurrentAnimation(name.."_focus") and "autocast_ring_focus") or
					(w.animstate:IsCurrentAnimation(name.."_pressed") and "autocast_ring_pressed") or
					"autocast_ring"
				if not ring:GetAnimState():IsCurrentAnimation(anim) then
					local frame = ring:GetAnimState():GetCurrentAnimationFrame()
					ring:GetAnimState():PlayAnimation(anim, true)
					ring:GetAnimState():SetFrame(frame)
				end
				ring:Show()
			else
				ring:Hide()
			end
		end
		w.OnShow = function(w)
			w.ring:StartUpdating()
		end
		w.OnHide = function(w)
			w.ring:StopUpdating()
		end
		if w.shown then
			w.ring:StartUpdating()
			w.ring:OnUpdate(0)
		end
	end
end

local COMMAND_DEFS =
{
	PET =
	{
		label = STRINGS.ACTIONS.PET,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ACTIONS.PET)
			inst.components.spellbook.closeonexecute = true
		end,
		execute = MakeWobyCommand(COMMANDS.PET),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "pet" },
			focus = { anim = "pet_focus" },
			down = { anim = "pet_pressed" },
		},
		widget_scale = ICON_SCALE,
	},

	MOUNT =
	{
		label = STRINGS.ACTIONS.MOUNT,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ACTIONS.MOUNT)
			inst.components.spellbook.closeonexecute = true
		end,
		execute = MakeWobyCommand(COMMANDS.MOUNT),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "mount" },
			focus = { anim = "mount_focus" },
			down = { anim = "mount_pressed" },
		},
		widget_scale = ICON_SCALE,
	},

	SHRINK =
	{
		label = STRINGS.WOBY_COMMANDS.SHRINK,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.SHRINK)
			inst.components.spellbook.closeonexecute = true
		end,
		execute = MakeWobyCommand(COMMANDS.SHRINK),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "forcetransform" },
			focus = { anim = "forcetransform_focus" },
			down = { anim = "forcetransform_pressed" },
		},
		widget_scale = ICON_SCALE,
	},

	SIT =
	{
		label = STRINGS.WOBY_COMMANDS.SIT,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.SIT)
			inst.components.spellbook.closeonexecute = false
		end,
		execute = MakeWobyCommand(COMMANDS.SIT),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "sit" },
			focus = { anim = "sit_focus" },
			down = { anim = "sit_pressed" },
		},
		widget_scale = ICON_SCALE,
		postinit = MakeAutocastToggle("sit"),
	},

	PICKUP =
	{
		label = STRINGS.WOBY_COMMANDS.PICKUP,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.PICKUP)
			inst.components.spellbook.closeonexecute = false
		end,
		execute = MakeWobyCommand(COMMANDS.PICKUP),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "pickup" },
			focus = { anim = "pickup_focus" },
			down = { anim = "pickup_pressed" },
		},
		widget_scale = ICON_SCALE,
		postinit = MakeAutocastToggle("pickup"),
		skill = "walter_woby_itemfetcher",
	},

	FORAGING =
	{
		label = STRINGS.WOBY_COMMANDS.FORAGING,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.FORAGING)
			inst.components.spellbook.closeonexecute = false
		end,
		execute = MakeWobyCommand(COMMANDS.FORAGING),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "foraging" },
			focus = { anim = "foraging_focus" },
			down = { anim = "foraging_pressed" },
		},
		widget_scale = ICON_SCALE,
		postinit = MakeAutocastToggle("foraging"),
		skill = "walter_woby_foraging",
	},

	WORKING =
	{
		label = STRINGS.WOBY_COMMANDS.WORKING,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.WOBY_COMMANDS.WORKING)
			inst.components.spellbook.closeonexecute = false
		end,
		execute = MakeWobyCommand(COMMANDS.WORKING),
		bank = "spell_icons_woby",
		build = "spell_icons_woby",
		anims =
		{
			idle = { anim = "working" },
			focus = { anim = "working_focus" },
			down = { anim = "working_pressed" },
		},
		widget_scale = ICON_SCALE,
		postinit = MakeAutocastToggle("working"),
		skill = "walter_woby_taskaid",
	},
}

local BIG_SPELLS =
{
	COMMAND_DEFS.MOUNT,
	COMMAND_DEFS.SHRINK,
	COMMAND_DEFS.SIT,
	COMMAND_DEFS.PICKUP,
	COMMAND_DEFS.FORAGING,
	COMMAND_DEFS.WORKING,
}

local SMALL_SPELLS =
{
	COMMAND_DEFS.PET,
	COMMAND_DEFS.SIT,
	COMMAND_DEFS.PICKUP,
	COMMAND_DEFS.FORAGING,
	COMMAND_DEFS.WORKING,
}

local function CanUseWobyCommands(inst, user)
	if user.woby_commands_classified and
		user.woby_commands_classified:GetWoby() == inst and
		not inst:HasTag("transforming")
	then
		if user.HUD then
			local range = user.HUD:GetCurrentOpenSpellBook() == inst and 18 or 15
			return user:IsNear(inst, range)
		end
		return true
	end
	return false
end

local function ShouldOpenWobyCommands(inst, user)
	return user.woby_commands_classified ~= nil and not user.woby_commands_classified:IsBusy()
end

local function OnOpenSpellBook(inst)
	TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, math.huge, math.huge, 10)
end

local function OnCloseSpellBook(inst)
	TheFocalPoint.components.focalpoint:StopFocusSource(inst)
end

local function RefreshCommands(inst, player)
	local skilltreeupdater = player and player.components.skilltreeupdater or nil
	local j = 1
	for i, v in ipairs(inst:HasTag("largecreature") and BIG_SPELLS or SMALL_SPELLS) do
		if v.skill == nil or (skilltreeupdater and skilltreeupdater:IsActivated(v.skill)) then
			inst._spells[j] = v
			j = j + 1
		end
	end
	for i = j, #inst._spells do
		inst._spells[i] = nil
	end
end

local function SetupClientCommandWheelRefreshers(inst, player)
	if inst._onskillrefreh_wobycommon == nil then
		inst._onskillrefreh_wobycommon = function(player) RefreshCommands(inst, player) end
		inst:ListenForEvent("onactivateskill_client", inst._onskillrefreh_wobycommon, player)
		inst:ListenForEvent("ondeactivateskill_client", inst._onskillrefreh_wobycommon, player)
		if player._PostActivateHandshakeState_Client == POSTACTIVATEHANDSHAKE.READY then
			RefreshCommands(inst, player)
		elseif inst._onskilltreeinitialized_wobycommon == nil then
			inst._onskilltreeinitialized_wobycommon = function(player)
				inst:RemoveEventCallback("skilltreeinitialized_client", inst._onskilltreeinitialized_wobycommon, player)
				inst._onskilltreeinitialized_wobycommon = nil
				RefreshCommands(inst, player)
			end
			inst:ListenForEvent("skilltreeinitialized_client", inst._onskilltreeinitialized_wobycommon, player)
		end
	end
end

local function DelayedSetupClientCommandWheelRefreshers(inst)
	local player = ThePlayer
	if player and player.woby_commands_classified and player.woby_commands_classified:GetWoby() == inst then
		SetupClientCommandWheelRefreshers(inst, player)
	end
end

local function SetupCommandWheel(inst)
	inst._spells = {}

	--V2C: inst.prefab is not available yet
	local sfxpath =
		inst:HasTag("largecreature") and
		"meta5/woby/bigwoby_actionwheel_UI" or
		"meta5/woby/smallwoby_actionwheel_UI"

	inst:AddComponent("spellbook")
	inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)
	inst.components.spellbook:SetCanUseFn(CanUseWobyCommands)
	inst.components.spellbook:SetShouldOpenFn(ShouldOpenWobyCommands)
	inst.components.spellbook:SetOnOpenFn(OnOpenSpellBook)
	inst.components.spellbook:SetOnCloseFn(OnCloseSpellBook)
	inst.components.spellbook:SetItems(inst._spells)
	inst.components.spellbook.opensound = sfxpath
	inst.components.spellbook.closesound = sfxpath
	--inst.components.spellbook.executesound = "meta4/winona_UI/select"	--use .clicksound for item buttons instead
	--inst.components.spellbook.focussound = "meta4/winona_UI/hover"

	if not TheWorld.ismastersim then
		--Delayed because woby prefab will call this during construction, which means
		--woby_commands_classified:GetWoby() won't be able to return it properly yet.
		inst:DoStaticTaskInTime(0, DelayedSetupClientCommandWheelRefreshers)
	end
end

--------------------------------------------------------------------------

return
{
	FLAGBITS = FLAGBITS,
	SMALL_SYMBOLS = SMALL_SYMBOLS,
	BIG_SYMBOLS = BIG_SYMBOLS,
	COMMAND_NAMES = COMMAND_NAMES,
	COMMANDS = COMMANDS,
	SetupCommandWheel = SetupCommandWheel,
	SetupClientCommandWheelRefreshers = SetupClientCommandWheelRefreshers,
	RefreshCommands = RefreshCommands,
	MakeWobyCommand = MakeWobyCommand,
	MakeAutocastToggle = MakeAutocastToggle,
}
