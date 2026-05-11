local M = {}

local JSFX_NAME = "JS: MIDI Euclidean Arpeggiator"
local JSFX_MATCH_NAME = "MIDI Euclidean Arpeggiator"

local function ensure_jsfx(track)
    local fx_index = M.find_jsfx(track)
    if fx_index ~= nil then
        return fx_index
    end

    fx_index = reaper.TrackFX_AddByName(track, JSFX_NAME, false, -1000)

    if fx_index < 0 then
        return nil, "Could not insert JSFX: " .. JSFX_NAME
    end

    return fx_index
end



function M.get_track()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then
        reaper.ShowConsoleMsg("No selected track")
        return nil, "No selected track"
    end
    return track
end

local function set_param(track, fx_index, param_index, value)
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

local function bool01(v)
    if v == true then return 1 end
    if v == false or v == nil then return 0 end
    return tonumber(v) or 0
end

function M.apply(track, config, dependencies)

    local fx_index, fx_err = ensure_jsfx(track)
    if fx_index == nil then
        return false, fx_err
    end

    local steps           = tonumber(config.steps) or 0
    local pulses          = tonumber(config.pulses) or 0
    local pattern_cycling = bool01(config.pattern_rotation) or 0
    local order            = tonumber(config.order) or 1
    local gate            = tonumber(config.gate) or 1
    local note_fraction   = tonumber(config.note_fraction) or (1 / 4)
    local note_cycling    = bool01(config.cycling_enabled) or 0
    local octave_enabled  = bool01(config.octave_enabled) or 0
    local octave_steps    = tonumber(config.octave_steps) or 0
    local octave_pulses   = tonumber(config.octave_pulses) or 0
    local jumping_pattern = bool01(config.jump_enabled) or 0
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
        fx_index = reaper.TrackFX_AddByName(track, JSFX_NAME, false, -1000)
        if fx_index < 0 then
            return nil, "Could not insert JSFX: " .. JSFX_NAME
        end
    end

    set_param(track, fx_index, 0, steps)
    set_param(track, fx_index, 1, pulses)
    set_param(track, fx_index, 2, pattern_cycling)
    set_param(track, fx_index, 3, order)
    set_param(track, fx_index, 4, gate)
    set_param(track, fx_index, 5, note_fraction)
    set_param(track, fx_index, 6, note_cycling)
    set_param(track, fx_index, 7, octave_enabled)
    set_param(track, fx_index, 8, octave_steps)
    set_param(track, fx_index, 9, octave_pulses)
    set_param(track, fx_index, 10, jumping_pattern)
    set_param(track, fx_index, 11, jump_steps)
    set_param(track, fx_index, 12, jump_pulses)
    set_param(track, fx_index, 13, 1)

    return true
end

return M
