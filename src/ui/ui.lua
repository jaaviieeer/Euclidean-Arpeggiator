package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10'
local ctx = ImGui.CreateContext('Euclidean Arp')
local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])")
local controller = dofile(script_path .. "../controller.lua")

local config = {
  steps = 15,
  pulses = 9,
  note_len_steps = 1,    --lenght of the note in steps
  gate = 1,              --% of the step that uses a note
  order = 1,             --1 up, 2 down, 3 ping pong, 4 random
  note_fraction = 1 / 4, --1 whole, 1/2 half, 1/4 quarter, etc all fractions supported
  octave_steps = 4,      -- for the octave pattern
  octave_pulses = 1,     -- for the octave pattern
  cycles = 2             -- number of cycles
}

local status = ""
local function set_status(msg) status = tostring(msg or "") end

local function loop()
  local visible, open = ImGui.Begin(ctx, 'Euclidean Arpegiator', true)
  if visible then
    ImGui.Text(ctx, 'Euclidean Arpegiator by Javier Pasamontes Martin')
    ImGui.SeparatorText(ctx, "Rhythm")--STEPS AND PULSES
    local changed
    changed, config.steps = ImGui.SliderInt(ctx, "Steps", config.steps, 1, 128)
    if changed then
      if config.pulses > config.steps then
        config.pulses = config.steps
      end
    end
    changed, config.pulses = ImGui.SliderInt(ctx, "Pulses", config.pulses, 0, config.steps)
    if changed then
      if config.pulses > config.steps then
        config.pulses = config.steps
      end
    end
    ImGui.Separator(ctx)--DENSITY OF PULSES
    ImGui.Text(ctx, string.format("Density: %.2f%%", (config.pulses / config.steps) * 100))
    ImGui.SeparatorText(ctx, "Note order")--NOTE ORDER
    if ImGui.Button(ctx, "Ascending") then
      config.order =1
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Descending") then
      config.order =2
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Ping-Pong") then
      config.order =3
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Random") then
      config.order =4
    end
    ImGui.SeparatorText(ctx, "Note lenght")--NOTE LENGTH
    ImGui.SeparatorText(ctx, "Cycles")--CYCLES
    _, config.cycles = ImGui.SliderInt(ctx, "Cycles", config.cycles, 1, 128)
    ImGui.SeparatorText(ctx, "Extra")--EXTRA OPTIONS
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
