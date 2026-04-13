local M = {}

local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
math.randomseed(math.floor(reaper.time_precise()))
local bjor = dofile(script_path .. "./core/bjorklund.lua")
local pitch = dofile(script_path .. "./core/pitch.lua")
local time = dofile(script_path .. "./core/time.lua")
local generator = dofile(script_path .. "./core/generator.lua")
local reaperInteraction = dofile(script_path .. "./reaper/adapter.lua")

function M.apply(config)
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

    reaper.Undo_BeginBlock()
    local pitches = reaperInteraction.read_pitches_from_take(take)
    local timing = reaperInteraction.get_item_timing(take)
    local events, totalPPQNeeded = generator.build_events(pitches, config, timing.ppqPerQN,
        { bjor = bjor, pitch = pitch, time = time })
    reaperInteraction.set_item_length_for_ppq(timing, take, totalPPQNeeded)
    reaperInteraction.insert_events(take, timing, events)

    reaper.Undo_EndBlock("Euclidean Arp", -1)
    return true, "OK"
end

return M