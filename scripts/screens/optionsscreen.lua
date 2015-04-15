require "util"
require "strings"
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Menu = require "widgets/menu"
local Grid = require "widgets/grid"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local Widget = require "widgets/widget"

local PopupDialogScreen = require "screens/popupdialog"

local OnlineStatus = require "widgets/onlinestatus"


local show_graphics = PLATFORM ~= "NACL"
local text_font = UIFONT--NUMBERFONT

local enableDisableOptions = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.ENABLED, data = true } }
local spinnerFont = { font = BUTTONFONT, size = 30 }

local screen_fade_time = .25

local function GetResolutionString( w, h )
	--return string.format( "%dx%d @ %dHz", w, h, hz )
	return string.format( "%d x %d", w, h )
end

local function SortKey( data )
	local key = data.w * 16777216 + data.h * 65536-- + data.hz
	return key
end

local function ValidResolutionSorter( a, b )
	return SortKey( a.data ) < SortKey( b.data )
end

local function GetDisplays()
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local num_displays = gOpts:GetNumDisplays()
	local displays = {}
	for i = 0, num_displays - 1 do
		table.insert( displays, { text = STRINGS.UI.OPTIONS.DISPLAY.." "..i+1, data = i } )
	end
	
	return displays
end

local function GetRefreshRates( display_id, mode_idx )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	
	local w, h, hz = gOpts:GetDisplayMode( display_id, mode_idx )
	local num_refresh_rates = gOpts:GetNumRefreshRates( display_id, w, h )
	
	local refresh_rates = {}
	for i = 0, num_refresh_rates - 1 do
		local refresh_rate = gOpts:GetRefreshRate( display_id, w, h, i )
		table.insert( refresh_rates, { text = string.format( "%d", refresh_rate ), data = refresh_rate } )
	end
	
	return refresh_rates
end


local function GetDisplayModes( display_id )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local num_modes = gOpts:GetNumDisplayModes( display_id )
	
	local res_data = {}
	for i = 0, num_modes - 1 do
		local w, h, hz = gOpts:GetDisplayMode( display_id, i )
		local res_str = GetResolutionString( w, h )
		res_data[ res_str ] = { w = w, h = h, hz = hz, idx = i }
	end

	local valid_resolutions = {}
	for res_str, data in pairs( res_data ) do
		table.insert( valid_resolutions, { text = res_str, data = data } )
	end

	table.sort( valid_resolutions, ValidResolutionSorter )

	local result = {}
	for k, v in pairs( valid_resolutions ) do
		table.insert( result, { text = v.text, data = v.data } )
	end

	return result
end

local function GetDisplayModeIdx( display_id, w, h, hz )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local num_modes = gOpts:GetNumDisplayModes( display_id )
	
	for i = 0, num_modes - 1 do
		local tw, th, thz = gOpts:GetDisplayMode( display_id, i )
		if tw == w and th == h and thz == hz then
			return i
		end
	end
	
	return nil
end

local function GetDisplayModeInfo( display_id, mode_idx )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local w, h, hz = gOpts:GetDisplayMode( display_id, mode_idx )

	return w, h, hz
end

local OptionsScreen = Class(Screen, function(self, in_game)
	Screen._ctor(self, "OptionsScreen")
	self.in_game = in_game
	--TheFrontEnd:DoFadeIn(2)

	local graphicsOptions = TheFrontEnd:GetGraphicsOptions()

	self.options = {
		fxvolume = TheMixer:GetLevel( "set_sfx" ) * 10,
		musicvolume = TheMixer:GetLevel( "set_music" ) * 10,
		ambientvolume = TheMixer:GetLevel( "set_ambience" ) * 10,
		bloom = graphicsOptions:IsBloomEnabled(),
		smalltextures = graphicsOptions:IsSmallTexturesMode(),
		distortion = graphicsOptions:IsDistortionEnabled(),
		screenshake = Profile:IsScreenShakeEnabled(),
		hudSize = Profile:GetHUDSize(),
		netbookmode = TheSim:IsNetbookMode(),
		vibration = Profile:GetVibrationEnabled(),
		showpassword = Profile:GetShowPasswordEnabled(),
		automods = Profile:GetAutoSubscribeModsEnabled(),
	}

	if IsDLCInstalled(REIGN_OF_GIANTS) then
		self.options.wathgrithrfont = Profile:IsWathgrithrFontEnabled()
	end

	--[[if PLATFORM == "WIN32_STEAM" and not self.in_game then
		self.options.steamcloud = TheSim:GetSetting("STEAM", "DISABLECLOUD") ~= "true"
	end--]]

	if show_graphics then

		self.options.display = graphicsOptions:GetFullscreenDisplayID()
		self.options.refreshrate = graphicsOptions:GetFullscreenDisplayRefreshRate()
		self.options.fullscreen = graphicsOptions:IsFullScreen()
		self.options.mode_idx = graphicsOptions:GetCurrentDisplayModeID( self.options.display )
	end

	self.working = deepcopy( self.options )
	
	
	self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
	TintBackground(self.bg)
    
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.bg:SetScale(1.05,1)
    
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
	local shield = self.root:AddChild( Image( "images/fepanels_dst.xml", "options_panel.tex" ) )
	shield:SetPosition( -50,0,0 )
	shield:SetScale( 1.05, 1 )

	self.fg = self.root:AddChild(Image("images/fg_trees.xml", "trees.tex"))
	self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)

	self.title = self.root:AddChild(Text(BUTTONFONT, 50))
   	self.title:SetPosition(0, 225, 0)
   	self.title:SetColour(0,0,0,1)
   	self.title:SetString(STRINGS.UI.OPTIONS.OPTIONS)
	
	self.onlinestatus = self.root:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)

	self.menu = self.root:AddChild(Menu(nil, -80, false))
	self.menu:SetPosition(30, -220 ,0)
	self.menu:SetScale(.8)

	self.grid = self.root:AddChild(Grid())
	self.grid:SetPosition(-235, 140, 0)
	self:DoInit()
	self:InitializeSpinners()

	self.default_focus = self.grid

end)


function OptionsScreen:OnControl(control, down)
    if OptionsScreen._base.OnControl(self, control, down) then return true end
    
    if not down then
	    if control == CONTROL_CANCEL then
			if self:IsDirty() then
				self:ConfirmRevert() --revert and go back, or stay
			else
				self:Close() --go back
			end
			return true
	    elseif control == CONTROL_ACCEPT and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
	    	if self:IsDirty() then
	    		self:ApplyChanges() --apply changes and go back, or stay
	    	end
	    end
	end
end


function OptionsScreen:ApplyChanges()
	if self:IsDirty() then
		if self:IsGraphicsDirty() then
			self:ConfirmGraphicsChanges()
		else
			self:ConfirmApply()
		end
	end
end

function OptionsScreen:Close()
	--TheFrontEnd:DoFadeIn(2)
	self.menu:Disable()
	if TheFrontEnd:GetFadeLevel() < 1 then
		TheFrontEnd:Fade(false, screen_fade_time, function()
	        TheFrontEnd:PopScreen()
	        TheFrontEnd:Fade(true, screen_fade_time)
	    end)
	else
		TheFrontEnd:PopScreen()
	    TheFrontEnd:Fade(true, screen_fade_time)
	end
end	

function OptionsScreen:ConfirmRevert()

	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.OPTIONS.BACKTITLE, STRINGS.UI.OPTIONS.BACKBODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.OPTIONS.YES, 
		  		cb = function()
					self:RevertChanges()
					TheFrontEnd:Fade(false, screen_fade_time, function()
						TheFrontEnd:PopScreen()
						self:Close()
					end)
				end
			},
			
			{ 
				text = STRINGS.UI.OPTIONS.NO, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		  }
		)
	)		
end

function OptionsScreen:ConfirmApply( )
	
	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.OPTIONS.ACCEPTTITLE, STRINGS.UI.OPTIONS.ACCEPTBODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.OPTIONS.ACCEPT, 
		  		cb = function()
					self:Apply()
					self:Save(function() 
						TheFrontEnd:Fade(false, screen_fade_time, function()
							TheFrontEnd:PopScreen()
							self:Close()
						end)
					end)
				end
			},
			
			{ 
				text = STRINGS.UI.OPTIONS.CANCEL, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		  }
		)
	)	
end

function OptionsScreen:GetHelpText()
	local t = {}
	local controller_id = TheInput:GetControllerID()
	if self:IsDirty() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HELP.APPLY)
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
	else
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
	end
	return table.concat(t, "  ")
end


function OptionsScreen:Accept()
	self:Save(function() self:Close() end )
end

function OptionsScreen:Save(cb)
	self.options = deepcopy( self.working )

	Profile:SetVolume( self.options.ambientvolume, self.options.fxvolume, self.options.musicvolume )
	Profile:SetBloomEnabled( self.options.bloom )
	Profile:SetDistortionEnabled( self.options.distortion )
	Profile:SetScreenShakeEnabled( self.options.screenshake )
	if IsDLCInstalled(REIGN_OF_GIANTS) then Profile:SetWathgrithrFontEnabled( self.options.wathgrithrfont ) end
	Profile:SetHUDSize( self.options.hudSize )
	Profile:SetVibrationEnabled( self.options.vibration )
	Profile:SetShowPasswordEnabled( self.options.showpassword )
	Profile:SetAutoSubscribeModsEnabled( self.options.automods )
	
	Profile:Save( function() if cb then cb() end end)	
end

function OptionsScreen:RevertChanges()
	self.working = deepcopy( self.options )
	self:Apply()
	self:InitializeSpinners()
	self:UpdateMenu()							
end

function OptionsScreen:IsDirty()
	for k,v in pairs(self.working) do
		if v ~= self.options[k] then
			return true	
		end
	end
	return false
end

function OptionsScreen:IsGraphicsDirty()
	return self.working.display ~= self.options.display or
		self.working.mode_idx ~= self.options.mode_idx or
		self.working.fullscreen ~= self.options.fullscreen
end

function OptionsScreen:ChangeGraphicsMode()
	if show_graphics then
		local gOpts = TheFrontEnd:GetGraphicsOptions()
		local w, h, hz = gOpts:GetDisplayMode( self.working.display, self.working.mode_idx )
		local mode_idx = GetDisplayModeIdx( self.working.display, w, h, self.working.refreshrate) or 0
		gOpts:SetDisplayMode( self.working.display, mode_idx, self.working.fullscreen )
	end

end

function OptionsScreen:ConfirmGraphicsChanges(fn)

	if not self.applying then
		self:ChangeGraphicsMode()

		TheFrontEnd:PushScreen(
			PopupDialogScreen( STRINGS.UI.OPTIONS.ACCEPTGRAPHICSTITLE, STRINGS.UI.OPTIONS.ACCEPTGRAPHICSBODY,
			  { { text = STRINGS.UI.OPTIONS.ACCEPT, cb =
					function()

						self:Apply()
						self:Save(
							function() 
								self.applying = false
								self:UpdateMenu()
								TheFrontEnd:PopScreen()
							end)
					end
				},
				{ text = STRINGS.UI.OPTIONS.CANCEL, cb =
					function()
						self.applying = false
						self:RevertChanges()
						self:ChangeGraphicsMode()
						TheFrontEnd:PopScreen()					
					end
				}
			  },
			  { timeout = 10, cb =
				function()
					self.applying = false
					self:RevertChanges()
					self:ChangeGraphicsMode()
					TheFrontEnd:PopScreen()
				end
			  }
			)
		)
	end


end

function OptionsScreen:ApplyVolume()
	TheMixer:SetLevel("set_sfx", self.working.fxvolume / 10 )
	TheMixer:SetLevel("set_music", self.working.musicvolume / 10 )
	TheMixer:SetLevel("set_ambience", self.working.ambientvolume / 10 )
end

function OptionsScreen:Apply( )
	self:ApplyVolume()
	
	TheInputProxy:EnableVibration(self.working.vibration)
	
	local gopts = TheFrontEnd:GetGraphicsOptions()
	gopts:SetBloomEnabled( self.working.bloom )
	gopts:SetDistortionEnabled( self.working.distortion )
	gopts:SetSmallTexturesMode( self.working.smalltextures )
	Profile:SetScreenShakeEnabled( self.working.screenshake )
	if IsDLCInstalled(REIGN_OF_GIANTS) then Profile:SetWathgrithrFontEnabled( self.working.wathgrithrfont ) end
	TheSim:SetNetbookMode(self.working.netbookmode)
end

local function MakeMenu(offset, menuitems)
	local menu = Widget("OptionsMenu")	
	local pos = Vector3(0,0,0)
	for k,v in ipairs(menuitems) do
		local button = menu:AddChild(ImageButton())
	    button:SetPosition(pos)
	    button:SetText(v.text)
	    button.text:SetColour(0,0,0,1)
	    button:SetOnClick( v.cb )
	    button:SetFont(BUTTONFONT)
	    button:SetTextSize(40)    
	    pos = pos + offset  
	end
	return menu
end

function OptionsScreen:CreateSpinnerGroup( text, spinner )
	local label_width = 200
	spinner:SetTextColour(0,0,0,1)
	local group = Widget( "SpinnerGroup" )
	local label = group:AddChild( Text( BUTTONFONT, 30, text ) )
	label:SetPosition( -label_width/2, 0, 0 )
	label:SetRegionSize( label_width, 50 )
	label:SetHAlign( ANCHOR_RIGHT )
	label:SetColour(0,0,0,1)
	
	group:AddChild( spinner )
	spinner:SetPosition( 125, 0, 0 )
	
	--pass focus down to the spinner
	group.focus_forward = spinner
	return group
end


function OptionsScreen:UpdateMenu()
	if TheInput:ControllerAttached() then return end

	if #self.menu.items == 0 then
		self.menu.horizontal = true
		self.back_button = self.menu:AddItem(STRINGS.UI.OPTIONS.BACK, function() 
			if self:IsDirty() then
				self:ConfirmRevert() --revert and go back, or stay
			else
				self:Close() --go back
			end
		end, Vector3(-300, -70, 0))
		self.apply_button = self.menu:AddItem(STRINGS.UI.OPTIONS.APPLY, function() self:ApplyChanges() end, Vector3(300, -72, 0), "large")
	end

	if self:IsDirty() then
		self.apply_button:Enable()
	else
		self.apply_button:Disable()
	end
end


function OptionsScreen:DoInit()

	self:UpdateMenu()
	--self.menu:SetScale(.8,.8,.8)

	local this = self
	
	if show_graphics then
		local gOpts = TheFrontEnd:GetGraphicsOptions()
	
		self.fullscreenSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
		
		self.fullscreenSpinner.OnChanged =
			function( _, data )
				this.working.fullscreen = data
				this:UpdateResolutionsSpinner()
				self:UpdateMenu()				
			end
		
		if gOpts:IsFullScreenEnabled() then
			self.fullscreenSpinner:Enable()
		else
			self.fullscreenSpinner:Disable()
		end

		local valid_displays = GetDisplays()
		self.displaySpinner = Spinner( valid_displays, nil, nil, nil, nil, nil, nil, true )
		self.displaySpinner.OnChanged =
			function( _, data )
				this.working.display = data
				this:UpdateResolutionsSpinner()
				this:UpdateRefreshRatesSpinner()
				self:UpdateMenu()
			end
		
		local refresh_rates = GetRefreshRates( self.working.display, self.working.mode_idx )
		self.refreshRateSpinner = Spinner( refresh_rates, nil, nil, nil, nil, nil, nil, true ) 
		self.refreshRateSpinner.OnChanged =
			function( _, data )
				this.working.refreshrate = data
				self:UpdateMenu()
			end

		local modes = GetDisplayModes( self.working.display )
		self.resolutionSpinner = Spinner( modes, nil, nil, nil, nil, nil, nil, true )
		self.resolutionSpinner.OnChanged =
			function( _, data )
				this.working.mode_idx = data.idx
				this:UpdateRefreshRatesSpinner()
				self:UpdateMenu()
			end			
			
		self.netbookModeSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
		self.netbookModeSpinner.OnChanged =
			function( _, data )
				this.working.netbookmode = data
				--this:Apply()
				self:UpdateMenu()
			end
			
		self.smallTexturesSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
		self.smallTexturesSpinner.OnChanged =
			function( _, data )
				this.working.smalltextures = data
				--this:Apply()
				self:UpdateMenu()
			end
						
	end
	

	self.bloomSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
	self.bloomSpinner.OnChanged =
		function( _, data )
			this.working.bloom = data
			--this:Apply()
			self:UpdateMenu()
		end
		
	self.distortionSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
	self.distortionSpinner.OnChanged =
		function( _, data )
			this.working.distortion = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.screenshakeSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
	self.screenshakeSpinner.OnChanged =
		function( _, data )
			this.working.screenshake = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.fxVolume = NumericSpinner( 0, 10, nil, nil, nil, nil, nil, nil, true )
	self.fxVolume.OnChanged =
		function( _, data )
			this.working.fxvolume = data
			this:ApplyVolume()
			self:UpdateMenu()
		end

	self.musicVolume = NumericSpinner( 0, 10, nil, nil, nil, nil, nil, nil, true )
	self.musicVolume.OnChanged =
		function( _, data )
			this.working.musicvolume = data
			this:ApplyVolume()
			self:UpdateMenu()
		end

	self.ambientVolume = NumericSpinner( 0, 10, nil, nil, nil, nil, nil, nil, true )
	self.ambientVolume.OnChanged =
		function( _, data )
			this.working.ambientvolume = data
			this:ApplyVolume()
			self:UpdateMenu()
		end
		
	self.hudSize = NumericSpinner( 0, 10, nil, nil, nil, nil, nil, nil, true )
	self.hudSize.OnChanged =
		function( _, data )
			this.working.hudSize = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.vibrationSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
	self.vibrationSpinner.OnChanged =
		function( _, data )
			this.working.vibration = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.passwordSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
	self.passwordSpinner.OnChanged =
		function( _, data )
			this.working.showpassword = data
			--this:Apply()
			self:UpdateMenu()
		end

	if IsDLCInstalled(REIGN_OF_GIANTS) then
		self.wathgrithrfontSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
		self.wathgrithrfontSpinner.OnChanged =
			function( _, data )
				this.working.wathgrithrfont = data
				--this:Apply()
				self:UpdateMenu()
			end
	end
	
	self.automodsSpinner = Spinner( enableDisableOptions, nil, nil, nil, nil, nil, nil, true )
	self.automodsSpinner.OnChanged =
		function( _, data )
			this.working.automods = data
			--this:Apply()
			self:UpdateMenu()
		end
		
	local left_spinners = {}
	local right_spinners = {}
	
	if show_graphics then
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.BLOOM, self.bloomSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.DISTORTION, self.distortionSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.SCREENSHAKE, self.screenshakeSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.FULLSCREEN, self.fullscreenSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.DISPLAY, self.displaySpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.RESOLUTION, self.resolutionSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.REFRESHRATE, self.refreshRateSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.SMALLTEXTURES, self.smallTexturesSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.NETBOOKMODE, self.netbookModeSpinner} )
		
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.FX, self.fxVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.MUSIC, self.musicVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.AMBIENT, self.ambientVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.HUDSIZE, self.hudSize} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.VIBRATION, self.vibrationSpinner} )
		if IsDLCInstalled(REIGN_OF_GIANTS) then
			table.insert( right_spinners, { STRINGS.UI.OPTIONS.WATHGRITHRFONT, self.wathgrithrfontSpinner} )
		end
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.SHOWPASSWORD, self.passwordSpinner} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.AUTOMODS, self.automodsSpinner } )
	else
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.BLOOM, self.bloomSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.DISTORTION, self.distortionSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.SCREENSHAKE, self.screenshakeSpinner } )

		table.insert( right_spinners, { STRINGS.UI.OPTIONS.FX, self.fxVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.MUSIC, self.musicVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.AMBIENT, self.ambientVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.HUDSIZE, self.hudSize} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.VIBRATION, self.vibrationSpinner} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.SHOWPASSWORD, self.passwordSpinner} )
		if IsDLCInstalled(REIGN_OF_GIANTS) then
			table.insert( right_spinners, { STRINGS.UI.OPTIONS.WATHGRITHRFONT, self.wathgrithrfontSpinner} )
		end
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.AUTOMODS, self.automodsSpinner } )
	end


	--self.grid:InitSize(2, 7, 400, -70)
	self.grid:InitSize(2, 9, 370, -43)

	for k,v in ipairs(left_spinners) do
		self.grid:AddItem(self:CreateSpinnerGroup(v[1], v[2]), 1, k)	
	end

	for k,v in ipairs(right_spinners) do
		self.grid:AddItem(self:CreateSpinnerGroup(v[1], v[2]), 2, k)	
	end

end

local function EnabledOptionsIndex( enabled )
	if enabled then
		return 2
	else
		return 1
	end
end

function OptionsScreen:InitializeSpinners()
	if show_graphics then
		self.fullscreenSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.fullscreen ) )
		self:UpdateDisplaySpinner()
		self:UpdateResolutionsSpinner()
		self:UpdateRefreshRatesSpinner()
		self.smallTexturesSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.smalltextures ) )
		self.netbookModeSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.netbookmode ) )
	end

	--[[if PLATFORM == "WIN32_STEAM" and not self.in_game then
		self.steamcloudSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.steamcloud ) )
	end
	--]]
	
	self.bloomSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.bloom ) )
	self.distortionSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.distortion ) )
	self.screenshakeSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.screenshake ) )

	local spinners = { fxvolume = self.fxVolume, musicvolume = self.musicVolume, ambientvolume = self.ambientVolume }
	for key, spinner in pairs( spinners ) do
		local volume = self.working[ key ] or 7
		spinner:SetSelectedIndex( math.floor( volume + 0.5 ) )
	end
	
	self.hudSize:SetSelectedIndex( self.working.hudSize or 5)
	self.vibrationSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.vibration ) )
	self.passwordSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.showpassword ) )
	if IsDLCInstalled(REIGN_OF_GIANTS) then self.wathgrithrfontSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.wathgrithrfont ) ) end
	
	self.automodsSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.automods ) )
end

function OptionsScreen:UpdateDisplaySpinner()
	if show_graphics then
		local graphicsOptions = TheFrontEnd:GetGraphicsOptions()
		local display_id = graphicsOptions:GetFullscreenDisplayID() + 1
		self.displaySpinner:SetSelectedIndex( display_id )
	end
end

function OptionsScreen:UpdateRefreshRatesSpinner()
	if show_graphics then
		local current_refresh_rate = self.working.refreshrate
		
		local refresh_rates = GetRefreshRates( self.working.display, self.working.mode_idx )
		self.refreshRateSpinner:SetOptions( refresh_rates )
		self.refreshRateSpinner:SetSelectedIndex( 1 )
		
		for idx, refresh_rate_data in ipairs( refresh_rates ) do
			if refresh_rate_data.data == current_refresh_rate then
				self.refreshRateSpinner:SetSelectedIndex( idx )
				break
			end
		end
		
		self.working.refreshrate = self.refreshRateSpinner:GetSelected().data		
	end
end

function OptionsScreen:UpdateResolutionsSpinner()
	if show_graphics then
		local resolutions = GetDisplayModes( self.working.display )
		self.resolutionSpinner:SetOptions( resolutions )
	
		if self.fullscreenSpinner:GetSelected().data then
			self.displaySpinner:Enable()
			self.refreshRateSpinner:Enable()
			self.resolutionSpinner:Enable()

			local spinner_idx = 1
			if self.working.mode_idx then
				local gOpts = TheFrontEnd:GetGraphicsOptions()
				local mode_idx = gOpts:GetCurrentDisplayModeID( self.options.display )
				local w, h, hz = GetDisplayModeInfo( self.working.display, mode_idx )
				
				for idx, option in pairs( self.resolutionSpinner.options ) do
					if option.data.w == w and option.data.h == h then
						spinner_idx = idx
						break
					end
				end
			end
			self.resolutionSpinner:SetSelectedIndex( spinner_idx )
		else
			self.displaySpinner:Disable()
			self.refreshRateSpinner:Disable()
			self.resolutionSpinner:Disable()
		end
	end
end

return OptionsScreen