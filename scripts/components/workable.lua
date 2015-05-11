local function onworkable(self)
    if self.maxwork ~= nil and self.workleft < self.maxwork and self.workable then
        self.inst:AddTag("workrepairable")
    else
        self.inst:RemoveTag("workrepairable")
    end
    if self.action ~= nil then
        if self.workleft > 0 and self.workable then
            self.inst:AddTag(self.action.id.."_workable")
        else
            self.inst:RemoveTag(self.action.id.."_workable")
        end
    end
end

local function onaction(self, action, old_action)
    if self.workleft > 0 and self.workable then
        if old_action ~= nil then
            self.inst:RemoveTag(old_action.id.."_workable")
        end
        if action ~= nil then
            self.inst:AddTag(action.id.."_workable")
        end
    end
end

local Workable = Class(function(self, inst)
    self.inst = inst
    self.onwork = nil
    self.onfinish = nil
    self.workleft = 10
    self.maxwork = -1
    self.action = ACTIONS.CHOP
    self.savestate = false
    self.destroyed = false
    self.workable = true
end,
nil,
{
    workleft = onworkable,
    maxwork = onworkable,
    action = onaction,
    workable = onworkable,
})

function Workable:OnRemoveFromEntity()
    self.inst:RemoveTag("workrepairable")
    if self.action ~= nil then
        self.inst:RemoveTag(self.action.id.."_workable")
    end
end

function Workable:GetDebugString()
    return "workleft: "..tostring(self.workleft)
        .." maxwork: "..tostring(self.maxwork)
        .." workable: "..tostring(self.workable)
end

function Workable:AddStage(amount)
    table.insert(self.stages, amount)
end

function Workable:SetWorkAction(act)
    self.action = act
end

function Workable:GetWorkAction()
    return self.action
end

function Workable:Destroy(destroyer)
    if not self.destroyed then
        self:WorkedBy(destroyer, self.workleft)
        self.destroyed = true
    end
end

function Workable:SetWorkable(able)
    self.workable = able
end

function Workable:SetWorkLeft(work)
    if not self.workable then self.workable = true end
    work = work or 10
    work = (work <= 0 and 1) or work
    if self.maxwork > 0 then
        work = (work > self.maxwork and self.maxwork) or work
    end
    self.workleft = work
end

function Workable:SetOnLoadFn(fn)
    if type(fn) == "function" then
        self.onloadfn = fn
    end
end

function Workable:SetMaxWork(work)
    work = work or 10
    work = (work <= 0 and 1) or work
    self.maxwork = work
end

function Workable:OnSave()
    if self.savestate then
        return
        {
            maxwork = self.maxwork,
            workleft = self.workleft
        }
    end
    return {}
end

function Workable:OnLoad(data)
    self.workleft = data.workleft or self.workleft
    self.maxwork = data.maxwork or self.maxwork
    if self.onloadfn ~= nil then
        self.onloadfn(self.inst, data)
    end
end

function Workable:WorkedBy(worker, numworks)
    numworks = numworks or 1
    self.workleft = self.workleft - numworks
    self.lastworktime = GetTime()

    worker:PushEvent("working", {target = self.inst})
    self.inst:PushEvent("worked", {worker = worker, workleft = self.workleft})
    
    if self.onwork then
        self.onwork(self.inst, worker, self.workleft)
    end

    if self.workleft <= 0 then
        if self.onfinish ~= nil then
            self.onfinish(self.inst, worker)
        end
        self.inst:PushEvent("workfinished", { worker = worker })

        worker:PushEvent("finishedwork", { target = self.inst, action = self.action })
    end
end

function Workable:SetOnWorkCallback(fn)
    self.onwork = fn
end

function Workable:SetOnFinishCallback(fn)
    self.onfinish = fn
end

return Workable
