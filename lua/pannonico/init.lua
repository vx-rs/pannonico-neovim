local M = {}
local lsp_release = require('pannonico.lsp_release')
local runtime_release = require('pannonico.runtime_release')
local guest_project_path = '/project'
local guest_project_uri = 'file:///project'

-- host_target returns the exact Wasmtime release target for this Neovim host.
local function host_target()
  local uname = vim.uv.os_uname()
  local os_name = ({ Darwin = 'darwin', Linux = 'linux', Windows_NT = 'windows' })[uname.sysname]
  local architecture = ({ x86_64 = 'amd64', AMD64 = 'amd64', aarch64 = 'arm64', arm64 = 'arm64' })[uname.machine]
  if not os_name or not architecture then
    error(('Pannonico does not support %s/%s'):format(uname.sysname, uname.machine))
  end
  return os_name .. '-' .. architecture
end

-- read_bytes loads one artifact without text conversion.
local function read_bytes(path)
  local file = io.open(path, 'rb')
  if not file then
    return nil
  end
  local bytes = file:read('*a')
  file:close()
  return bytes
end

-- verify_file checks that a regular, non-link file has the pinned byte identity.
local function verify_file(path, size, sha256)
  local metadata = vim.uv.fs_lstat(path)
  if not metadata or metadata.type ~= 'file' or metadata.size ~= size then
    return false
  end
  local bytes = read_bytes(path)
  return bytes ~= nil and vim.fn.sha256(bytes) == sha256
end

-- powershell_literal quotes one download value without letting its
-- contents become PowerShell syntax in the Windows acquisition command.
local function powershell_literal(value)
  return "'" .. value:gsub("'", "''") .. "'"
end

-- download_command returns the platform downloader invocation while keeping
-- each URL and destination literal across the native process boundary.
local function download_command(url, destination, target)
  if target:match('^windows%-') then
    return {
      'powershell.exe', '-NoProfile', '-NonInteractive', '-Command',
      ('Invoke-WebRequest -UseBasicParsing -Uri %s -OutFile %s')
        :format(powershell_literal(url), powershell_literal(destination)),
    }
  end
  return { 'curl', '--fail', '--location', '--silent', '--show-error', '--output', destination, url }
end

-- run_checked runs one acquisition command and reports stderr on failure.
local function run_checked(command, label)
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    error(('%s failed: %s'):format(label, result.stderr or ('exit ' .. result.code)))
  end
end

-- acquire_lsp returns the verified pinned WASI module or an exact local override.
local function acquire_lsp(options)
  if options.lsp_wasm_path then
    local configured = vim.fs.normalize(options.lsp_wasm_path)
    if not verify_file(configured, lsp_release.size, lsp_release.sha256) then
      error('Pannonico local LSP does not match the pinned WASI module')
    end
    return configured
  end

  local directory = vim.fs.joinpath(vim.fn.stdpath('data'), 'pannonico', 'lsp', lsp_release.version)
  local destination = vim.fs.joinpath(directory, lsp_release.filename)
  if verify_file(destination, lsp_release.size, lsp_release.sha256) then
    return destination
  end
  vim.fn.delete(directory, 'rf')
  vim.fn.mkdir(directory, 'p')
  local temporary = destination .. '.download'
  run_checked(download_command(lsp_release.url, temporary, host_target()), 'Pannonico LSP download')
  if not verify_file(temporary, lsp_release.size, lsp_release.sha256) then
    vim.fn.delete(temporary)
    error('Downloaded Pannonico LSP failed verification')
  end
  assert(vim.uv.fs_rename(temporary, destination))
  return destination
end

-- extraction_command returns the exact one-member Wasmtime extraction command.
local function extraction_command(archive, directory, artifact)
  return { 'tar', '-xf', archive, '-C', directory, artifact.member }
end

-- acquire_wasmtime returns the verified runtime executable for this host.
local function acquire_wasmtime(options)
  local target = host_target()
  local artifact = assert(runtime_release.artifacts[target], 'missing Wasmtime release target ' .. target)
  if options.wasmtime_path then
    local configured = vim.fs.normalize(options.wasmtime_path)
    if not verify_file(configured, artifact.member_size, artifact.member_sha256) then
      error('Pannonico local Wasmtime does not match the pinned ' .. target .. ' runtime')
    end
    return configured
  end

  local directory = vim.fs.joinpath(vim.fn.stdpath('data'), 'pannonico', 'wasmtime', runtime_release.version, target)
  local executable_name = target:match('^windows%-') and 'wasmtime.exe' or 'wasmtime'
  local destination = vim.fs.joinpath(directory, executable_name)
  if verify_file(destination, artifact.member_size, artifact.member_sha256) then
    if not target:match('^windows%-') then
      assert(vim.uv.fs_chmod(destination, 493))
    end
    return destination
  end

  vim.fn.delete(directory, 'rf')
  vim.fn.mkdir(directory, 'p')
  local archive = vim.fs.joinpath(directory, artifact.archive)
  run_checked(download_command(artifact.url, archive, target), 'Wasmtime download')
  if not verify_file(archive, artifact.archive_size, artifact.archive_sha256) then
    vim.fn.delete(archive)
    error('Downloaded Wasmtime archive failed verification')
  end
  local extraction_root = vim.fs.joinpath(directory, 'extract')
  vim.fn.mkdir(extraction_root, 'p')
  run_checked(extraction_command(archive, extraction_root, artifact), 'Wasmtime extraction')
  local extracted = vim.fs.joinpath(extraction_root, artifact.member)
  if not verify_file(extracted, artifact.member_size, artifact.member_sha256) then
    error('Extracted Wasmtime executable failed verification')
  end
  assert(vim.uv.fs_rename(extracted, destination))
  vim.fn.delete(extraction_root, 'rf')
  vim.fn.delete(archive)
  if not target:match('^windows%-') then
    assert(vim.uv.fs_chmod(destination, 493))
  end
  return destination
end

-- wasmtime_cache_config creates the editor-owned compilation-cache setting.
local function wasmtime_cache_config()
  local directory = vim.fs.joinpath(vim.fn.stdpath('cache'), 'pannonico', 'wasmtime')
  local cache_directory = vim.fs.joinpath(directory, 'modules')
  local configuration = vim.fs.joinpath(directory, 'config.toml')
  vim.fn.mkdir(directory, 'p')
  vim.fn.mkdir(cache_directory, 'p')
  local escaped = cache_directory:gsub('\\', '\\\\'):gsub('"', '\\"')
  local expected = ('[cache]\ndirectory = "%s"\n'):format(escaped)
  if read_bytes(configuration) ~= expected then
    local file = assert(io.open(configuration, 'wb'))
    assert(file:write(expected))
    assert(file:close())
  end
  return configuration
end

-- map_uri_value copies one protocol value while translating only file URI
-- strings at the selected-root slash boundary.
local function map_uri_value(value, source_root, destination_root)
  if type(value) == 'string' then
    if value == source_root then
      return destination_root
    end
    local prefix = source_root .. '/'
    if value:sub(1, #prefix) == prefix then
      return destination_root .. value:sub(#source_root + 1)
    end
    return value
  end
  if type(value) ~= 'table' then
    return value
  end
  local mapped = {}
  for key, child in pairs(value) do
    mapped[key] = map_uri_value(child, source_root, destination_root)
  end
  return mapped
end

-- start_project_rpc keeps Neovim's host-side root ownership while presenting
-- only the fixed /project preopen and file:///project protocol root to the LSP.
local function start_project_rpc(command, dispatchers, root)
  local host_uri = vim.uri_from_fname(root)
  local translated_dispatchers = {
    notification = function(method, params)
      return dispatchers.notification(method, map_uri_value(params, guest_project_uri, host_uri))
    end,
    server_request = function(method, params)
      local result, err = dispatchers.server_request(method, map_uri_value(params, guest_project_uri, host_uri))
      return map_uri_value(result, host_uri, guest_project_uri), err
    end,
    on_error = dispatchers.on_error,
    on_exit = dispatchers.on_exit,
  }
  local rpc = vim.lsp.rpc.start(command, translated_dispatchers, { cwd = root })
  return {
    is_closing = rpc.is_closing,
    terminate = rpc.terminate,
    notify = function(method, params)
      local mapped = map_uri_value(params, host_uri, guest_project_uri)
      if method == 'initialized' then
        mapped = params
      end
      return rpc.notify(method, mapped)
    end,
    request = function(method, params, callback, notify_reply_callback)
      local mapped = map_uri_value(params, host_uri, guest_project_uri)
      if method == 'initialize' and mapped then
        mapped.rootPath = guest_project_path
      end
      return rpc.request(method, mapped, function(err, result, request_id)
        callback(err, map_uri_value(result, guest_project_uri, host_uri), request_id)
      end, notify_reply_callback)
    end,
  }
end

-- register_commands exposes status and restart lifecycle operations.
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
--- @param options table|nil Optional exact `{ lsp_wasm_path = '...', wasmtime_path = '...' }` overrides.
function M.setup(options)
  local version = vim.version()
  if version.major ~= 0 or version.minor ~= 12 then
    error('Pannonico requires Neovim 0.12.x')
  end
  options = options or {}
  local wasm = acquire_lsp(options)
  local wasmtime = acquire_wasmtime(options)
  local cache_config = wasmtime_cache_config()
  vim.lsp.config('pannonico', {
    cmd = function(dispatchers, config)
      local root = assert(config.root_dir, 'Pannonico LSP requires a marked project root')
      return start_project_rpc({
        wasmtime,
        'run',
        '-C',
        'cache=y',
        '-C',
        'cache-config=' .. cache_config,
        '--dir',
        root .. '::' .. guest_project_path,
        wasm,
      }, dispatchers, root)
    end,
    filetypes = { 'html', 'markdown', 'yaml', 'json' },
    -- Source discovery needs create/delete events as well as didSave. Use
    -- Neovim's native watcher lifecycle for this client on every supported host.
    capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } },
    root_markers = { '.pannonico', 'pannonico.yaml' },
  })
  register_commands()
  vim.lsp.enable('pannonico')
end

return M
