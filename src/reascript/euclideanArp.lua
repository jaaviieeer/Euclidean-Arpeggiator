local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
dofile(script_path .. "./bjorklund.lua")
math.randomseed(os.time())

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

function generateEuclideanArp(take, steps, pulses, order, note_len_steps, gate, note_fraction, octave_steps, octave_pulses, cycles)
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
    local stepPPQ = stepLength(ppqPerQN, note_fraction)
    -- apply the partern using the bjorklund algorithm
    local pattern = bjorklund(steps, pulses)
    local noteIndex = 1
    -- apply the octave pattern (if not 0)
    local octave_pattern = nil
    if octave_steps > 0 and octave_pulses > 0 then
        octave_pattern = bjorklund(octave_steps, octave_pulses)
    end

    local totalSteps = steps * cycles
    local totalPPQNeeded = totalSteps * stepPPQ

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

    for step = 0, totalSteps - 1 do
        local patternStep = (step % steps) + 1 --cycle
        local startppq = itemStartPPQ + step * stepPPQ

        if pattern[patternStep] == 1 then
            local pitch = pitches[noteIndex]
            local baseLen = note_len_steps * stepPPQ
            local endppq = math.min(startppq + baseLen * gate, itemEndPPQ)

            if octave_pattern then
                local octStep = (step % octave_steps) + 1
                if octave_pattern[octStep] == 1 then
                    pitch = pitch + 12
                end
            end

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
        end
    end
    reaper.MIDI_Sort(take)
end