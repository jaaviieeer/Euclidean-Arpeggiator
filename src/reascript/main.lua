reaper.Undo_BeginBlock()
reaper.ShowConsoleMsg("=== EUCLIDEAN ARP (TEMPORAL) ===\n")
local STEPS = 16
local PULSES = 11
local NOTE_LEN_STEPS = 1
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
-- take notes pitches as it is the info we need
local pitches = {}
for i = noteCount - 1, 0, -1 do
    local _, _, _, _, _, _, pitch = reaper.MIDI_GetNote(take, i)
    table.insert(pitches, pitch)
    reaper.MIDI_DeleteNote(take, i)
end
-- sort it (ascending)
table.sort(pitches)
-- note timing
local ppqStart = 0
local ppqPerQN = reaper.MIDI_GetPPQPosFromProjQN(take, 1) -
                 reaper.MIDI_GetPPQPosFromProjQN(take, 0)

local stepPPQ = ppqPerQN / 4  -- semicorchea
-- apply the partern using the bjorklund algorithm
local pattern = bjorklund(STEPS, PULSES)
local noteIndex = 1

for step = 1, STEPS do
    if pattern[step] == 1 then
        local pitch = pitches[noteIndex]
        local startppq = ppqStart + (step - 1) * stepPPQ
        local endppq = startppq + NOTE_LEN_STEPS * stepPPQ

        reaper.MIDI_InsertNote(
            take,
            false, false,
            startppq,
            endppq,
            0,
            pitch,
            100,
            true
        )

        noteIndex = (noteIndex % #pitches) + 1
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Euclidean Arp", -1)