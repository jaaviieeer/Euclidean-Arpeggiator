-- we take the selected item
local item = reaper.GetSelectedMediaItem(0, 0)
if not item then
    reaper.ShowConsoleMsg("No selected item")
    return
end
-- check if item contains midi
local take = reaper.GetActiveTake(item)
if not take or not reaper.TakeIsMIDI(take) then
    reaper.ShowConsoleMsg("The selected item does not contain MIDI")
    return
end
--count notes in the midi item
--this function returns 3 values, we only need the second one, _ ignores the first value
local _, noteCount = reaper.MIDI_CountEvts(take)
reaper.ShowConsoleMsg("Total notes in selected MIDI item: " ..noteCount.. "\n")
--read selected notes if selected or all the notes if there is no selected notes
local notes = {}
local selectedCount = 0
for i = 0, noteCount - 1 do
    local _, selected = reaper.MIDI_GetNote(take, i)
    if selected then selectedCount = selectedCount + 1 end
end
for i = 0, noteCount - 1 do
    local _, selected, muted, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if selectedCount == 0 or selected then
        table.insert(notes, {
            index = i,
            pitch = pitch,
            vel = vel,
            startppq = startppq,
            endppq = endppq
        })
    end
end

reaper.ShowConsoleMsg("Notes to use: " .. #notes .. "\n")