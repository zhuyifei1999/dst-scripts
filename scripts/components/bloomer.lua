local Bloomer = Class(function(self, inst)
    self.inst = inst
    self.bloomstack = {}
end)

function Bloomer:OnRemoveFromEntity()
    for i, v in ipairs(self.bloomstack) do
        if v.onremove ~= nil then
            self.inst:RemoveEventCallback("onremove", v.onremove, v.source)
        end
    end
end

function Bloomer:GetCurrentFX()
    return #self.bloomstack > 0 and self.bloomstack[#self.bloomstack].fx or nil
end

function Bloomer:PushBloom(source, fx, priority)
    if source ~= nil and fx ~= nil then
        local oldfx = self:GetCurrentFX()
        local bloom = nil

        priority = priority or 0

        for i, v in ipairs(self.bloomstack) do
            if v.source == source then
                bloom = v
                bloom.fx = fx
                bloom.priority = priority
                table.remove(self.bloomstack, i)
                break
            end
        end

        if bloom == nil then
            bloom = { source = source, fx = fx, priority = priority }
            if type(source) == "table" then
                bloom.onremove = function() self:PopBloom(source) end
                self.inst:ListenForEvent("onremove", bloom.onremove, source)
            end
        end

        for i, v in ipairs(self.bloomstack) do
            if v.priority > priority then
                table.insert(self.bloomstack, i, bloom)
                local newfx = self:GetCurrentFX()
                if newfx ~= oldfx then
                    self.inst.AnimState:SetBloomEffectHandle(newfx)
                end
                return
            end
        end

        table.insert(self.bloomstack, bloom)
        if fx ~= oldfx then
            self.inst.AnimState:SetBloomEffectHandle(fx)
        end
    end
end

function Bloomer:PopBloom(source)
    if source ~= nil then
        for i, v in ipairs(self.bloomstack) do
            if v.source == source then
                if v.onremove ~= nil then
                    self.inst:RemoveEventCallback("onremove", v.onremove, source)
                end
                local oldfx = self:GetCurrentFX()
                table.remove(self.bloomstack, i)
                local newfx = self:GetCurrentFX()
                if newfx == nil then
                    self.inst.AnimState:ClearBloomEffectHandle()
                elseif newfx ~= oldfx then
                    self.inst.AnimState:SetBloomEffectHandle(newfx)
                end
                return
            end
        end
    end
end

function Bloomer:GetDebugString()
    local str = ""
    for i = #self.bloomstack, 1, -1 do
        local bloom = self.bloomstack[i]
        str = str..string.format("\n\t[%d] %s: %s", bloom.priority, tostring(bloom.source), bloom.fx)
    end
    return str
end

return Bloomer
