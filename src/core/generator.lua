local M = {}

function M.build_events(pitches, config, ppqPerQN, dependencies)
    local bjor = dependencies.bjor
    local pitch = dependencies.pitch
    local time = dependencies.time

    local steps = tonumber(config.steps) or 0
    local pulses = tonumber(config.pulses) or 0
    local cycles = tonumber(config.cycles) or 0
    local cycle_length = tonumber(config.cycle_length) or steps
    local gate = tonumber(config.gate) or 1
    local note_fraction = tonumber(config.note_fraction) or (1/4)
    local order = tonumber(config.order) or 1
    local octave_steps = tonumber(config.octave_steps) or 0
    local octave_pulses = tonumber(config.octave_pulses) or 0
    local jump_steps = tonumber(config.jump_steps) or 0
    local jump_pulses = tonumber(config.jump_pulses) or 0

    local stepPPQ = time.step_length_ppq(ppqPerQN, note_fraction)
    local baseLen = stepPPQ
    local pattern = bjor.bjorklund(steps, pulses)

    local octave_pattern = nil
    if octave_steps > 0 and octave_pulses > 0 then
        octave_pattern = bjor.bjorklund(octave_steps, octave_pulses)
    end

    local jump_pattern = nil
    if jump_steps > 0 and jump_pulses > 0 then
        jump_pattern = bjor.bjorklund(jump_steps, jump_pulses)
    end

    local ordered = pitch.order_notes(pitches, order)
    local noteIndex = 1
    local totalSteps = cycle_length * cycles
    local events = {}
    local cycle_count = 0

    for step = 0, totalSteps - 1 do
        local patternStep = (step % cycle_length) + 1
        if pattern[patternStep] == 1 then
            local p = ordered[noteIndex]

            if octave_pattern then
                local octStep = (step % octave_steps) + 1
                if octave_pattern[octStep] == 1 then p = p + 12 end
            end

            local startPPQ = step * stepPPQ
            local endPPQ = startPPQ + baseLen * gate

            events[#events + 1] = {
                startPPQ = startPPQ,
                endPPQ = endPPQ,
                pitch = p,
                vel = 100,
                chan = 0
            }
            if jump_pattern then
                local jumpStep = (step % jump_steps) + 1
                if jump_pattern[jumpStep] == 1 then noteIndex = (noteIndex % #ordered) + 1 end
            end
            noteIndex = (noteIndex % #ordered) + 1
        end
        cycle_count = cycle_count + 1
            if cycle_count >= cycle_length then
                cycle_count = 0
                if config.cycling_enabled then
                    ordered = pitch.cycle_notes(ordered)
                end
            end
    end

    local totalPPQNeeded = totalSteps * stepPPQ
    return events, totalPPQNeeded, nil
end

return M
