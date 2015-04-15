local function makeassetlist(name)
    return {
        Asset("ANIM", "anim/"..name..".zip")
    }
end

local function makefn(name, collide)
    return function()
    	local inst = CreateEntity()

    	inst.entity:AddTransform()
    	inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        if collide then
            MakeObstaclePhysics(inst, 2.75)
        end

        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)

        return inst
    end
end

local function pillar(name, collide)
    return Prefab("cave/objects/"..name, makefn(name, collide), makeassetlist(name))
end

return pillar("pillar_ruins", true), pillar("pillar_algae", true), pillar("pillar_cave", true), pillar("pillar_stalactite")