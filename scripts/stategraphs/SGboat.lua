local events =
{

}

local function SpawnFragment(inst, prefix, suffix, offset_x, offset_y, offset_z)
    local fragment = SpawnPrefab(prefix .. suffix)
    local pos_x, pos_y, pos_z = inst.Transform:GetWorldPosition()
    fragment.Transform:SetPosition(pos_x + offset_x, pos_y + offset_y, pos_z + offset_z)   


    if offset_y > 0 then
        local physics = fragment.Physics
        if physics ~= nil then        
            physics:SetVel(0, -0.25, 0)
        end
    end

end

local states =
{
    State
    {
        name = "place",
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/mast/place")
            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/large",nil,.3)
            inst.AnimState:PlayAnimation("place")
        end,

        events =
        {        
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },                        
    },

    State
    {
        name = "idle",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_full", true)        
        end,

        events =
        {        
            EventHandler("death", function(inst) inst.sg:GoToState("ready_to_snap") end),
        },                        
    },

    State
    {
        name = "ready_to_snap",
        onenter = function(inst)         
            inst.sg:SetTimeout(0.75)               
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("snapping")
        end,
    },


    State
    {
        name = "snapping",
        onenter = function(inst)         
            local fx_boat_crackle = SpawnPrefab("fx_boat_crackle")
            fx_boat_crackle.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.AnimState:PlayAnimation("crack") 
            inst.sg:SetTimeout(1)  

            for k,v in ipairs(inst.components.walkableplatform:GetEntitiesOnPlatform()) do
                v:PushEvent("onpresink")
            end
        end,

        events =
        {        
            EventHandler("animover", function(inst) inst.sg:GoToState("popping") end),
        },   

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/creak")                  
            end),
            TimeEvent(2 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .1})                  
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .2})                  
            end),
            TimeEvent(32* FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .3})                  
            end),
            TimeEvent(39* FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .3})                  
            end),
            TimeEvent(39* FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/creak")                  
            end),
            TimeEvent(51 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .4})                  
            end),
            TimeEvent(58 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .4})                  
            end),
            TimeEvent(60 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .5})                  
            end),
            TimeEvent(71 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage",{intensity= .5})                  
            end),
            TimeEvent(75 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage", {intensity= .6})                  
            end),
            TimeEvent(82 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage", {intensity= .6})                  
            end),
        },        
    },
    
    State
    {
        name = "popping",
        onenter = function(boat)         
            local fx_boat_crackle = SpawnPrefab("fx_boat_pop")
            fx_boat_crackle.Transform:SetPosition(boat.Transform:GetWorldPosition())            
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage", {intensity= 1})                 
            end),
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/sink")
            end),
            TimeEvent(1 * FRAMES, function(inst)
                inst.AnimState:PlayAnimation("hide")  

                local mast_sinking = SpawnPrefab("boat_mast_sink_fx")
                mast_sinking.Transform:SetPosition(inst.Transform:GetWorldPosition())              

                for k,v in ipairs(inst.components.walkableplatform:GetEntitiesOnPlatform()) do
                    v:PushEvent("onsink")
                end

                inst:PushEvent("onsink")

                SpawnFragment(inst, "boatfragment", "04", 2.75, 0, 0.5)
                SpawnFragment(inst, "boatfragment", "05", -2.5, 0, -0.25)
                SpawnFragment(inst, "boatfragment", "04", 0.25, 0, -2.8)
                SpawnFragment(inst, "boatfragment", "05", -0.95, 0, 0.75)
                SpawnFragment(inst, "boards", "", 2, 2, -2.25)
                SpawnFragment(inst, "boards", "", -1.75, 2, -1.5)
                SpawnFragment(inst, "boards", "", 1.25, 2, 1.25)                

            end),

            TimeEvent(30 * FRAMES, function(inst)
                inst:Remove()
            end),
            TimeEvent(110 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/water/sinking_item")                 
            end),            
        },               

        events =
        {

        },                        
    },     
             
}

return StateGraph("boat", states, events, "idle")
