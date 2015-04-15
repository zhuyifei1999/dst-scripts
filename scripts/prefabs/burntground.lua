local assets =
{
	Asset("ANIM", "anim/burntground.zip")
}

local function OnIsDay(inst, isday)
    if isday then
        inst.alpha = inst.alpha - .2
        inst:DoTaskInTime(math.random(), function(inst)
            inst.components.colourtweener:StartTween({1,1,1,inst.alpha}, 3, function(inst)
                if inst.alpha <= 0 then
                    inst:Remove()
                end
            end)
        end)
    end
end

local function OnSave(inst, data)
    data.alpha = inst.alpha
end

local function OnLoad(inst, data)
    if data then
        inst.alpha = data.alpha or 1
        inst.AnimState:SetMultColour(1,1,1,inst.alpha)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("burntground")
    inst.AnimState:SetBank("burntground")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.Transform:SetRotation(math.random() * 360)

    inst.alpha = 1
    inst:AddComponent("colourtweener")
    inst:WatchWorldState("isday", OnIsDay)

	return inst
end

return Prefab("common/objects/burntground", fn, assets)