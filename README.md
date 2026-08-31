# Pannonico for Neovim

Pannonico supports Neovim 0.12 only. There is no compatibility support for
earlier or later Neovim generations and no dependency on `nvim-lspconfig` or
Mason.

Install this Git repository with your plugin manager, then configure it:

```lua
require('pannonico').setup()
```

The adapter downloads the exact pinned `pannonico-lsp.wasm` and official
Wasmtime 48.0.1 archive with `curl` on macOS/Linux or PowerShell on Windows. It
verifies each archive and selected executable by byte length and SHA-256,
extracts only the expected runtime member with `tar`, and enables Neovim's
built-in LSP client for HTML and Markdown. Runtime files stay in Neovim's data
directory; Wasmtime's compilation cache stays in Neovim's cache directory.

For offline use, both local files must exactly match the plugin pins:

```lua
require('pannonico').setup({
  lsp_wasm_path = '/absolute/path/to/pannonico-lsp.wasm',
  wasmtime_path = '/absolute/path/to/wasmtime',
})
```

The local file must match the release pinned by the plugin. Use
`:PannonicoStatus` and `:PannonicoRestart` for lifecycle diagnosis.

Wasmtime is not bundled or republished. Pannonico selects official Wasmtime
48.0.1 under `Apache-2.0 WITH LLVM-exception`; see
<https://github.com/bytecodealliance/wasmtime/releases/tag/v48.0.1>.

Report plugin issues at <https://github.com/vx-rs/pannonico-neovim/issues>.
Report suspected vulnerabilities privately at
<https://github.com/vx-rs/pannonico/security/advisories/new>.
