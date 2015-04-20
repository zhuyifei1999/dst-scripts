--------------------------------------------------------------------------
--[[ DSP class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim

local _itemlist = {}
local _itemindex = 1

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- for debug
local function GetOldestUpdate()
	local oldestUpdate = math.huge
	for k,v in pairs(_itemlist) do
		if v.components.moisturelistener and v.components.moisturelistener.lastUpdate < oldestUpdate then
			oldestUpdate = v.components.moisturelistener.lastUpdate
		end
	end
	return oldestUpdate
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnTrackInventoryItem(src, item)
	-- Make sure item can actually get wet
	if not (item and item.components.waterproofer) then
		table.insert(_itemlist, item)
		item.components.moisturelistener:UpdateMoisture(GetTime())
	elseif item and item.components.moisturelistener and item.components.waterproofer then
		-- Somehow we ended up with an item that has moisturelistener AND waterproofer: remove moisturelistener (waterproof items can't get wet)
		item:RemoveComponent("moisturelistener")
	end
end

local function OnForgetInventoryItem(src, item)
	local toRemove = nil
	for k,v in pairs(_itemlist) do
		if v == item then
			toRemove = k
		end
	end
	if toRemove then
		table.remove(_itemlist, toRemove)
	end

	_itemindex = _itemindex - 1
	_itemindex = math.clamp(_itemindex, 1, #_itemlist)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

inst:ListenForEvent("trackinventoryitem", OnTrackInventoryItem, _world)
inst:ListenForEvent("forgetinventoryitem", OnForgetInventoryItem, _world)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
	if #_itemlist <= 0 then return end

	local numToUpdate = #_itemlist * 0.01
	numToUpdate = math.ceil(numToUpdate)
	numToUpdate = math.clamp(numToUpdate, 1, 50)

	local endNum = numToUpdate + _itemindex
	endNum = (endNum > #_itemlist) and #_itemlist or endNum
	for i = _itemindex, endNum do
		local item = _itemlist[i]
		if item and item.components.moisturelistener then
			item.components.moisturelistener:UpdateMoisture(GetTime() - item.components.moisturelistener.lastUpdate)
		end
	end
	_itemindex = endNum + 1
	if _itemindex >= #_itemlist then
		_itemindex = 1
	end
end
inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	local str = ""

	str = str..string.format("Total Items: %d, OldestUpdate age: %2.2f, _itemindex: %d", 
		#_itemlist,
		GetTime() - GetOldestUpdate(),
		_itemindex)
	return str
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
