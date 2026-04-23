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

function set_param(track, fx_index, param_index, value) 
    reaper.TrackFX_SetParam(track, fx_index, param_index, value)
end

function M.apply(track, config, dependencies)
    local steps = tonumber(config.steps) or 0
    local pulses = tonumber(config.pulses) or 0
    local note_fraction = tonumber(config.note_fraction) or (1 / 4)
    local fx_count = reaper.TrackFX_GetCount(track)
    local fx_index = -1
    for i = 0, fx_count - 1 do
        local retval, fx = reaper.TrackFX_GetFXName(track, i)
        if retval and fx:find(JSFX_NAME, 1, true) then
            fx_index = i
        end
    end
    if fx_index == -1 then
        fx_index = reaper.TrackFX_AddByName(track, JSFX_NAME, false, -1)
        if fx_index < 0 then
            return nil, "Could not insert JSFX: " .. JSFX_NAME
        end
    end

    set_param(track, fx_index, 0, steps)
    set_param(track, fx_index, 1, pulses)

    return true
end

return M
