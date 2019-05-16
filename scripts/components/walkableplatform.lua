local WalkablePlatform = Class(function(self, inst)
    self.inst = inst    

    self.inst:AddTag("walkableplatform")

    TheWorld.components.walkableplatformmanager:AddPlatform(inst)

    if not TheWorld.ismastersim then
        self.inst:StartUpdatingComponent(self)
    else
        self.inst:ListenForEvent("onremove", function() self:OnRemove() end)
        self.inst:ListenForEvent("onsink", function() self:OnSink() end)
    end

    self.player_zoomed_out = false
    self.player_zoom_task = nil

    self.previous_objects_on_platform = {}
    self.new_objects_on_platform = {}
    self.platform_radius = 4
    self.movement_locators = {}
end)

local IGNORE_WALKABLE_PLATFORM_TAGS = { "ignorewalkableplatforms" }
local IGNORE_WALKABLE_PLATFORM_TAGS_ON_REMOVE = { "ignorewalkableplatforms", "FX", "NOCLICK", "DECOR", "INLIMBO", "player" }
local IGNORE_WALKABLE_PLATFORM_TAGS = { "ignorewalkableplatforms", "FX", "DECOR", "INLIMBO" }


--Client Only
function WalkablePlatform:OnUpdate(dt) 
    self:CollectEntitiesOnPlatform()
    self:TriggerEvents()
end

function WalkablePlatform:AddMovementLocator(locator)
    self.movement_locators[locator] = true
end

function WalkablePlatform:RemoveMovementLocator(locator)
    self.movement_locators[locator] = nil
end

function WalkablePlatform:OnSink()
    TheWorld.components.walkableplatformmanager:RemovePlatform(self.inst) 
    self.inst:RemoveComponent("walkableplatform")
    self.inst:RemoveTag("walkableplatform")    
    self:DestroyObjectsOnPlatform()
    self:ClearMovementLocators()
end

function WalkablePlatform:ClearMovementLocators()
    for k,v in pairs(self.movement_locators) do
        if k:IsValid() and k:HasTag("movement_locator") then
            k.entity:SetParent(nil)
        end
    end
end

function WalkablePlatform:OnRemove()
    TheWorld.components.walkableplatformmanager:RemovePlatform(self.inst)     
end

function WalkablePlatform:DestroyObjectsOnPlatform()
    for k,v in ipairs(self:GetEntitiesOnPlatform(nil, IGNORE_WALKABLE_PLATFORM_TAGS_ON_REMOVE)) do
        if v:IsValid() then            
            local health = v.components.health
            if health ~= nil then
                health:Kill()
            else
                if v.components.inventoryitem ~= nil then
                    v.components.inventoryitem:SetLanded(false, true)
                else
                    v:Remove()
                end
            end
        end
    end
end

function WalkablePlatform:GetEntitiesOnPlatform(must_have_tags, ignore_tags)      
    ignore_tags = ignore_tags or IGNORE_WALKABLE_PLATFORM_TAGS
    local world_position_x, world_position_y, world_position_z = self.inst.Transform:GetWorldPosition()
    local entities = TheSim:FindEntities(world_position_x, world_position_y, world_position_z, self.platform_radius, must_have_tags, ignore_tags)
        
    for i, v in ipairs(entities) do
        if v == self.inst or not v:IsValid() or v.parent ~= nil then
            table.remove(entities, i)
        end
    end

    return entities
end

function WalkablePlatform:UpdatePositions()
	if self.previous_position_x == nil then
        self.previous_position_x, self.previous_position_y, self.previous_position_z = self.inst.Transform:GetWorldPosition()
		return
	end

    local is_master_sim = TheWorld.ismastersim

    local world_position_x, world_position_y, world_position_z = self.inst.Transform:GetWorldPosition()
	local delta_position_x, delta_position_z = VecUtil_Sub(world_position_x, world_position_z, self.previous_position_x, self.previous_position_z)

    local should_update_pos = VecUtil_LengthSq(delta_position_x, delta_position_z) > 0

    self:CollectEntitiesOnPlatform()

    for k, v in pairs(self.new_objects_on_platform) do
        if k:IsValid() then
            local is_client_player_with_prediction_enabled = ThePlayer == k and ThePlayer.components.locomotor
            if is_master_sim or is_client_player_with_prediction_enabled then

    		    local entity_position_x, entity_position_y, entity_position_z = k.Transform:GetWorldPosition()
                local new_entity_position_x, new_entity_position_z = VecUtil_Add(entity_position_x, entity_position_z, delta_position_x, delta_position_z)

                local physics = k.Physics
                if physics ~= nil then
                    physics:TeleportRespectingInterpolation(new_entity_position_x, entity_position_y, new_entity_position_z)
                else
    		        k.Transform:SetPosition(new_entity_position_x, entity_position_y, new_entity_position_z)
                end
            end
        end
    end

    self.previous_position_x, self.previous_position_y, self.previous_position_z = world_position_x, world_position_y, world_position_z

    self:TriggerEvents()
end

function WalkablePlatform:CollectEntitiesOnPlatform()
    local entities = self:GetEntitiesOnPlatform(nil, IGNORE_WALKABLE_PLATFORM_TAGS)
    for i, v in ipairs(entities) do
        if v:IsValid() then
            self.new_objects_on_platform[v] = true
        end
    end
end

local ZOOM_STEP = 0.25
local ZOOM_TARGET = 5
local ZOOM_TIME = 4
local NUM_ZOOMS = ZOOM_TARGET / ZOOM_STEP
local ZOOM_TASK_PERIOD = ZOOM_TIME / NUM_ZOOMS

local function player_zoom(boat_inst, self, player_inst)
    -- If our player inst is still valid and we haven't done all of our zoomes yet,
    -- send another zoom message to the camera. Otherwise, end ourselves.
    if player_inst and player_inst:IsValid() and self.player_zooms <= NUM_ZOOMS then
        player_inst:PushEvent("zoomcamera", {zoomout = self.player_zoomed_out, zoom = ZOOM_STEP})
        self.player_zooms = self.player_zooms + 1
    else
        self.player_zoom_task:Cancel()
        self.player_zoom_task = nil
    end
end

function WalkablePlatform:TriggerEvents()
    for k,v in pairs(self.previous_objects_on_platform) do
        if self.new_objects_on_platform[k] == nil then
            k:PushEvent("got_off_platform", self.inst)

            -- If our player was zoomed out and just jumped off of the platform,
            -- we should undo our zoom effect.
            if self.player_zoomed_out and k == ThePlayer then
                self.player_zoomed_out = false
                self.player_zooms = 0

                -- Cancel any currently running zoom task, and then just snap out our target amount.
                -- It's ok if our zoom snap is off; we just want to get out of the player's way ASAP.
                if self.player_zoom_task ~= nil then
                    self.player_zoom_task:Cancel()
                    self.player_zoom_task = nil
                end
                ThePlayer:PushEvent("zoomcamera", {zoomout = false, zoom = ZOOM_TARGET})
            end
        end
    end

    for k,v in pairs(self.new_objects_on_platform) do
        if self.previous_objects_on_platform[k] == nil then
            k:PushEvent("got_on_platform", self.inst)
        end

        -- If this object is the player, we need to check for whether we should zoom in/out.
        if k == ThePlayer then
            local should_zoom = false
            local has_zoom_tag = self.inst:HasTag("doplatformcamerazoom")

            if self.player_zoomed_out == false and has_zoom_tag then
                self.player_zoomed_out = true
                should_zoom = true
            elseif self.player_zoomed_out == true and not has_zoom_tag then
                self.player_zoomed_out = false
                should_zoom = true
            end

            if should_zoom then
                self.player_zooms = 0

                -- If a task was already running, we just cancel it and start a task zooming in the opposite direction.
                if self.player_zoom_task ~= nil then
                    self.player_zoom_task:Cancel()
                    self.player_zoom_task = nil
                end
                self.player_zoom_task = self.inst:DoPeriodicTask(ZOOM_TASK_PERIOD, player_zoom, nil, self, k)
            end
        end
    end

    self.previous_objects_on_platform = self.new_objects_on_platform
    self.new_objects_on_platform = {}
end

return WalkablePlatform