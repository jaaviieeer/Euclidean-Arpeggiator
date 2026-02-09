local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
dofile(script_path .. "./bjorklund.lua")
dofile(script_path .. "./euclideanArp.lua")
reaper.Undo_BeginBlock()
reaper.ShowConsoleMsg("=== EUCLIDEAN ARP (TEMPORAL) ===\n")
local steps = 15
local pulses = 9
local note_len_steps = 1 --lenght of the note in steps
local gate = 1 --% of the step that uses a note
local order = 1 --1 up, 2 down, 3 ping pong, 4 random
local note_fraction = 0 --0 adaptative, 1 whole, 1/2 half, 1/4 quarter, etc all fractions supported
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

generateEuclideanArp(take, steps, pulses, order, note_len_steps, gate, note_fraction)

reaper.Undo_EndBlock("Euclidean Arp", -1)