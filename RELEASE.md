# Neovim release

The initial release is `0.5.0`. Later Neovim-only changes increment the Neovim
patch version without forcing unrelated tracks to use the same patch number.

Every Pannonico LSP release requires a new Neovim plugin release:

## WSL/Linux x64 prerequisites

Install Neovim 0.12.5 once in a persistent user-local directory:

```sh
mkdir -p "$HOME/.local/opt/nvim-0.12.5" "$HOME/.local/bin"
curl -fL -o /tmp/nvim-linux-x86_64-0.12.5.tar.gz \
  https://github.com/neovim/neovim/releases/download/v0.12.5/nvim-linux-x86_64.tar.gz
tar -xzf /tmp/nvim-linux-x86_64-0.12.5.tar.gz --strip-components=1 \
  -C "$HOME/.local/opt/nvim-0.12.5"
ln -sfn "$HOME/.local/opt/nvim-0.12.5/bin/nvim" "$HOME/.local/bin/nvim"
```

Confirm that `~/.local/bin` is on `PATH`:

```sh
command -v nvim
nvim --version
```

If `command -v nvim` prints nothing, add this line once to `~/.zshrc`, open a
new shell, and repeat the checks:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Install the pinned Wasmtime 48.0.1 executable once, verify the downloaded
archive and extracted executable, and expose it through `~/.local/bin`:

```sh
mkdir -p "$HOME/.local/opt/wasmtime-48.0.1" "$HOME/.local/bin"
curl -fL -o /tmp/wasmtime-v48.0.1-x86_64-linux.tar.xz \
  https://github.com/bytecodealliance/wasmtime/releases/download/v48.0.1/wasmtime-v48.0.1-x86_64-linux.tar.xz
printf '%s  %s\n' \
  4c2e31b68ad99e0a519f225a261fda099eb15f056d4a24fdb3c2a46517bde1df \
  /tmp/wasmtime-v48.0.1-x86_64-linux.tar.xz | sha256sum -c -
tar -xJf /tmp/wasmtime-v48.0.1-x86_64-linux.tar.xz --strip-components=1 \
  -C "$HOME/.local/opt/wasmtime-48.0.1"
ln -sfn "$HOME/.local/opt/wasmtime-48.0.1/wasmtime" \
  "$HOME/.local/bin/wasmtime"
export PANNONICO_TEST_WASMTIME="$HOME/.local/opt/wasmtime-48.0.1/wasmtime"
printf '%s  %s\n' \
  5a61e28214e31c2a52154103407bae5265a36732b3af502609e5ffe19f249463 \
  "$PANNONICO_TEST_WASMTIME" | sha256sum -c -
wc -c "$PANNONICO_TEST_WASMTIME"
"$PANNONICO_TEST_WASMTIME" --version
```

The executable size printed by `wc -c` must be `70733544`. The release
acceptance requires `PANNONICO_TEST_WASMTIME` to name the versioned regular
file above, not the `~/.local/bin/wasmtime` symbolic link. Neovim resolves from
`PATH`; use `PANNONICO_NVIM` only as an override for a verified executable that
is not on `PATH`.

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
