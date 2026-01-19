-- =========================================
-- EUCLIDEAN RHYTHM (BJORKLUND ALGORITHM)
-- =========================================

function bjorklund(steps, pulses)
    if pulses < 0 then pulses = 0 end
    if pulses > steps then pulses = steps end
    if pulses == 0 then
        local r = {}
        for i = 1, steps do r[i] = 0 end
        return r
    end
    if pulses == steps then
        local r = {}
        for i = 1, steps do r[i] = 1 end
        return r
    end

    local pattern = {}
    local counts = {}
    local remainders = {}

    remainders[1] = pulses
    local divisor = steps - pulses
    local level = 1

    while true do
        counts[level] = math.floor(divisor / remainders[level])
        remainders[level + 1] = divisor % remainders[level]
        divisor = remainders[level]
        level = level + 1
        if remainders[level] <= 1 then
            break
        end
    end

    counts[level] = divisor

    local function build(l)
        if l == 0 then
            table.insert(pattern, 0)
        elseif l == -1 then
            table.insert(pattern, 1)
        else
            for i = 1, counts[l] do
                build(l - 1)
            end
            if remainders[l] ~= 0 then
                build(l - 2)
            end
        end
    end

    build(level)
    return pattern
end

-- TEST
local steps = 16
local pulses = 5

local pattern = bjorklund(steps, pulses)

local result = ""
for i = 1, #pattern do
    result = result .. pattern[i] .. " "
end

reaper.ShowConsoleMsg("Pattern: " .. result .. "\n")
print("Pattern: " .. result .. "\n")
