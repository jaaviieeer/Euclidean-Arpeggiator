local M = {}

function M.order_notes(pitches, order)
    if order == 1 then --up
        table.sort(pitches)
    end
        
    if order == 2 then --down
        table.sort(pitches, function (a,b)
            return a > b
        end)
    end
    
    if order == 3 then --pingpong
        for i = #pitches - 1, 2, -1 do
            table.insert(pitches, pitches[i])
        end
    end

    if order == 4 then --random
        for i = #pitches, 2, -1 do
            local j = math.random(i)
            pitches[i], pitches[j] = pitches[j], pitches[i]
        end
    end
    return pitches
end

function M.cycle_notes(pitches)
    local first = table.remove(pitches, 1)
    table.insert(pitches, first)
    return pitches
end

return M