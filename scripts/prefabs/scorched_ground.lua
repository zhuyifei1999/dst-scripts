local assets =
{
	Asset("ANIM", "anim/scorched_ground.zip")
}

local function OnSave(inst, data)
    data.alpha = inst.alpha
end

local function OnLoad(inst, data)
    if data then
        inst.alpha = data.alpha or 1
        inst.AnimState:SetMultColour(1,1,1,inst.alpha)
    end
end

local anim_names =
{
    "idle",
}


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    for i = 2, 10 do
        table.insert(anim_names, "idle"..i)
    end

    inst.AnimState:SetBuild("scorched_ground")
    inst.AnimState:SetBank("scorched_ground")
    inst.AnimState:PlayAnimation(anim_names[math.random(#anim_names)])
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end


    inst.Transform:SetRotation(math.random() * 360)

    -- local scale = 2 * math.random()
    -- scale = math.clamp(scale, 1, 1.33)

    -- inst.Transform:SetScale(scale, scale, scale)

    inst.alpha = 1
    inst:AddComponent("colourtweener")

	return inst
end

return Prefab("common/objects/scorchedground", fn, assets)