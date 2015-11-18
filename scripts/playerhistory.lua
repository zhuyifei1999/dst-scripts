PlayerHistory = Class(function(self)
    self.persistdata = {}
    self.existing_map = {}

    self.task = nil
    self.dirty = false
    self.sort_function = function(a,b) return (a.days_survived or 1) > (b.days_survived or 1) end

    self.max_history = 40
end)

function PlayerHistory:StartListening()
    if self.task == nil then
        self.task = TheWorld:DoPeriodicTask(60, function() self:UpdateHistoryFromClientTable() end)
    end
end

function PlayerHistory:Reset()
    self.persistdata = {}
    self.existing_map = {}
    self.dirty = true
    self:Save()
end

function PlayerHistory:DiscardDownToMaxForNew()
    self:SortBackwards("sort_date")
    for idx = #self.persistdata, self.max_history - 1, -1 do
        self.existing_map[self.persistdata[idx].userid] = nil
        table.remove(self.persistdata, idx)
    end
end

function PlayerHistory:UpdateHistoryFromClientTable()
    local ClientObjs = TheNet:GetClientTable()
    if ClientObjs ~= nil and #ClientObjs > 0 then
        local my_userid = TheNet:GetUserID()
        local server_name = TheNet:GetServerName()
        local current_date = os.date("%b %d, %y")
        local sort_date = os.date("%Y%m%d")

        for i, v in ipairs(ClientObjs) do
            -- Skip yourself
            -- Skip dedicated server host
            if v.userid ~= my_userid and not (v.performance ~= nil and TheNet:GetServerIsDedicated()) then
                local seen_state =
                {
                    name = v.name,
                    userid = v.userid,
                    netid = v.netid,
                    prefab = v.prefab,
                    playerage = v.playerage,
                    server_name = server_name,
                    date = current_date,
                    sort_date = sort_date,
                }

                -- Replace existing record if found
                -- Otherwise add new record to the front
                local existing_record = self.existing_map[v.userid]
                if existing_record ~= nil then
                    for k2, v2 in pairs(seen_state) do
                        existing_record[k2] = v2
                    end
                else
                    self:DiscardDownToMaxForNew()
                    table.insert(self.persistdata, 1, seen_state)
                    self.existing_map[v.userid] = seen_state
                end

                self.dirty = true
            end
        end

        self:Save()
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
        self:SortBackwards("sort_date")
        for idx = #self.persistdata, self.max_history, -1 do
            self.existing_map[self.persistdata[idx].userid] = nil
            table.remove(self.persistdata, idx)
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

        -- Create a map for existing user ids
        -- NOTE: cannot map to index, because once we add new
        --       records to the front, all these indices will
        --       become invalid
        self.existing_map = {}
        for i, v in ipairs(self.persistdata) do
            self.existing_map[v.userid] = v
        end

        self:SortBackwards("sort_date")

        -- self.totals = {days_survived = 0, deaths = 0}
        -- for i,v in ipairs(self.persistdata) do
        --  self.totals.days_survived = self.totals.days_survived + (v.days_survived or 0)
        -- end

        self.dirty = false
        if callback ~= nil then
            callback(true)
        end
    end
end
