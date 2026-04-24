local M = {}

local JSFX_FILE_NAME = "euclideanArp.jsfx"
local JSFX_NAME = "JS: MIDI Euclidean Arpeggiator"

local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
local project = 0

local function join_path(a, b)
    local sep = package.config:sub(1, 1)
    if a:sub(-1) == "/" or a:sub(-1) == "\\" then
        return a .. b
    end
    return a .. sep .. b
end

local function get_resource_effects_dir()
    local project_path = reaper.GetResourcePath()
    return join_path(project_path, "Effects")
end

local function get_source_jsfx_path()
    return join_path(script_path, "../../jsfx/" .. JSFX_FILE_NAME)
end

local function get_dest_jsfx_path()
    local effects_dir = get_resource_effects_dir()
    return join_path(effects_dir, JSFX_FILE_NAME)
end

local function ensure_directory(path)
    reaper.RecursiveCreateDirectory(path, 0)
end

local function copy_file(src, dst)
    local in_f = io.open(src, "rb")
    if not in_f then
        return false, "Could not open source JSFX: " .. tostring(src)
    end

    local data = in_f:read("*all")
    in_f:close()

    local out_f = io.open(dst, "wb")
    if not out_f then
        return false, "Could not open destination JSFX: " .. tostring(dst)
    end

    out_f:write(data)
    out_f:close()

    return true
end

local function ensure_jsfx_file()
    local effects_dir = get_resource_effects_dir()
    ensure_directory(effects_dir)

    local src = get_source_jsfx_path()
    local dst = get_dest_jsfx_path()

    local f = io.open(dst, "rb")
    if f then
        f:close()
        return true, dst
    end

    local ok, err = copy_file(src, dst)
    if not ok then
        return false, err
    end

    return true, dst
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
    local ok_file, file_msg = ensure_jsfx_file()
    if not ok_file then
        return false, file_msg
    end

    local steps           = tonumber(config.steps) or 0
    local pulses          = tonumber(config.pulses) or 0
    local pattern_cycling = bool01(config.pattern_rotation) or 0
    local mode            = tonumber(config.order) or 1
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
