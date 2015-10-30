PlayerHistory = Class(function(self)
    self.persistdata = {}

    self.listening = false
    self.dirty = false
    self.sort_function =  function(a,b) return (a.days_survived or 1) > (b.days_survived or 1) end

    self.max_history = 100
end)

function PlayerHistory:StartListening()
    if not self.listening then
        self.listening = true
        TheWorld:ListenForEvent("playerentered", function(world, player) self:UpdateHistoryOnEntered(player) end)
        TheWorld:ListenForEvent("playerexited", function(world, player) self:UpdateHistoryOnExited(player) end)
    end
end

function PlayerHistory:Reset()
    self.persistdata = {}
    self.dirty = true
    self:Save()
end

function PlayerHistory:DiscardDownToMaxForNew()
    self:SortBackwards("sort_date")
    while #self.persistdata > (self.max_history - 1) do
        self.persistdata[#self.persistdata] = nil
    end
end

function PlayerHistory:UpdateHistoryOnEntered(player)
    if ThePlayer ~= player then
        local current_index = nil
        for i, existing_v in ipairs(self.persistdata) do
            if player.userid == existing_v.userid then
                current_index = i
                break
            end
        end

        local client = TheNet:GetClientTableForUser(player.userid)

        local seen_state =
        {
            name = player.name,
            userid = player.userid,
            netid = client ~= nil and client.netid or "",
            server_name = TheNet:GetServerName(),
            prefab = player.prefab,
            playerage = player.components.age:GetAgeInDays(),
            date = os.date("%b %d, %y"),
            sort_date = os.date("%Y%m%d"),
        }

        if client ~= nil then
            seen_state.base_skin = client.base_skin
            seen_state.body_skin = client.body_skin
            seen_state.hand_skin = client.hand_skin
            seen_state.legs_skin = client.legs_skin
        end

        if current_index == nil then
            self:DiscardDownToMaxForNew()
            table.insert(self.persistdata, 1, seen_state)
        else
            self.persistdata[current_index] = seen_state
        end

        self.dirty = true
        self:Save() --we could skip this, but we'd potentially lose data if someone kills the app without disconnecting
    end
end

function PlayerHistory:UpdateHistoryOnExited(player)
    if ThePlayer ~= player then
        for i, v in ipairs(self.persistdata) do
            if player.userid == v.userid then
                --found this player in our data
                v.date = os.date("%b %d, %y")
                v.sort_date = os.date("%Y%m%d")
                v.playerage = player.components.age:GetAgeInDays()
                v.prefab = player.prefab

                self.dirty = true
                self:Save()
                return
            end
        end
    end
end

function PlayerHistory:GetRows()
    return self.persistdata
end

function PlayerHistory:Sort(field, forwards)
    if forwards == nil then
        forwards = true
    end
    local sort_function = self.sort_function
    if field ~= nil and self.persistdata[1] ~= nil then
        sort_function = function(a,b)
            if forwards then
                return a[field] < b[field]
            else
                return a[field] > b[field]
            end
        end
        table.sort( self.persistdata, sort_function )
    end
end

function PlayerHistory:SortBackwards(field)
    self:Sort(field, false)
end

----------------------------

function PlayerHistory:GetSaveName()
    return BRANCH == "release" and "player_history" or "player_history_"..BRANCH
end


function PlayerHistory:Save(callback)
    if self.dirty then
        self:Sort()
        if #self.persistdata > 40 then
            for idx = #self.persistdata, 40, -1 do
                table.remove(self.persistdata, idx)
            end
        end
        --print( "SAVING Player History", #self.persistdata )
        local str = json.encode(self.persistdata)
        local insz, outsz = SavePersistentString(self:GetSaveName(), str, ENCODE_SAVES, callback)
    elseif callback ~= nil then
            callback(true)
        end
end

function PlayerHistory:Load(callback)
    TheSim:GetPersistentString(self:GetSaveName(),
        function(load_success, str) 
            -- Can ignore the successfulness cause we check the string
            self:Set( str, callback )
        end, false)
end

function PlayerHistory:Set(str, callback)
    if str == nil or string.len(str) == 0 then
        print ("PlayerHistory could not load ".. self:GetSaveName())
        if callback then
            callback(false)
        end
    else
        print ("PlayerHistory loaded ".. self:GetSaveName(), #str)

        self.persistdata = TrackedAssert("TheSim:GetPersistentString player history",  json.decode, str)
        self:Sort("sort_date", true)

        -- self.totals = {days_survived = 0, deaths = 0}
        -- for i,v in ipairs(self.persistdata) do
        --  self.totals.days_survived = self.totals.days_survived + (v.days_survived or 0)
        -- end

        self.dirty = false
        if callback then
            callback(true)
        end
    end
end
