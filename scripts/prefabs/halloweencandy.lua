local assets =
{
    Asset("ANIM", "anim/halloweencandy.zip"),
}

local candyinfo =
{
	{food=FOODTYPE.GOODIES, health=1, hunger=1, sanity=1}, -- Candy Apple
	{food=FOODTYPE.GOODIES, health=1, hunger=0, sanity=2}, -- Candy Corn
	{food=FOODTYPE.VEGGIE,  health=1, hunger=2, sanity=0}, -- Not-So-Candy Corn
	{food=FOODTYPE.GOODIES, health=2, hunger=0, sanity=1}, -- Gummy Spider
	{food=FOODTYPE.GOODIES, health=1, hunger=0, sanity=2}, -- Catcoon Candy
	{food=FOODTYPE.VEGGIE,  health=2, hunger=1, sanity=0}, -- "Raisins"
	{food=FOODTYPE.VEGGIE,  health=2, hunger=0, sanity=1}, -- Raisins
	{food=FOODTYPE.GOODIES, health=1, hunger=0, sanity=2}, -- Ghost Pop
	{food=FOODTYPE.GOODIES, health=1, hunger=2, sanity=0}, -- Jelly Worm
	{food=FOODTYPE.GOODIES, health=2, hunger=0, sanity=1}, -- Tentacle Lolli
	{food=FOODTYPE.GOODIES, health=1, hunger=1, sanity=1}, -- Choco Pigs
}

assert(#candyinfo == NUM_HALLOWEENCANDY)

local function MakeCandy(num)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("halloweencandy")
        inst.AnimState:SetBuild("halloweencandy")
        inst.AnimState:PlayAnimation(tostring(num))

        inst:AddTag("molebait")
        inst:AddTag("cattoy")
        inst:AddTag("halloweencandy")
        inst:AddTag("show_spoilage")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("edible")
		inst.components.edible.foodtype = candyinfo[num].food
		inst.components.edible.hungervalue = candyinfo[num].hunger
		inst.components.edible.healthvalue = candyinfo[num].health
		inst.components.edible.sanityvalue = candyinfo[num].sanity

        MakeHauntableLaunch(inst)

        inst:AddComponent("bait")

        return inst
    end

    return Prefab("halloweencandy_"..tostring(num), fn, assets, prefabs)
end

local ret = {}
for k = 1, NUM_HALLOWEENCANDY do
    table.insert(ret, MakeCandy(k))
end

return unpack(ret)
