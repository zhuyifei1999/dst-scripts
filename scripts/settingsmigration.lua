package.path = package.path .. ";scripts/?.lua"
require("dumper")

function ParseOldSaveData(savedata)

    local sessionIds = {}
    local saveIndexContents = {}

    if savedata ~= nil and
       savedata.slots ~= nil and
       type(savedata.slots) == "table" then

        for i, oldSlot in ipairs(savedata.slots) do

            if oldSlot ~= nil and oldSlot.session_id ~= nil then

				local saveIndexData = { last_used_slot=1, slots = { oldSlot } }
                saveIndexData = DataDumper(saveIndexData, nil, false)

                sessionIds[i] = oldSlot.session_id
                saveIndexContents[i] = saveIndexData
            end
        end
    end

    return sessionIds, saveIndexContents

end

