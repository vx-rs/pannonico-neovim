# Pannonico for Neovim

Pannonico supports Neovim 0.12 only. There is no compatibility support for
Neovim earlier than 0.12 and no dependency on `nvim-lspconfig` or Mason.

Install this Git repository with your plugin manager, then configure it:

```lua
require('pannonico').setup()
```

The adapter downloads the exact native Pannonico LSP with `curl` on macOS and
Linux or PowerShell on Windows. It verifies the byte length, SHA-256, and native
executable format before enabling the built-in LSP configuration for HTML and
Markdown. For offline use:

```lua
require('pannonico').setup({ lsp_path = '/absolute/path/to/pannonico-lsp' })
```

The local file must match the release pinned by the plugin. Use
`:PannonicoStatus` and `:PannonicoRestart` for lifecycle diagnosis.

Report plugin issues at <https://github.com/vx-rs/pannonico-neovim/issues>.
Report suspected vulnerabilities privately at
<https://github.com/vx-rs/pannonico/security/advisories/new>.
