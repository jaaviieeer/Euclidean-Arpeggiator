-- bjorklund algorithm is in its own file
local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
dofile(script_path .. "./bjorklund.lua")
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
-- count notes in the midi item
-- this function returns 3 values, we only need the second one, _ ignores the first value
local _, noteCount = reaper.MIDI_CountEvts(take)
-- read selected notes if selected or all the notes if there is no selected notes
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
-- sort notes (at first we sort based on pitch, will up to user)
table.sort(notes, function (a, b)
    return a.pitch < b.pitch
end)
-- apply the partern using the bjorklund algorithm
local pattern = bjorklund(16, 9)
for i = 1, #notes do
    local step = pattern[(i - 1) % #pattern + 1]
    if step == 0 then
        reaper.MIDI_SetNote(
            take,
            notes[i].index,
            false, true,
            notes[i].startppq,
            notes[i].endppq,
            nil,
            nil,
            nil,
            true
        )
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Euclidean Arp", -1)