local M = {}

local function section(lines, title)
  table.insert(lines, ("## %s"):format(title))
end

local function item(lines, text)
  table.insert(lines, ("- %s"):format(text))
end

local function resolve_lsp_configs(ft)
  local names = {}
  local enabled = vim.lsp._enabled_configs or {}

  for name, _ in pairs(enabled) do
    local cfg = vim.lsp.config[name]
    local filetypes = cfg and cfg.filetypes or nil
    if not filetypes or vim.tbl_contains(filetypes, ft) then
      table.insert(names, name)
    end
  end

  table.sort(names)
  return names
end

local function resolve_lint_names(ft)
  local ok, lint = pcall(require, "lint")
  if not ok then
    return {}
  end

  local names = lint.linters_by_ft[ft]
  if names then
    return vim.deepcopy(names)
  end

  local dedup = {}
  for _, split_ft in ipairs(vim.split(ft, ".", { plain = true })) do
    local linters = lint.linters_by_ft[split_ft]
    if linters then
      for _, name in ipairs(linters) do
        dedup[name] = true
      end
    end
  end

  local resolved = vim.tbl_keys(dedup)
  table.sort(resolved)
  return resolved
end

local function resolve_declared_conform_names(bufnr)
  local ok, conform = pcall(require, "conform")
  if not ok then
    return {}
  end

  local names = conform.list_formatters_for_buffer(bufnr)
  local resolved = {}
  for _, name in ipairs(names) do
    if type(name) == "string" then
      table.insert(resolved, name)
    end
  end
  table.sort(resolved)
  return resolved
end

local function command_status(command)
  if not command or command == "" then
    return "unknown command"
  end
  if vim.fn.executable(command) == 1 then
    return "installed"
  end
  return "missing"
end

local function treesitter_status(bufnr, ft)
  local ok_lang, lang = pcall(vim.treesitter.language.get_lang, ft)
  if not ok_lang or not lang then
    lang = ft
  end

  local ok_parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if ok_parser then
    return lang, "attached"
  end
  return lang, "missing parser"
end

local function python_mypy_note(bufname)
  local pyproject = vim.fs.find({ "pyproject.toml" }, { path = bufname, upward = true })[1]
  if not pyproject then
    return "mypy linting disabled: no pyproject.toml found"
  end
  local has_mypy = vim.fn.match(vim.fn.readfile(pyproject), "mypy") >= 0
  if has_mypy then
    return ("mypy linting expected from %s"):format(pyproject)
  end
  return ("mypy linting disabled: %s does not mention mypy"):format(pyproject)
end

local function eval_linter_condition(linter, bufname)
  if type(linter.condition) ~= "function" then
    return true, nil
  end

  local ok, result = pcall(linter.condition, { filename = bufname })
  if not ok then
    return false, "condition errored"
  end
  if result then
    return true, nil
  end
  return false, "condition disabled"
end

function M.build_lines(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo[bufnr].filetype
  local lines = {
    "# File Tooling",
    "",
    ("Buffer: %s"):format(bufname ~= "" and bufname or "[No Name]"),
    ("Filetype: %s"):format(ft ~= "" and ft or "[none]"),
  }

  section(lines, "LSP")
  local configured_lsps = resolve_lsp_configs(ft)
  if #configured_lsps == 0 then
    item(lines, "Configured: none")
  else
    item(lines, "Configured: " .. table.concat(configured_lsps, ", "))
  end

  local attached_clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #attached_clients == 0 then
    item(lines, "Attached: none")
  else
    local attached = {}
    table.sort(attached_clients, function(a, b)
      return a.name < b.name
    end)
    for _, client in ipairs(attached_clients) do
      table.insert(attached, client.name)
    end
    item(lines, "Attached: " .. table.concat(attached, ", "))
  end

  for _, name in ipairs(configured_lsps) do
    local cfg = vim.lsp.config[name] or {}
    local cmd = cfg.cmd and table.concat(cfg.cmd, " ") or "[default]"
    local executable = cfg.cmd and cfg.cmd[1] or nil
    item(lines, ("%s: %s (%s)"):format(name, cmd, executable and command_status(executable) or "builtin/default"))
  end

  section(lines, "Treesitter")
  local parser_lang, parser_state = treesitter_status(bufnr, ft)
  item(lines, ("Parser: %s (%s)"):format(parser_lang, parser_state))

  section(lines, "Formatting")
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    item(lines, "Conform: not loaded")
  else
    item(lines, "Conform: loaded")
    local declared_formatters = resolve_declared_conform_names(bufnr)
    if #declared_formatters == 0 then
      item(lines, "Declared for filetype: none")
    else
      item(lines, "Declared for filetype: " .. table.concat(declared_formatters, ", "))
    end
    local runnable_formatters, uses_lsp = conform.list_formatters_to_run(bufnr)
    if #runnable_formatters == 0 then
      item(lines, uses_lsp and "Will run now: lsp" or "Will run now: none")
    else
      local names = {}
      for _, formatter in ipairs(runnable_formatters) do
        table.insert(names, formatter.name)
      end
      if uses_lsp then
        table.insert(names, "lsp")
      end
      item(lines, "Will run now: " .. table.concat(names, ", "))
    end

    for _, name in ipairs(declared_formatters) do
      local formatter = conform.get_formatter_info(name, bufnr)
      local status = formatter.available and "ready" or (formatter.available_msg or "unavailable")
      item(lines, ("%s: %s"):format(name, status))
    end
  end

  section(lines, "Linting")
  local lint_ok, lint = pcall(require, "lint")
  if not lint_ok then
    item(lines, "nvim-lint: not loaded")
  else
    item(lines, "nvim-lint: loaded")
    local lint_names = resolve_lint_names(ft)
    if #lint_names == 0 then
      item(lines, "Declared for filetype: none")
    else
      item(lines, "Declared for filetype: " .. table.concat(lint_names, ", "))
    end

    local running = lint.get_running(bufnr)
    item(lines, #running > 0 and ("Running: " .. table.concat(running, ", ")) or "Running: none")

    for _, name in ipairs(lint_names) do
      local linter = lint.linters[name]
      if not linter then
        item(lines, ("%s: missing linter config"):format(name))
      else
        local cmd = type(linter.cmd) == "string" and linter.cmd or nil
        local enabled, condition_note = eval_linter_condition(linter, bufname)
        local status = cmd and command_status(cmd) or "dynamic/unknown command"
        if enabled then
          status = status == "installed" and "ready" or status
        elseif condition_note then
          status = condition_note
        end
        item(lines, ("%s: %s"):format(name, status))
      end
    end
  end

  section(lines, "Completion")
  item(lines, "blink.cmp: source chain = snippets, lsp, path, buffer")
  item(lines, "LuaSnip: enabled")

  section(lines, "Notes")
  if ft == "python" then
    item(lines, python_mypy_note(bufname))
  end
  item(lines, "Built-ins: :LspInfo, :ConformInfo, :checkhealth, :Inspect")

  return lines
end

function M.show(bufnr)
  local lines = M.build_lines(bufnr)
  vim.cmd("new")
  local out_buf = vim.api.nvim_get_current_buf()
  vim.bo[out_buf].buftype = "nofile"
  vim.bo[out_buf].bufhidden = "wipe"
  vim.bo[out_buf].swapfile = false
  vim.bo[out_buf].modifiable = true
  vim.bo[out_buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, lines)
  vim.bo[out_buf].modifiable = false
  vim.api.nvim_buf_set_name(out_buf, "File Tooling")
end

return M
