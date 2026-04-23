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

function M.disable_live_fx(track)
    local fx_count = reaper.TrackFX_GetCount(track)
    for i = 0, fx_count - 1 do
        local retval, fx = reaper.TrackFX_GetFXName(track, i)
        if retval and fx:find(JSFX_NAME, 1, true) then
            reaper.TrackFX_Delete(track, i)
        end
    end
end

function M.apply(track, config, dependencies)
    local steps           = tonumber(config.steps) or 0
    local pulses          = tonumber(config.pulses) or 0
    local pattern_cycling = tonumber(config.pattern_rotation) or 0
    local mode            = tonumber(config.order) or 1
    local gate            = tonumber(config.gate) or 1
    local note_fraction   = tonumber(config.note_fraction) or (1 / 4)
    local note_cycling    = tonumber(config.cycling_enabled)
    local octave_enabled  = tonumber(config.octave_enabled) or 0
    local octave_steps    = tonumber(config.octave_steps) or 0
    local octave_pulses   = tonumber(config.octave_pulses) or 0
    local jumping_pattern = tonumber(config.jump_enabled)
    local jump_steps      = tonumber(config.jump_steps) or 0
    local jump_pulses     = tonumber(config.jump_pulses) or 0
    local fx_count        = reaper.TrackFX_GetCount(track)
    local fx_index        = -1
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
    set_param(track, fx_index, 2, pattern_cycling)
    set_param(track, fx_index, 3, mode)
    set_param(track, fx_index, 4, gate)
    set_param(track, fx_index, 5, note_fraction)
    set_param(track, fx_index, 6, note_cycling)
    set_param(track, fx_index, 7, octave_enabled)
    set_param(track, fx_index, 8, octave_steps)
    set_param(track, fx_index, 9, octave_pulses)
    set_param(track, fx_index, 10, jumping_pattern)
    set_param(track, fx_index, 11, jump_steps)
    set_param(track, fx_index, 12, jump_pulses)

    return true
end

return M
