local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
dofile(script_path .. "./bjorklund.lua")

function orderNotes(pitches, order)
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

function stepLength(ppqPerQN, note_fraction)
    return ppqPerQN * 4 * note_fraction
end

function generateEuclideanArp(take, steps, pulses, order, note_len_steps, gate, note_fraction)
    -- count notes in the midi item
    -- this function returns 3 values, we only need the second one, _ ignores the first value
    local _, noteCount = reaper.MIDI_CountEvts(take)
    -- take notes pitches as it is the info we need
    local pitches = {}
    for i = noteCount - 1, 0, -1 do
        local _, _, _, _, _, _, pitch = reaper.MIDI_GetNote(take, i)
        table.insert(pitches, pitch)
        reaper.MIDI_DeleteNote(take, i)
    end
    -- order the notes
    pitches = orderNotes(pitches, order)
    -- note timing
    local item = reaper.GetMediaItemTake_Item(take) --identify the item to get the time position
    local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    --midi positions
    local itemStartPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, itemPos) --item initial position
    local itemEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, itemPos + itemLen) --item final position
    --midi units per quarter note
    local ppqPerQN = reaper.MIDI_GetPPQPosFromProjQN(take, 1) - reaper.MIDI_GetPPQPosFromProjQN(take, 0)
    --we divide the midi in steps
    local totalPPQ = itemEndPPQ - itemStartPPQ
    local stepPPQ = totalPPQ / steps
    stepPPQ = stepLength(ppqPerQN, note_fraction)
    -- apply the partern using the bjorklund algorithm
    local pattern = bjorklund(steps, pulses)
    local noteIndex = 1
    local stepsNeeded = 0
    local notesPlaced = 0

    while notesPlaced < #pitches do
        local patternStep = (stepsNeeded % steps) + 1
        if pattern[patternStep] == 1 then
            notesPlaced = notesPlaced + 1
        end
        stepsNeeded = stepsNeeded + 1
    end

    local totalPPQNeeded = stepsNeeded * stepPPQ


    local newItemEndTime = reaper.MIDI_GetProjTimeFromPPQPos(
        take,
        itemStartPPQ + totalPPQNeeded
    )

    reaper.SetMediaItemInfo_Value(
        item,
        "D_LENGTH",
        newItemEndTime - itemPos
    )

    itemEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take,itemPos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
)

    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)

    local step = 0
    local notesPlaced = 0

    while notesPlaced < #pitches do
        local patternStep = (step % steps) + 1 --cycle
        local startppq = itemStartPPQ + step * stepPPQ

        if startppq >= itemEndPPQ then break end

        if pattern[patternStep] == 1 then
            local pitch = pitches[noteIndex]
            local baseLen = note_len_steps * stepPPQ
            local endppq = math.min(startppq + baseLen * gate, itemEndPPQ)

            reaper.MIDI_InsertNote(
                take,
                false, false,
                startppq,
                endppq,
                0,
                pitch,
                100, --may be interesting to make it variable
                true
            )

            noteIndex = (noteIndex % #pitches) + 1
            notesPlaced = notesPlaced + 1
        end
        step = step + 1
    end
    reaper.MIDI_Sort(take)
end