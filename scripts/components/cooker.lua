local Cooker = Class(function(self, inst)
    self.inst = inst

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("cooker")
end)

function Cooker:OnRemoveFromEntity()
    self.inst:RemoveTag("cooker")
end

function Cooker:CanCook(item, chef)
    return item ~= nil
        and item.components.cookable ~= nil
        and not (self.inst.components.fueled ~= nil and self.inst.components.fueled:IsEmpty())
        and (not self.inst:HasTag("dangerouscooker") or chef:HasTag("expertchef"))
end

function Cooker:CookItem(item, chef)
    if self:CanCook(item, chef) then
        local newitem = item.components.cookable:Cook(self.inst, chef)
        ProfileStatsAdd("cooked_"..item.prefab)

        if self.oncookitem ~= nil then
            self.oncookitem(item, newitem)
        end

        if self.inst.SoundEmitter ~= nil then
            self.inst.SoundEmitter:PlaySound("dontstarve/wilson/cook")
        end

        if self.oncookfn ~= nil then
            self.oncookfn(self.inst, newitem, chef)
        end

        item:Remove()
        return newitem
    end
end

return Cooker
