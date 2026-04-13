local M = {}

function M.step_length_ppq(ppqPerQN, note_fraction) --realmente es una conversion de medidas musicales a medidas del take
  return ppqPerQN * 4 * note_fraction
end

return M