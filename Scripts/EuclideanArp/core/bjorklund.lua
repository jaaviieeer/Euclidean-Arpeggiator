--bjorklund algorithm
local M = {}
function M.bjorklund(steps, pulses)
    steps = tonumber(steps) or 1
    pulses = tonumber(pulses) or 0

    if steps < 1 then steps = 1 end
    if pulses < 0 then pulses = 0 end
    if pulses > steps then pulses = steps end

    local pattern = {}

    for i = 1, steps do
        pattern[i] = 0
    end

    if pulses == 0 then
        return pattern
    end

    if pulses == steps then
        for i = 1, steps do
            pattern[i] = 1
        end
        return pattern
    end

    local prev = -1

    for i = 0, steps - 1 do
        local curr = math.floor((i * pulses) / steps)
        pattern[i + 1] = curr ~= prev and 1 or 0
        prev = curr
    end

    return pattern
end

function M.rotate_pattern(pattern)
    local first = table.remove(pattern, 1)
    table.insert(pattern, first)
    return pattern
end

return M