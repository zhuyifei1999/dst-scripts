
local HALLOWEDNIGHTS_START = 32
local HALLOWEDNIGHTS_END = 37

function PickRandomTrinket()
    local chessunlocks = TheWorld.components.chessunlocks

	local has_locked_chess = chessunlocks ~= nil and (chessunlocks:GetNumLockedTrinkets() > 0)
	local is_hallowednights = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS)

	local unlocked_trinkets = {}
	for i = 1,NUM_TRINKETS do
		if (not has_locked_chess or not chessunlocks:IsLocked("trinket_"..i))
			and (is_hallowednights or not(i >= HALLOWEDNIGHTS_START and i <= HALLOWEDNIGHTS_END)) then

			table.insert(unlocked_trinkets, i)
		end
    end

    return "trinket_"..unlocked_trinkets[math.random(#unlocked_trinkets)]
end

local assets =
{
    Asset("ANIM", "anim/trinkets.zip"),
}

local TRADEFOR =
{
    [15] = {"chesspiece_bishop_sketch"},
    [16] = {"chesspiece_bishop_sketch"},
    [28] = {"chesspiece_rook_sketch"},
    [29] = {"chesspiece_rook_sketch"},
    [30] = {"chesspiece_knight_sketch"},
    [31] = {"chesspiece_knight_sketch"},
}

local function MakeTrinket(num)
    local prefabs = TRADEFOR[num]

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("trinkets")
        inst.AnimState:SetBuild("trinkets")
        inst.AnimState:PlayAnimation(tostring(num))

        inst:AddTag("molebait")
        inst:AddTag("cattoy")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inventoryitem")
        inst:AddComponent("tradable")
        inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.TRINKETS[num] or 3
        inst.components.tradable.tradefor = TRADEFOR[num]
        
        if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
			if num >= HALLOWEDNIGHTS_START and num <= HALLOWEDNIGHTS_END then
				inst.components.tradable.halloweencandyvalue = 5
			end
		else
			inst:AddComponent("fuel")
			inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL
		end

        MakeHauntableLaunchAndSmash(inst)

        inst:AddComponent("bait")

        return inst
    end

    return Prefab("trinket_"..tostring(num), fn, assets, prefabs)
end

local ret = {}
for k = 1, NUM_TRINKETS do
    table.insert(ret, MakeTrinket(k))
end

return unpack(ret)
