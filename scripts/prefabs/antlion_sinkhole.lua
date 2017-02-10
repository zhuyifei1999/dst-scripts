local assets =
{
    Asset("ANIM", "anim/antlion_sinkhole.zip"),
    Asset("MINIMAP_IMAGE", "sinkhole"),
}

local prefabs =
{
    "sinkhole_spawn_fx_1",
    "sinkhole_spawn_fx_2",
    "sinkhole_spawn_fx_3",
}

local NUM_CRACKING_STAGES = 3
local COLLAPSE_STAGE_DURATION = 0.9

local function UpdateOverrideSymbols(inst, state)
    if state == NUM_CRACKING_STAGES then
        inst.AnimState:ClearOverrideSymbol("cracks1")
        inst.components.unevenground:Enable()
    else
        inst.AnimState:OverrideSymbol("cracks1", "antlion_sinkhole", "cracks_pre"..tostring(state))
        inst.components.unevenground:Disable()
    end
end

local function UpdateSinkholeRepair(inst)
    if inst.collapsetask == nil then
        local age = (TheWorld.state.cycles + TheWorld.state.time) - inst.creationtime
        if age < TUNING.ANTLION_SINKHOLE.LIFETIME_FIRST_REPAIR then
            UpdateOverrideSymbols(inst, 3)
        elseif age < TUNING.ANTLION_SINKHOLE.LIFETIME_SECOND_REPAIR then
            UpdateOverrideSymbols(inst, 2)
        elseif age < TUNING.ANTLION_SINKHOLE.LIFETIME_FINAL_REPAIR then
            UpdateOverrideSymbols(inst, 1)
        else
            --V2C: can reach here from OnEntityWake, but components will
            --     also finish triggering their OnEntityWake after we're
            --     removed. Normally we'd queue the remove for one frame
            --     but... we can get away with it this way here.
            --[[
                --This would be the safe way
                inst.components.unevenground:Disable()
                inst.persists = false
                inst:Hide()
                inst:DoTaskInTime(0, inst.Remove)
            ]]
            inst.components.unevenground:Disable()
            inst:Remove()
        end
    end
end

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "_combat", "pickable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end
local NON_COLLAPSIBLE_TAGS = { "flying", "bird", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO" }
local NON_COLLAPSIBLE_TAGS_FIRST = { "flying", "bird", "ghost", "locomotor", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function SmallLaunch(inst, launcher, basespeed)
    local hp = inst:GetPosition()
    local pt = launcher:GetPosition()
    local vel = (hp - pt):GetNormalized()
    local speed = basespeed * .5 + math.random()
    local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
    inst.Physics:Teleport(hp.x, .1, hp.z)
    inst.Physics:SetVel(math.cos(angle) * speed, 3 * speed + math.random(), math.sin(angle) * speed)
end

local function donextcollapse(inst)
    inst.collapsestage = inst.collapsestage + 1

    local isfinalstage = inst.collapsestage >= NUM_CRACKING_STAGES

    if isfinalstage then
        inst.collapsetask:Cancel()
        inst.collapsetask = nil

        inst:RemoveTag("scarytoprey")
        ShakeAllCameras(CAMERASHAKE.FULL, COLLAPSE_STAGE_DURATION, .03, .15, inst, TUNING.ANTLION_SINKHOLE.RADIUS*6)
    else
        ShakeAllCameras(CAMERASHAKE.FULL, COLLAPSE_STAGE_DURATION, .015, .15, inst, TUNING.ANTLION_SINKHOLE.RADIUS*4)
    end

    UpdateOverrideSymbols(inst, inst.collapsestage)

    local dir = math.random()*PI*2
    local num = 7
    local radius = 1.6
    SpawnPrefab("sinkhole_spawn_fx_"..math.random(3)).Transform:SetPosition(inst:GetPosition():Get())
    for i = 1, num do
        local function spawnit(inst)
            local dust=SpawnPrefab("sinkhole_spawn_fx_"..math.random(3))
            dust.Transform:SetPosition((inst:GetPosition() + Vector3(math.cos(dir)*radius*(1+math.random()*0.1), 0, -math.sin(dir))*radius*(1+math.random()*0.1)):Get())
            local scale = .8 + math.random() * .5
            dust.Transform:SetScale(scale * (i%2==0 and -1 or 1), scale, scale)
            dir = dir + ((2*PI) / num)
        end
        spawnit(inst)
    end

    inst.SoundEmitter:PlaySoundWithParams("dontstarve/creatures/together/antlion/sfx/ground_break", {size=math.pow(inst.collapsestage/NUM_CRACKING_STAGES, 2)})

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, TUNING.ANTLION_SINKHOLE.RADIUS + 1, nil, inst.collapsestage > 1 and NON_COLLAPSIBLE_TAGS or NON_COLLAPSIBLE_TAGS_FIRST, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() then
            if v.components.workable ~= nil and
                v.components.workable:CanBeWorked() and
                COLLAPSIBLE_WORK_ACTIONS[v.components.workable:GetWorkAction().id] then
                if isfinalstage then
                    v.components.workable:Destroy(inst)
                    if v:IsValid() and v:HasTag("stump") then
                        v:Remove()
                    end
                else
                    if v.components.workable:GetWorkAction() == ACTIONS.MINE then
                        SpawnPrefab(v:HasTag("frozen") and "mining_ice_fx" or "mining_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
                    end
                    v.components.workable:WorkedBy(inst, 1)
                end
            elseif v.components.pickable ~= nil
                and v.components.pickable:CanBePicked() then
                local num = v.components.pickable.numtoharvest or 1
                local product = v.components.pickable.product
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                if product ~= nil and num > 0 then
                    for i = 1, num do
                        SpawnPrefab(product).Transform:SetPosition(x1, 0, z1)
                    end
                end
            elseif v.components.combat ~= nil
                and v.components.health ~= nil
                and not v.components.health:IsDead() then
                v.components.combat:GetAttacked(inst, TUNING.ANTLION_SINKHOLE.DAMAGE)
            end
        end
    end
    local totoss = TheSim:FindEntities(x, 0, z, TUNING.ANTLION_SINKHOLE.RADIUS, { "_inventoryitem" }, { "locomotor", "INLIMBO" })
    for i, v in ipairs(totoss) do
        if not v.components.inventoryitem.nobounce and v.Physics ~= nil then
            SmallLaunch(v, inst, 1.5)
        end
    end
end

local function onstartcollapse(inst)
    inst.collapsestage = 0
    inst.creationtime = (TheWorld.state.cycles + TheWorld.state.time) - math.random() * TUNING.ANTLION_SINKHOLE.LIFETIME_VARIANCE

    inst:AddTag("scarytoprey")

    inst.collapsetask = inst:DoPeriodicTask(COLLAPSE_STAGE_DURATION, donextcollapse)
    donextcollapse(inst)
end

-------------------------------------------------------------------------------

local function OnSave(inst, data)
    data.creationtime = inst.creationtime

    if inst.collapsetask ~= nil then
        data.collapsestage = inst.collapsestage
    end
end

local function OnLoad(inst, data)
    inst.creationtime = data ~= nil and data.creationtime or 0

    if data ~= nil and data.collapsestage then
        inst.collapsestage = data.collapsestage
        UpdateOverrideSymbols(inst, inst.collapsestage)
        inst.collapsetask = inst:DoPeriodicTask(COLLAPSE_STAGE_DURATION, donextcollapse)
    else
        UpdateSinkholeRepair(inst)
    end
end


-------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("sinkhole")
    inst.AnimState:SetBuild("antlion_sinkhole")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("sinkhole.png")

    inst.Transform:SetEightFaced()

    inst:AddTag("antlion_sinkhole")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("workrepairable")

    inst:SetDeployExtraSpacing(4)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("unevenground")
    inst.components.unevenground.radius = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnEntitySleep = UpdateSinkholeRepair
    inst.OnEntityWake = UpdateSinkholeRepair

    inst.creationtime = 0

    inst:ListenForEvent("startcollapse", onstartcollapse)

    return inst
end

return Prefab("antlion_sinkhole", fn, assets, prefabs)
