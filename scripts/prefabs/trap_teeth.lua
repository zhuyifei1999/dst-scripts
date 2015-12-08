local assets =
{
    Asset("ANIM", "anim/trap_teeth.zip"),
    Asset("ANIM", "anim/trap_teeth_maxwell.zip"),
	Asset("MINIMAP_IMAGE", "toothtrap"),
}

local function onfinished_normal(inst)
    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("mine")
    inst.persists = false
    inst.AnimState:PushAnimation("used", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:DoTaskInTime(3, inst.Remove)
end

local function onused_maxwell(inst)
    inst.AnimState:PlayAnimation("used", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:DoTaskInTime(3, inst.Remove)
end

local function onfinished_maxwell(inst)
    inst:RemoveComponent("mine")
    inst.persists = false
    inst:DoTaskInTime(1.25, onused_maxwell)
end

local function OnExplode(inst, target)
    inst.AnimState:PlayAnimation("trap")
    if target then
        inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_trigger")
        target.components.combat:GetAttacked(inst, TUNING.TRAP_TEETH_DAMAGE)
        if METRICS_ENABLED then
            FightStat_TrapSprung(inst,target,TUNING.TRAP_TEETH_DAMAGE)
        end
    end
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(1)
    end
end

local function OnReset(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_reset")
    inst.AnimState:PlayAnimation("reset")
    inst.AnimState:PushAnimation("idle", false)
end

local function OnResetMax(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_reset")
    inst.AnimState:PlayAnimation("idle")
    --inst.AnimState:PushAnimation("idle", false)
end

local function SetSprung(inst)
    inst.AnimState:PlayAnimation("trap_idle")
end

local function SetInactive(inst)
    inst.AnimState:PlayAnimation("inactive")
end

local function OnDropped(inst)
    inst.components.mine:Deactivate()
end

local function ondeploy(inst, pt, deployer)
    inst.components.mine:Reset()
    inst.Physics:Teleport(pt:Get())
end

--legacy save support - mines used to start out activated
local function onload(inst, data)
    if not data or not data.mine then
        inst.components.mine:Reset()
    end
end

local function common_fn(bank, build, isinventoryitem)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("toothtrap.png")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("trap")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    if isinventoryitem then
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true
        inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    end

    inst:AddComponent("mine")
    inst.components.mine:SetRadius(TUNING.TRAP_TEETH_RADIUS)
    inst.components.mine:SetAlignment("player")
    inst.components.mine:SetOnExplodeFn(OnExplode)
    inst.components.mine:SetOnResetFn(OnReset)
    inst.components.mine:SetOnSprungFn(SetSprung)
    inst.components.mine:SetOnDeactivateFn(SetInactive)
    --inst.components.mine:StartTesting()

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.TRAP_TEETH_USES)
    inst.components.finiteuses:SetUses(TUNING.TRAP_TEETH_USES)
    inst.components.finiteuses:SetOnFinished(onfinished_normal)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if inst.components.mine ~= nil then
            if inst.components.mine.inactive then
                Launch(inst, haunter, TUNING.LAUNCH_SPEED_SMALL)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
                    return true
            elseif inst.components.mine.issprung then
                if math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
                    inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                    inst.components.mine:Reset()
                    return true
                end
            elseif math.random() <= TUNING.HAUNT_CHANCE_HALF then
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
                inst.components.mine:Explode(
                    FindEntity(
                        inst,
                        TUNING.TRAP_TEETH_RADIUS * 1.5,
                        function(dude, inst)
                            return not (dude.components.health ~= nil and
                                        dude.components.health:IsDead())
                                and dude.components.combat:CanBeAttacked(inst)
                        end,
                        { "_combat" }, -- see entityscript.lua
                        { "notraptrigger", "flying", "playerghost" },
                        { "monster", "character", "animal" }
                    )
                )
                return true
            end
        end
        return false
    end)

    inst.components.mine:Deactivate()
    inst.OnLoad = onload
    return inst
end

local function MakeTeethTrapNormal()
    return common_fn("trap_teeth", "trap_teeth", true)
end

local function MakeTeethTrapMaxwell()
    local inst = common_fn("trap_teeth_maxwell", "trap_teeth_maxwell")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.mine:SetAlignment("nobody")
    inst.components.mine:SetOnResetFn(OnResetMax)
    inst.components.finiteuses:SetMaxUses(1)
    inst.components.finiteuses:SetUses(1)
    inst.components.finiteuses:SetOnFinished(onfinished_maxwell)

    inst.components.mine:Reset()

    return inst
end

return Prefab("trap_teeth", MakeTeethTrapNormal, assets),
    MakePlacer("trap_teeth_placer", "trap_teeth", "trap_teeth", "idle"),
    Prefab("trap_teeth_maxwell", MakeTeethTrapMaxwell, assets)
