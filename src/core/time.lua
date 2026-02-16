local M = {}

function M.step_length_ppq(ppqPerQN, note_fraction)
  return ppqPerQN * 4 * note_fraction
end

return M