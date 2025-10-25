-- Normalizace hashů na neznaménkové 32-bit číslo (0..4294967295)
local function normalizeHash(value)
    if type(value) ~= "number" then return nil end
    local two32 = 4294967296 -- 2^32
    -- převede případné záporné / mimo rozsah na 0..2^32-1
    local normalized = ((value % two32) + two32) % two32
    return normalized
end

-- Přátelské zobrazení hashe: původní, unsigned i hex
local function hashToDisplayString(value)
    local normalized = normalizeHash(value)
    if not normalized or normalized == value then
        return tostring(value)
    end
    local unsignedStr = ('%.0f'):format(normalized)
    local hexStr = ('0x%X'):format(normalized)
    return ('%s (unsigned: %s, hex: %s)'):format(value, unsignedStr, hexStr)
end

-- Robustní parsování vstupu: čísla (dec/hex, i se znaménkem) nebo jména → hash
local function parseHash(input)
    if not input or input == '' then
        return nil
    end

    -- pokus o přímé číslo (např. "12345" nebo "-12345")
    local numeric = tonumber(input)

    -- když to není čisté číslo, zkusíme 0xHEX (i se znaménkem)
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

    -- fallback: GTA/FiveM jméno hashe → číslo
    return GetHashKey(input)
end

-- Enumerace všech objektů ve světě, bez duplicit; volá callback(entity)
local function enumerateObjects(callback)
    if type(callback) ~= "function" then return end

    local seen = {}

    -- 1) rychlý průchod přes game pool
    for _, entity in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(entity) and not seen[entity] then
            seen[entity] = true
            callback(entity)
        end
    end

    -- 2) jistota přes nativní iterátor (někdy najde i to, co pool ne)
    local handle, entity = FindFirstObject()
    if handle and handle ~= -1 then
        local ok = true
        repeat
            if ok and entity and DoesEntityExist(entity) and not seen[entity] then
                seen[entity] = true
                callback(entity)
            end
            ok, entity = FindNextObject(handle)
        until not ok
        EndFindObject(handle)
    end
end
