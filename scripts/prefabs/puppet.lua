local function createassets(name)
    return {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ANIM", "anim/player_basic.zip"),
        Asset("ANIM", "anim/player_throne.zip")
    }
end

local function createpuppet(name)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 2)

        inst.Transform:SetFourFaced()
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("throne_loop", true)
        inst.AnimState:Hide("ARM_carry") 
        inst.AnimState:Show("ARM_normal")

        --Sneak these into pristine state for optimization
        inst:AddTag("_named")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_named")

        inst:AddComponent("named")
        inst:AddComponent("inspectable")
        inst.components.named:SetName(STRINGS.CHARACTER_NAMES[name])

        if table.contains(CHARACTER_GENDERS.MALE, name) then
            inst.components.inspectable.nameoverride = "male_puppet"
        elseif table.contains(CHARACTER_GENDERS.FEMALE, name) then
            inst.components.inspectable.nameoverride = "fem_puppet"
        elseif table.contains(CHARACTER_GENDERS.ROBOT, name) then
            inst.components.inspectable.nameoverride = "robot_puppet"
        else
            inst.components.inspectable.nameoverride = "male_puppet"
        end

        return inst
    end
end

local prefabs = {}
for i, name in ipairs(DST_CHARACTERLIST) do
    if name ~= "unknown" and
        name ~= "waxwell" then
        table.insert(prefabs, Prefab("puppet_"..name, createpuppet(name), createassets(name))) 
    end
end
return unpack(prefabs)