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
  order = 1,             --0 as played, 1 up, 2 down, 3 ping pong, 4 random
  note_fraction = 1 / 4, --1 whole, 1/2 half, 1/4 quarter, etc all fractions supported
  octave_steps = 0,      -- for the octave pattern
  octave_pulses = 0,     -- for the octave pattern
  cycles = 2,            -- number of cycles
  cycle_length = 15,     --cycle lenght (steps)
  octave_enabled = false,
  jump_enabled = false,
  jump_steps = 0,
  jump_pulses = 0,
  cycling_enabled = false,
  multiple_chords_enabled = false,
  multiple_chord_interval = 1, --interval for cycling through chords
  pattern_rotation = false,    --rotation of the pattern
  mode =
  "offline"                    --offline or live, if live the arpeggiator will run in real time, if offline it will generate MIDI items
}

local pattern = bj.bjorklund(config.steps, config.pulses)
local octave_pattern = bj.bjorklund(config.octave_steps, config.octave_pulses)
local jump_pattern = bj.bjorklund(config.jump_steps, config.jump_pulses)

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
      if config.cycle_length > config.steps then
        config.cycle_length = config.steps
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
    _, config.pattern_rotation = ImGui.Checkbox(ctx, "Enable Pattern Rotation", config.pattern_rotation or false)
    ImGui.Text(ctx,
      "If enabled, the pattern will rotate (one position to the left) every cycle, creating a more dynamic rhythm")
    pattern = bj.bjorklund(config.steps, config.pulses)
    ImGui.Text(ctx, visualize_pattern(pattern))
    ImGui.Separator(ctx)                   --DENSITY OF PULSES
    ImGui.Text(ctx, string.format("Density: %.2f%%", (config.pulses / config.steps) * 100))
    ImGui.SeparatorText(ctx, "Note order") --NOTE ORDER
    if ImGui.RadioButton(ctx, "As played", config.order == 0) then
      config.order = 0
    end
    ImGui.SameLine(ctx)
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
    ImGui.SeparatorText(ctx, "Gate") --NOTE LENGTH
    ImGui.Text(ctx, "Gate")
    ImGui.SameLine(ctx)
    _, config.gate = ImGui.SliderDouble(ctx, "##Gate", config.gate, 0.1, 5.0)
    ImGui.SeparatorText(ctx, "Note lenght") --NOTE LENGTH
    ImGui.Text(ctx, "Straight")
    ImGui.SameLine(ctx)
    --notas normales
    if ImGui.RadioButton(ctx, "Whole", config.note_fraction == 1) then
      config.note_fraction = 1
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Half", config.note_fraction == 0.5) then
      config.note_fraction = 0.5
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Quarter", config.note_fraction == 0.25) then
      config.note_fraction = 0.25
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Eighth", config.note_fraction == 0.125) then
      config.note_fraction = 0.125
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Sixteenth", config.note_fraction == 0.0625) then
      config.note_fraction = 0.0625
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Thirty-second", config.note_fraction == 0.03125) then
      config.note_fraction = 0.03125
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Sixty-fourth", config.note_fraction == 0.015625) then
      config.note_fraction = 0.015625
    end
    ImGui.Separator(ctx)
    --notas normales
    ImGui.Text(ctx, "Dotted")
    ImGui.SameLine(ctx)
    --notas puntillo
    if ImGui.RadioButton(ctx, "Dotted Half", config.note_fraction == 3 / 4) then
      config.note_fraction = 3 / 4
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Dotted Quarter", config.note_fraction == 3 / 8) then
      config.note_fraction = 3 / 8
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Dotted Eighth", config.note_fraction == 3 / 16) then
      config.note_fraction = 3 / 16
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Dotted Sixteenth", config.note_fraction == 3 / 32) then
      config.note_fraction = 3 / 32
    end
    ImGui.Separator(ctx)
    --notas puntillo
    ImGui.Text(ctx, "Triplets")
    ImGui.SameLine(ctx)
    --notas triples
    if ImGui.RadioButton(ctx, "Whole Triplet", config.note_fraction == 1 / 3) then
      config.note_fraction = 1 / 3
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Half Triplet", config.note_fraction == 1 / 6) then
      config.note_fraction = 1 / 6
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Quarter Triplet", config.note_fraction == 1 / 12) then
      config.note_fraction = 1 / 12
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Eighth Triplet", config.note_fraction == 1 / 24) then
      config.note_fraction = 1 / 24
    end
    ImGui.Separator(ctx)
    --notas triples
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
    _, config.cycling_enabled = ImGui.Checkbox(ctx, "Enable note list cycling", config.cycling_enabled or false)
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
    ImGui.SeparatorText(ctx, "Jumping pattern")
    local changed_enable
    changed_enable, config.jump_enabled = ImGui.Checkbox(ctx, "Enable Jumping Pattern", config.jump_enabled or false)
    if changed_enable and not config.jump_enabled then
      config.jump_steps = 0
      config.jump_pulses = 0
    end
    ImGui.BeginDisabled(ctx, not config.jump_enabled)
    local changed
    ImGui.Text(ctx, "Steps")
    ImGui.SameLine(ctx)
    changed, config.jump_steps = ImGui.SliderInt(ctx, "##JumpSteps", config.jump_steps, 1, 128)
    if changed then
      if config.jump_pulses > config.jump_steps then
        config.jump_pulses = config.jump_steps
      end
    end
    ImGui.Text(ctx, "Pulses")
    ImGui.SameLine(ctx)
    changed, config.jump_pulses = ImGui.SliderInt(ctx, "##JumpPulses", config.jump_pulses, 0, config.jump_steps)
    if changed then
      if config.jump_pulses > config.jump_steps then
        config.jump_pulses = config.jump_steps
      end
    end
    jump_pattern = bj.bjorklund(config.jump_steps, config.jump_pulses)
    ImGui.Text(ctx, visualize_pattern(jump_pattern))
    ImGui.EndDisabled(ctx)
    ImGui.SeparatorText(ctx, "Multiple chords") --MULTIPLE CHORDS
    ImGui.Text(ctx,
      "When enabled you will have to adjust an interval where the arpeggiator will pick the next chords to use")
    local changed_enable
    changed_enable, config.multiple_chords_enabled = ImGui.Checkbox(ctx, "Enable multiple chords",
      config.multiple_chords_enabled or false)
    if changed_enable and not config.multiple_chords_enabled then
      config.multiple_interval = 0
    end
    ImGui.BeginDisabled(ctx, not config.multiple_chords_enabled)
    ImGui.Text(ctx, "Take chord every N bars")
    ImGui.SameLine(ctx)
    --compases
    if ImGui.RadioButton(ctx, "1/4 bar", config.multiple_chord_interval == 1 / 4) then
      config.multiple_chord_interval = 1 / 4
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "1/2 bar", config.multiple_chord_interval == 1 / 2) then
      config.multiple_chord_interval = 1 / 2
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "1 bar", config.multiple_chord_interval == 1) then
      config.multiple_chord_interval = 1
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "2 bars", config.multiple_chord_interval == 2) then
      config.multiple_chord_interval = 2
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "4 bars", config.multiple_chord_interval == 4) then
      config.multiple_chord_interval = 4
    end
    --compases
    ImGui.EndDisabled(ctx)
    ImGui.Separator(ctx)
    if ImGui.RadioButton(ctx, "Offline Mode", config.mode == "offline") then
      config.mode = "offline"
    end
    ImGui.SameLine(ctx)
    if ImGui.RadioButton(ctx, "Live Mode", config.mode == "live") then
      config.mode = "live"
    end
    if config.mode == "live" then
      if ImGui.Button(ctx, "Connect") then
        local ok, msg = controller.apply(config)
      end
    else
      if ImGui.Button(ctx, "Generate") then
        local ok, msg = controller.apply(config)
      end
    end
    ImGui.End(ctx)
  end
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)
