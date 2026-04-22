local M = {}

function M.read_pitches_from_take(take)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    -- take notes pitches as it is the info we need
    local pitches = {}
    for i = noteCount - 1, 0, -1 do
        local _, _, _, _, _, _, pitch = reaper.MIDI_GetNote(take, i)
        table.insert(pitches, pitch)
    end
    return pitches
end

function M.read_pitches_from_window(take, startppq, endppq)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    -- take notes pitches as it is the info we need
    local pitches = {}
    for i = noteCount - 1, 0, -1 do
        local _, _, _, sppq, eppq, _, pitch = reaper.MIDI_GetNote(take, i)
        if sppq < endppq and eppq > startppq then
            table.insert(pitches, pitch)
        end
    end
    return pitches
end

function M.clear_notes_from_take(take)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    for i = noteCount - 1, 0, -1 do
        reaper.MIDI_DeleteNote(take, i)
    end
end

function M.get_item_timing(take)
    local item = reaper.GetMediaItemTake_Item(take)
    local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemStartPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, itemPos)
    local itemEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, itemPos + itemLen)
    local ppqPerQN = reaper.MIDI_GetPPQPosFromProjQN(take, 1) - reaper.MIDI_GetPPQPosFromProjQN(take, 0)
    return {
        item = item,
        itemPos = itemPos,
        itemLen = itemLen,
        itemStartPPQ = itemStartPPQ,
        itemEndPPQ = itemEndPPQ,
        ppqPerQN = ppqPerQN
    }
end

function M.set_item_length_for_ppq(timing, take, totalPPQNeeded)
    local newEndTime = reaper.MIDI_GetProjTimeFromPPQPos(take, timing.itemStartPPQ + totalPPQNeeded)
    reaper.SetMediaItemInfo_Value(timing.item, "D_LENGTH", newEndTime - timing.itemPos)
    reaper.SetMediaItemInfo_Value(timing.item, "B_LOOPSRC", 0)
    local newLen = reaper.GetMediaItemInfo_Value(timing.item, "D_LENGTH")
    timing.itemLen = newLen
    timing.itemEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timing.itemPos + newLen)
end

function M.insert_events(take, timing, events)
    for i = 1, #events do
        local e = events[i]
        local startppq = timing.itemStartPPQ + e.startPPQ
        local endppq = timing.itemStartPPQ + e.endPPQ

        if endppq > timing.itemEndPPQ then endppq = timing.itemEndPPQ end
        if startppq < timing.itemEndPPQ and endppq > startppq then
            reaper.MIDI_InsertNote(
                take,
                false, false,
                startppq, 
                endppq,
                0,
                e.pitch,
                100,
                false
            )
        end
    end
    reaper.MIDI_Sort(take)
end

return M