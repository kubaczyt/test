local lastFoundObjects = {}

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

local function parseHash(input)
    if not input or input == '' then
        return nil
    end

    local numeric = tonumber(input)
    if numeric then
        return numeric
    end

    return GetHashKey(input)
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

    local objects = GetGamePool('CObject')
    lastFoundObjects = {}

    for _, entity in ipairs(objects) do
        if DoesEntityExist(entity) and GetEntityModel(entity) == targetHash then
            local coords = GetEntityCoords(entity)
            lastFoundObjects[#lastFoundObjects + 1] = {
                entity = entity,
                coords = coords
            }
        end
    end

    local count = #lastFoundObjects
    if count == 0 then
        notify(('No objects found for hash %s.'):format(targetHash))
        return
    end

    notify(('Found %d object(s) for hash %s. Use /gotoobject <index> to teleport.'):format(count, targetHash))

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
