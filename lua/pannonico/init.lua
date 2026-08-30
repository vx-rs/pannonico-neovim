local M = {}
local release = require('pannonico.lsp_release')

-- host_target returns the exact native release target for this Neovim host.
local function host_target()
  local uname = vim.uv.os_uname()
  local os = ({ Darwin = 'darwin', Linux = 'linux', Windows_NT = 'windows' })[uname.sysname]
  local architecture = ({ x86_64 = 'amd64', AMD64 = 'amd64', aarch64 = 'arm64', arm64 = 'arm64' })[uname.machine]
  if not os or not architecture then
    error(('Pannonico does not publish an LSP for %s/%s'):format(uname.sysname, uname.machine))
  end
  return os .. '-' .. architecture
end

-- read_bytes loads one native artifact without text conversion.
local function read_bytes(path)
  local file, open_error = io.open(path, 'rb')
  if not file then
    return nil, open_error
  end
  local bytes = file:read('*a')
  file:close()
  return bytes
end

-- verify_artifact checks exact size, SHA-256, and native executable format.
local function verify_artifact(path, target, artifact)
  local bytes = read_bytes(path)
  if not bytes or #bytes ~= artifact.size or vim.fn.sha256(bytes) ~= artifact.sha256 then
    return false
  end
  if target:match('^darwin%-') then
    return bytes:sub(1, 4) == string.char(0xcf, 0xfa, 0xed, 0xfe)
  elseif target:match('^linux%-') then
    return bytes:sub(1, 4) == string.char(0x7f) .. 'ELF'
  end
  return bytes:sub(1, 2) == 'MZ'
end

-- download_command returns the documented downloader for the current host.
local function download_command(url, destination, target)
  if target:match('^windows%-') then
    return { 'powershell.exe', '-NoProfile', '-NonInteractive', '-Command', 'Invoke-WebRequest -UseBasicParsing -Uri $args[0] -OutFile $args[1]', url, destination }
  end
  return { 'curl', '--fail', '--location', '--silent', '--show-error', '--output', destination, url }
end

-- acquire returns one verified pinned executable or the explicit local path.
local function acquire(options)
  local target = host_target()
  local artifact = assert(release.artifacts[target], 'missing Pannonico LSP release target ' .. target)
  local path = options.lsp_path
  if path then
    path = vim.fs.normalize(path)
    if not verify_artifact(path, target, artifact) then
      error('Pannonico local LSP does not match the pinned ' .. target .. ' artifact')
    end
    return path
  end

  local directory = vim.fs.joinpath(vim.fn.stdpath('data'), 'pannonico', 'lsp', release.version, target)
  path = vim.fs.joinpath(directory, artifact.filename)
  if verify_artifact(path, target, artifact) then
    if not target:match('^windows%-') then
      assert(vim.uv.fs_chmod(path, 493))
    end
    return path
  end
  vim.fn.delete(directory, 'rf')
  vim.fn.mkdir(directory, 'p')
  local temporary = path .. '.download'
  local url = ('https://github.com/vx-rs/pannonico-lsp/releases/download/v%s/%s'):format(release.version, artifact.filename)
  local result = vim.system(download_command(url, temporary, target), { text = true }):wait()
  if result.code ~= 0 or not verify_artifact(temporary, target, artifact) then
    vim.fn.delete(temporary)
    error('Pannonico LSP download failed verification: ' .. (result.stderr or 'unknown error'))
  end
  assert(vim.uv.fs_rename(temporary, path))
  if not target:match('^windows%-') then
    assert(vim.uv.fs_chmod(path, 493))
  end
  return path
end

-- register_commands exposes only status and restart lifecycle diagnostics.
local function register_commands()
  vim.api.nvim_create_user_command('PannonicoStatus', function()
    local clients = vim.lsp.get_clients({ name = 'pannonico' })
    vim.notify(#clients == 0 and 'Pannonico LSP is stopped' or ('Pannonico LSP clients: %d'):format(#clients))
  end, { desc = 'Show Pannonico LSP status' })
  vim.api.nvim_create_user_command('PannonicoRestart', function()
    vim.lsp.enable('pannonico', false)
    vim.schedule(function() vim.lsp.enable('pannonico', true) end)
  end, { desc = 'Restart Pannonico LSP clients' })
end

--- Configure Pannonico through Neovim 0.12's built-in LSP lifecycle.
--- @param options table|nil Optional `{ lsp_path = '/absolute/offline/path' }`.
function M.setup(options)
  if vim.version().minor < 12 then
    error('Pannonico requires Neovim 0.12 or newer; older releases are unsupported')
  end
  options = options or {}
  local command = acquire(options)
  vim.lsp.config('pannonico', {
    cmd = { command },
    filetypes = { 'html', 'markdown' },
    root_markers = { '.pannonico', 'pannonico.yaml' },
  })
  register_commands()
  vim.lsp.enable('pannonico')
end

return M
