PlayerHistory = Class(function(self)
    self.persistdata = {}
	
    self.dirty = false
    self.sort_function =  function(a,b) return (a.days_survived or 1) > (b.days_survived or 1) end
    
    self.max_history = 100
end)

function PlayerHistory:StartListening()
	TheWorld:ListenForEvent("playerentered", function() self:UpdateHistoryFromClientTable() end )
	TheWorld:ListenForEvent("playerexited", function( inst ) self:UpdateHistoryOnExited( inst ) end )
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

function PlayerHistory:UpdateHistoryFromClientTable()

	local ClientObjs = TheNet:GetClientTable()
	if ClientObjs ~= nil then
		local _server_name = TheNet:GetServerName()
		for _,v in pairs(ClientObjs) do
			if ThePlayer ~= nil and ThePlayer.userid ~= v.userid then
				local this_user_is_dedicated_server = v.performance ~= nil and TheNet:GetServerIsDedicated()
				if not this_user_is_dedicated_server then
					local current_index = -1
					for k,existing_v in pairs(self.persistdata) do
						if v.userid == existing_v.userid then
							current_index = k
						end
					end
					
					local current_date = os.date("%b %d, %y")
					local _sort_date = os.date("%Y%m%d")
					local seen_state = { name = v.name, userid = v.userid, steamid = v.steamid, server_name = _server_name, prefab = v.prefab, 
										 playerage = v.playerage, date = current_date, sort_date = _sort_date, base_skin = v.base_skin, 
										 body_skin = v.body_skin, hand_skin = v.hand_skin, legs_skin = v.legs_skin }	
					if current_index == -1 then
						self:DiscardDownToMaxForNew()
						table.insert( self.persistdata, 1, seen_state )
					else
						self.persistdata[current_index] = seen_state
					end
					self.dirty = true
				end
			end
		end
		self:Save() --we could skip this, but we'd potentially lose data if someone kills the app without disconnecting
	end
end

function PlayerHistory:UpdateHistoryOnExited( inst )
	if ThePlayer ~= nil and ThePlayer.userid ~= inst.userid then
		for k,v in pairs(self.persistdata) do
			if inst.userid == v.userid then
				--found this player in our data				
				local current_date = os.date("%b %d, %y")
				local _sort_date = os.date("%Y%m%d")
				v.date = current_date
				v.sort_date = _sort_date
				v.playerage = inst.components.age:GetAgeInDays()
				v.prefab = inst.prefab			
				break
			end
		end
	end
	self:Save()
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
    else
		if callback then
			callback(true)
		end
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
		-- 	self.totals.days_survived = self.totals.days_survived + (v.days_survived or 0)
		-- end

		self.dirty = false
		if callback then
			callback(true)
		end
	end
end
