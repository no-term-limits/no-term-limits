local function debuglogger(message)
  local m = "nil"
  if m then
    m = tostring(message)
  end
  vim.notify(m, "info", { timeout = 60000 })
end

return {
  s("cl", {
    t('echo "'),
    i(1, "value"),
    t(": ${"),
    extras.rep(1),
    t('}"'),
  }),
  s("e", {
    t('>&2 echo "ERROR: '),
    i(1, "value"),
    -- 2 args here signify a newline between them
    t({ '"', "exit 1" }),
  }),
  s(
    "s",
    f(function(_, _)
      return 'script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"'
    end, {})
  ),
  s(
    "h",
    f(function(_, _)
      local output = vim.fn.systemlist("bash_script_header")
      local trimmed_output = {}
      for _, line in ipairs(output) do
        table.insert(trimmed_output, line)
      end
      return trimmed_output
    end, {})
  ),
  s(
    "u",
    f(function(_, _)
      local regexForVariableAssignments = '^([%w_]+)="?%$%{?(%d)(:-[%w_]*)}?"?'
      local argVariableAssignmentLineNumbers = {}
      for lineNumber, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        local match = string.match(line, regexForVariableAssignments)
        if match then
          table.insert(argVariableAssignmentLineNumbers, lineNumber)
        end
      end

      local biggestArgumentNumber = 0
      local variableNames = {}
      for _, lineNumber in ipairs(argVariableAssignmentLineNumbers) do
        local textOnLine = vim.api.nvim_buf_get_lines(0, lineNumber - 1, lineNumber, false)[1]
        local _, _, variableName, variableNumber = string.find(textOnLine, regexForVariableAssignments)
        variableNumber = tonumber(variableNumber)

        if variableNumber > biggestArgumentNumber then
          biggestArgumentNumber = variableNumber
        end

        table.insert(variableNames, variableName)
      end

      local usageLine = '  >&2 echo "usage: $(basename "$0")'
      for _, variableName in ipairs(variableNames) do
        usageLine = usageLine .. " [" .. variableName .. "]"
      end
      usageLine = usageLine .. '"'

      local firstLine = 'if [[ -z "${' .. biggestArgumentNumber .. ':-}" ]]; then'
      local lines = { firstLine, usageLine, "  exit 1", "fi" }

      return lines
    end, {})
  ),
}
