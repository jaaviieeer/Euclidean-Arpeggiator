local M = {}

local JSFX_NAME = "MIDI Euclidean Arpeggiator"

function M.get_track()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then
        reaper.ShowConsoleMsg("No selected track")
        return nil, "No selected track"
    end
    return track
end

function M.apply(track, config, dependencies)
    local steps = tonumber(config.steps) or 0
    local pulses = tonumber(config.pulses) or 0
    local note_fraction = tonumber(config.note_fraction) or (1 / 4)
    

end

return M
