# Pannonico for Neovim

Pannonico supports Neovim 0.12 only. There is no compatibility support for
earlier or later Neovim generations and no dependency on `nvim-lspconfig` or
Mason.

Git and Neovim 0.12.5 are required. Add the newest immutable tag on the
supported `0.5.x` line through Neovim's built-in package manager in `init.lua`,
then configure it:

```lua
vim.pack.add({
  {
    src = 'https://github.com/vx-rs/pannonico-neovim',
    version = vim.version.range('0.5'),
  },
})

require('pannonico').setup()
```

Restart Neovim after the initial install. Create either `pannonico.yaml` or
`.pannonico` at the project root, then open an HTML or Markdown file below that
root. `:checkhealth vim.pack` diagnoses package installation, and
`:PannonicoStatus` reports whether the Pannonico LSP client started.

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

The local files must match the releases pinned by the plugin. Use
`:PannonicoStatus` and `:PannonicoRestart` for lifecycle diagnosis. Failed
managed downloads are errors; install `curl`, `tar`, and Git and rerun rather
than replacing the pinned URLs or checksums.

Wasmtime is not bundled or republished. Pannonico selects official Wasmtime
48.0.1 under `Apache-2.0 WITH LLVM-exception`; see
<https://github.com/bytecodealliance/wasmtime/releases/tag/v48.0.1>.

Report plugin issues at <https://github.com/vx-rs/pannonico-neovim/issues>.
Report suspected vulnerabilities privately at
<https://github.com/vx-rs/pannonico/security/advisories/new>.
