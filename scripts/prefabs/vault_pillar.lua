local assets =
{
	Asset("ANIM", "anim/pillar_vault_deep.zip"),
}

local function CreateBottom()
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:SetCanSleep(TheWorld.ismastersim)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("pillar_vault")
	inst.AnimState:SetBuild("pillar_vault_deep")
	inst.AnimState:PlayAnimation("idle_lower")
	inst.AnimState:SetLayer(LAYER_BELOW_GROUND)

	return inst
end

local function MakeCapped(inst, var)
	inst.broken = nil
	if var == 2 then
		inst.capped = 2
		inst.AnimState:PlayAnimation("idle_upper_capped_2")
	else
		inst.capped = 1
		inst.AnimState:PlayAnimation("idle_upper_capped")
	end
	return inst
end

local function MakeBroken(inst, broken)
	if broken then
		inst.capped = nil
		inst.broken = 1
		inst.AnimState:PlayAnimation("idle_upper_broken")
	elseif inst.broken then
		inst.broken = nil
		inst.AnimState:PlayAnimation("idle_upper")
	end
	return inst
end

local function OnSave(inst, data)
	data.capped = inst.capped
	data.broken = inst.broken
end

local function OnLoad(inst, data)--, ents)
	if data then
		if data.capped then
			inst:MakeCapped(data.capped)
		elseif data.broken then
			inst:MakeBroken(true)
        elseif data.random then -- Note: this is set by world gen.
            if math.random() < 0.5 then
                inst:MakeBroken(true)
            end
        end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("pillar_vault")
	inst.AnimState:SetBuild("pillar_vault_deep")
	inst.AnimState:PlayAnimation("idle_upper")
	inst.AnimState:SetFinalOffset(-1)

	if not TheNet:IsDedicated() then
		CreateBottom().entity:SetParent(inst.entity)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.MakeCapped = MakeCapped
	inst.MakeBroken = MakeBroken
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("vault_pillar", fn, assets)
