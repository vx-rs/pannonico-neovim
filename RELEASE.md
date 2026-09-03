# Neovim release

The initial release is `0.5.0`. Later Neovim-only changes increment the Neovim
patch version without forcing unrelated tracks to use the same patch number.

Every Pannonico LSP release requires a new Neovim plugin release:

## Prerequisites

Install [Neovim 0.12.5](https://github.com/neovim/neovim/releases/tag/v0.12.5)
and [Wasmtime 48.0.1](https://github.com/bytecodealliance/wasmtime/releases/tag/v48.0.1)
from their official release assets.
Neovim normally resolves from `PATH`; use `PANNONICO_NVIM` only for a verified
executable that is not on `PATH`. Select the versioned Wasmtime regular file,
not a convenience symbolic link:

```sh
export PANNONICO_TEST_WASMTIME="$HOME/.local/opt/wasmtime-48.0.1/wasmtime"
"${PANNONICO_NVIM:-nvim}" --version
"$PANNONICO_TEST_WASMTIME" --version
```

## Build and publish

```text
PANNONICO_TEST_WASMTIME="$HOME/.local/opt/wasmtime-48.0.1/wasmtime" \
npm run release:build -- neovim <plugin-version> <lsp-version>
npm run release:neovim -- <plugin-version>
```

The build command requires `tar`, builds the source-only candidate, and runs it
unchanged through the headless installed scenario. A failure retains
`failure.json` and process logs below `.local/test-results/neovim/runs/`; a
successful run removes its run directory.

Pannonico's canonical editor LSP is `pannonico-lsp.wasm`. This plugin executes
it through the repository-pinned, verified Wasmtime release and never resolves
a mutable latest runtime. When the runtime pin changes, update every host
archive identity, acquisition contract, protocol/editor/host acceptance, and
documentation together. A native Pannonico LSP fallback requires a separately
approved architecture change.

The release publishes the reviewed `pannonico-neovim` source commit and signed
tag. Neovim has no central marketplace or publisher account.

## Verify the public tag on Windows

After publication, verify that Neovim can resolve the new public tag through
the same `0.5` version range users install. Use an unused `NVIM_APPNAME` so the
check cannot reuse an existing plugin checkout or managed runtime:

```powershell
$env:NVIM_APPNAME = 'pannonico-release-readback'
$config = Join-Path $env:LOCALAPPDATA "$env:NVIM_APPNAME\init.lua"
New-Item -ItemType Directory -Force (Split-Path $config) | Out-Null
notepad $config
```

Put this configuration in the new `init.lua`:

```lua
vim.pack.add({
  {
    src = 'https://github.com/vx-rs/pannonico-neovim',
    version = vim.version.range('0.5'),
  },
})

require('pannonico').setup()
```

Start Neovim once and let the initial installation finish. Exit, start Neovim
again with the same `NVIM_APPNAME`, open an HTML or Markdown file in a project
containing `pannonico.yaml` or `.pannonico`, and run `:PannonicoStatus`. The
client must start from the public versioned checkout. Do not substitute a local
checkout, a branch, or rebuilt candidate files for this destination readback.

When the check is complete, clear the test setting in that PowerShell session:

```powershell
Remove-Item Env:NVIM_APPNAME
```
