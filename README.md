# Pannonico for Neovim

Pannonico supports Neovim 0.12 only. There is no compatibility support for
earlier or later Neovim generations and no dependency on `nvim-lspconfig` or
Mason.

## Install the prerequisites

Install Git and Neovim 0.12.5 before you add the plugin. Pannonico also uses
the platform download and archive commands listed below.

### Windows

Install Git and the supported Neovim release from PowerShell:

```powershell
winget install --exact --id Git.Git
winget install --exact --id Neovim.Neovim --version 0.12.5
```

Open a new terminal after installation, then verify Git, Neovim, Windows
PowerShell, and the Windows `tar` command:

```powershell
git --version
nvim --version
powershell.exe -NoProfile -Command '$PSVersionTable.PSVersion'
tar --version
```

The Neovim configuration file is
`%LOCALAPPDATA%\nvim\init.lua`, normally
`C:\Users\<username>\AppData\Local\nvim\init.lua`.

### macOS

Install Homebrew from <https://brew.sh> if it is not already installed. Then
install Git and Neovim:

```sh
brew install git neovim
```

Verify every required command:

```sh
git --version
nvim --version
curl --version
tar --version
```

The Neovim configuration file is `~/.config/nvim/init.lua`.

### Linux

On Debian, Ubuntu, or WSL, install the host commands first:

```sh
sudo apt-get update
sudo apt-get install -y git curl tar
```

Install the official Neovim 0.12.5 archive for the machine's architecture.
Use this block on x86-64:

```sh
curl --fail --location --remote-name \
  https://github.com/neovim/neovim/releases/download/v0.12.5/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
```

Use this block on ARM64 instead:

```sh
curl --fail --location --remote-name \
  https://github.com/neovim/neovim/releases/download/v0.12.5/nvim-linux-arm64.tar.gz
sudo tar -C /opt -xzf nvim-linux-arm64.tar.gz
sudo ln -sf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim
```

Verify every required command:

```sh
git --version
nvim --version
curl --version
tar --version
```

The Neovim configuration file is `~/.config/nvim/init.lua`.

## Install Pannonico

Add the newest immutable tag on the supported `0.5.x` line through Neovim's
built-in package manager, then configure the plugin:

```lua
vim.pack.add({
  {
    src = 'https://github.com/vx-rs/pannonico-neovim',
    version = vim.version.range('0.5'),
  },
})

require('pannonico').setup()
```

Restart Neovim after the initial install. On first setup, Pannonico downloads
and verifies its pinned LSP WASM and Wasmtime runtime. Run
`:checkhealth vim.pack` to diagnose package installation.

Create either `pannonico.yaml` or `.pannonico` at the project root. Open an
HTML or Markdown file below that root, then run `:PannonicoStatus` to confirm
that the Pannonico LSP client started.

## Runtime management

The adapter downloads the exact pinned `pannonico-lsp.wasm` and official
Wasmtime 48.0.1 archive with `curl` on macOS/Linux or PowerShell on Windows. It
verifies each archive and selected executable by byte length and SHA-256,
extracts only the expected runtime member with `tar`, and enables Neovim's
built-in LSP client for HTML and Markdown. Runtime files stay in Neovim's data
directory; Wasmtime's compilation cache stays in Neovim's cache directory.

A separate Wasmtime installation is not required. Pannonico does not select a
`wasmtime` executable from `PATH`; it uses the downloaded and verified 48.0.1
runtime unless an exact local override is configured. If another Wasmtime
version is already installed, it can remain on the machine. You do not need to
downgrade or remove it.

For offline use on macOS or Linux, both local files must exactly match the
plugin pins:

```lua
require('pannonico').setup({
  lsp_wasm_path = '/absolute/path/to/pannonico-lsp.wasm',
  wasmtime_path = '/absolute/path/to/wasmtime',
})
```

Use Windows long-bracket strings for Windows paths:

```lua
require('pannonico').setup({
  lsp_wasm_path = [[C:\absolute\path\to\pannonico-lsp.wasm]],
  wasmtime_path = [[C:\absolute\path\to\wasmtime.exe]],
})
```

The local files must match the releases pinned by the plugin. Use
`:PannonicoStatus` and `:PannonicoRestart` for lifecycle diagnosis. Failed
managed downloads are errors. Verify the download and archive commands listed
for the host above, then rerun rather than replacing the pinned URLs or
checksums.

Wasmtime is not bundled or republished. Pannonico selects official Wasmtime
48.0.1 under `Apache-2.0 WITH LLVM-exception`; see
<https://github.com/bytecodealliance/wasmtime/releases/tag/v48.0.1>.

Report plugin issues at <https://github.com/vx-rs/pannonico-neovim/issues>.
Report suspected vulnerabilities privately at
<https://github.com/vx-rs/pannonico/security/advisories/new>.
