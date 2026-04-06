package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10'
local ctx = ImGui.CreateContext('Euclidean Arp')
local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
local controller = dofile(script_path .. "../controller.lua")
local bj = dofile(script_path .. "../core/bjorklund.lua")

local config = {
  steps = 15,
  pulses = 9,
  gate = 1,              --% of the step that uses a note
  order = 1,             --1 up, 2 down, 3 ping pong, 4 random
  note_fraction = 1 / 4, --1 whole, 1/2 half, 1/4 quarter, etc all fractions supported
  octave_steps = 0,      -- for the octave pattern
  octave_pulses = 0,     -- for the octave pattern
  cycles = 2,             -- number of cycles
  cycle_length = 15,      --cycle lenght (steps)
  octave_enabled = false
}

local pattern = bj.bjorklund(config.steps, config.pulses)
local octave_pattern = bj.bjorklund(config.octave_steps, config.octave_pulses)

local status = ""
local function set_status(msg) status = tostring(msg or "") end

local function visualize_pattern(pattern)
  local parts = {}
  for i = 1, #pattern do
    parts[i] = pattern[i] == 1 and "■" or "□"
  end
  return table.concat(parts, " ")
end

local function loop()
  local visible, open = ImGui.Begin(ctx, 'Euclidean Arpegiator', true)
  if visible then
    ImGui.Text(ctx, 'Euclidean Arpegiator by Javier Pasamontes Martin')
    ImGui.SeparatorText(ctx, "Rhythm") --STEPS AND PULSES
    local changed
    ImGui.Text(ctx, "Steps")
    ImGui.SameLine(ctx)
    changed, config.steps = ImGui.SliderInt(ctx, "##Steps", config.steps, 1, 128)
    if changed then
      if config.pulses > config.steps then
        config.pulses = config.steps
      end
    end
    ImGui.Text(ctx, "Pulses")
    ImGui.SameLine(ctx)
    changed, config.pulses = ImGui.SliderInt(ctx, "##Pulses", config.pulses, 0, config.steps)
    if changed then
      if config.pulses > config.steps then
        config.pulses = config.steps
      end
    end
    pattern = bj.bjorklund(config.steps, config.pulses)
    ImGui.Text(ctx, visualize_pattern(pattern))
    ImGui.Separator(ctx)                   --DENSITY OF PULSES
    ImGui.Text(ctx, string.format("Density: %.2f%%", (config.pulses / config.steps) * 100))
    ImGui.SeparatorText(ctx, "Note order") --NOTE ORDER
    if ImGui.RadioButton(ctx, "Ascending", config.order == 1) then
      config.order = 1
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Descending", config.order == 2) then
      config.order = 2
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Ping-Pong", config.order == 3) then
      config.order = 3
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Random", config.order == 4) then
      config.order = 4
    end
    ImGui.SeparatorText(ctx, "Note lenght") --NOTE LENGTH
    ImGui.Text(ctx, "Gate")
    ImGui.SameLine(ctx)
    _, config.gate = ImGui.SliderDouble(ctx, "##Gate", config.gate, 0.1, 5.0)
    ImGui.Text(ctx, "Sync")
    ImGui.SameLine(ctx)
    _, config.note_fraction = ImGui.SliderDouble(ctx, "##SyncSlider", config.note_fraction, 0.0, 1.0)
    ImGui.SameLine(ctx)
    local syncText = tostring(config.note_fraction)
    changed, syncText = ImGui.InputText(ctx, "##SyncInput", syncText)
    if changed then
      local num, den = syncText:match("^(%d+)%/(%d+)$")

      if num and den then
        config.note_fraction = tonumber(num) / tonumber(den)
      else
        local val = tonumber(syncText)
        if val then
          config.note_fraction = val
        end
      end
    end
    if config.note_fraction < 0.01 then config.note_fraction = 0.01 end
    if config.note_fraction > 1.0 then config.note_fraction = 1.0 end
    ImGui.SeparatorText(ctx, "Cycles") --CYCLES
    ImGui.Text(ctx, "Cycles")
    ImGui.SameLine(ctx)
    _, config.cycles = ImGui.SliderInt(ctx, "##Cycles", config.cycles, 1, 128)
    ImGui.Text(ctx, "Cycle length")
    ImGui.SameLine(ctx)
    _, config.cycle_length = ImGui.SliderInt(ctx, "##Cycle length", config.cycle_length, 1, config.steps)
    ImGui.SeparatorText(ctx, "Extra") --EXTRA OPTIONS
    ImGui.SeparatorText(ctx, "Octave shifting pattern")
    local changed_enable
    changed_enable, config.octave_enabled = ImGui.Checkbox(ctx, "Enable Octave Pattern", config.octave_enabled or false)
    if changed_enable and not config.octave_enabled then
      config.octave_steps = 0
      config.octave_pulses = 0
    end
    ImGui.BeginDisabled(ctx, not config.octave_enabled)
    local changed
    ImGui.Text(ctx, "Steps")
    ImGui.SameLine(ctx)
    changed, config.octave_steps = ImGui.SliderInt(ctx, "##OctaveSteps", config.octave_steps, 1, 128)
    if changed then
      if config.octave_pulses > config.octave_steps then
        config.octave_pulses = config.octave_steps
      end
    end
    ImGui.Text(ctx, "Pulses")
    ImGui.SameLine(ctx)
    changed, config.octave_pulses = ImGui.SliderInt(ctx, "##OctavePulses", config.octave_pulses, 0, config.octave_steps)
    if changed then
      if config.octave_pulses > config.octave_steps then
        config.octave_pulses = config.octave_steps
      end
    end
    octave_pattern = bj.bjorklund(config.octave_steps, config.octave_pulses)
    ImGui.Text(ctx, visualize_pattern(octave_pattern))
    ImGui.EndDisabled(ctx)
    ImGui.Separator(ctx)
    if ImGui.Button(ctx, "Generate") then
      local ok, msg = controller.apply(config)
    end
    ImGui.End(ctx)
  end
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)
