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
