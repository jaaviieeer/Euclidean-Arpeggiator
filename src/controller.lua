local M = {}

local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
math.randomseed(math.floor(reaper.time_precise()))
local bjor = dofile(script_path .. "./core/bjorklund.lua")
local pitch = dofile(script_path .. "./core/pitch.lua")
local time = dofile(script_path .. "./core/time.lua")
local generator = dofile(script_path .. "./core/generator.lua")
local reaperInteraction = dofile(script_path .. "./adapter/offlineAdapter.lua")
local jsfxInteraction = dofile(script_path .. "./adapter/liveAdapter.lua")


function M.apply(config)
    if config.mode == "live" then
        return M.runLive(config)
    else
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

        return M.runOffline(config, take)
    end
end

function M.runLive(config)
    local ok, msg = jsfxInteraction.apply(config, { bjor = bjor, pitch = pitch, time = time })
    if not ok then
        reaper.ShowConsoleMsg("Error applying live mode: " .. msg)
    end
    return ok, msg
end

function M.runOffline(config, take)
    reaper.Undo_BeginBlock()
    local timing = reaperInteraction.get_item_timing(take)

    local events, totalPPQNeeded

    if not config.multiple_chords_enabled then
        local pitches = reaperInteraction.read_pitches_from_take(take)
        events, totalPPQNeeded = generator.build_events(pitches, config, timing.ppqPerQN,
            { bjor = bjor, pitch = pitch, time = time })
    else
        local chords      = {}
        local currentPPQ  = timing.itemStartPPQ
        local intervalPPQ = time.step_length_ppq(timing.ppqPerQN, config.multiple_chord_interval)
        while currentPPQ < timing.itemEndPPQ do
            local pitchesInWindow = reaperInteraction.read_pitches_from_window(take, currentPPQ,
                currentPPQ + intervalPPQ)
            if #pitchesInWindow > 0 then
                table.insert(chords, pitchesInWindow)
            end
            currentPPQ = currentPPQ + intervalPPQ
        end
        events, totalPPQNeeded = generator.build_events_from_chord_sequence(chords, config, timing.ppqPerQN,
            { bjor = bjor, pitch = pitch, time = time })
    end

    reaperInteraction.clear_notes_from_take(take)
    reaperInteraction.set_item_length_for_ppq(timing, take, totalPPQNeeded)
    reaperInteraction.insert_events(take, timing, events)

    reaper.Undo_EndBlock("Euclidean Arp", -1)
    return true, "OK"
end

return M
