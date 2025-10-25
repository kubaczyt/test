local lastFoundObjects = {}

local UINT32_MAX = 0x100000000

local function sendMessage(message, color)
    color = color or {255, 255, 255}
    TriggerEvent('chat:addMessage', {
        color = color,
        args = {'^3FindObject', message}
    })
end

local function notify(message)
    if TriggerEvent then
        sendMessage(message)
    else
        print(message)
    end
end

local function saveResultsToFile(objects)
    local lines = {}
    for index, data in ipairs(objects) do
        local coords = data.coords
        lines[#lines + 1] = ("%d: %.2f, %.2f, %.2f"):format(index, coords.x, coords.y, coords.z)
    end
    local content = table.concat(lines, '\n')
    SaveResourceFile(GetCurrentResourceName(), 'findobject_results.txt', content, -1)
    notify(('Saved %d object coordinates to findobject_results.txt'):format(#objects))
end

local function normalizeHash(value)
    if type(value) ~= 'number' then
        return nil
    end

    if value < 0 then
        value = UINT32_MAX + value
    end

    return value
end

local function formatHashForDisplay(value)
    if value == nil then
        return 'unknown'
    end

    if type(value) ~= 'number' then
        return tostring(value)
    end

    local normalized = normalizeHash(value)
    if not normalized or normalized == value then
        return tostring(value)
    end

    local unsignedStr = ('%.0f'):format(normalized)
    local hexStr = ('0x%X'):format(normalized)

    return ('%s (unsigned: %s, hex: %s)'):format(value, unsignedStr, hexStr)
end

local function parseHash(input)
    if not input or input == '' then
        return nil
    end

    local numeric = tonumber(input)
    if not numeric then
        local sign = 1
        local candidate = input

        if candidate:sub(1, 1) == '-' then
            sign = -1
            candidate = candidate:sub(2)
        end

        if candidate:sub(1, 2):lower() == '0x' then
            local parsed = tonumber(candidate:sub(3), 16)
            if parsed then
                numeric = sign * parsed
            end
        end
    end

    if numeric then
        return numeric
    end

    return GetHashKey(input)
end

local function enumerateObjects(callback)
    local seen = {}

    for _, entity in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(entity) and not seen[entity] then
            seen[entity] = true
            callback(entity)
        end
    end

    local handle, entity = FindFirstObject()
    if handle and handle ~= -1 then
        if entity and entity ~= 0 then
            local continue = true
            repeat
                if DoesEntityExist(entity) and not seen[entity] then
                    seen[entity] = true
                    callback(entity)
                end

                continue, entity = FindNextObject(handle)
            until not continue
        end

        EndFindObject(handle)
    end
end

local function collectObjectsByHash(targetHash)
    local normalizedTarget = normalizeHash(targetHash)
    local results = {}

    if not normalizedTarget then
        return results
    end

    enumerateObjects(function(entity)
        local model = GetEntityModel(entity)
        if normalizeHash(model) == normalizedTarget then
            local coords = GetEntityCoords(entity)
            results[#results + 1] = {
                entity = entity,
                coords = coords
            }
        end
    end)

    return results
end

RegisterCommand('findobject', function(source, args)
    if not args[1] then
        notify('Usage: /findobject <objectHash or modelName> [save]')
        return
    end

    local targetHash = parseHash(args[1])
    if not targetHash then
        notify(('Invalid hash "%s" provided.'):format(args[1]))
        return
    end

    local shouldSave = false
    for i = 2, #args do
        if args[i]:lower() == 'save' then
            shouldSave = true
        end
    end

    lastFoundObjects = collectObjectsByHash(targetHash)

    local count = #lastFoundObjects
    local displayHash = formatHashForDisplay(targetHash)

    if count == 0 then
        notify(('No objects found for hash %s.'):format(displayHash))
        return
    end

    notify(('Found %d object(s) for hash %s. Use /gotoobject <index> to teleport.'):format(count, displayHash))

    for index, data in ipairs(lastFoundObjects) do
        local coords = data.coords
        sendMessage(('#%d -> %.2f, %.2f, %.2f'):format(index, coords.x, coords.y, coords.z), {0, 200, 255})
    end

    if shouldSave then
        saveResultsToFile(lastFoundObjects)
    end
end, false)

RegisterCommand('gotoobject', function(source, args)
    if #lastFoundObjects == 0 then
        notify('No cached objects. Use /findobject first.')
        return
    end

    local index = tonumber(args[1] or '')
    if not index or not lastFoundObjects[index] then
        notify('Usage: /gotoobject <index>. Index must reference a listed object.')
        return
    end

    local coords = lastFoundObjects[index].coords
    local ped = PlayerPedId()

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    notify(('Teleported to object #%d at %.2f, %.2f, %.2f'):format(index, coords.x, coords.y, coords.z))
end, false)
