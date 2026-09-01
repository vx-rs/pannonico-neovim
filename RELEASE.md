# Neovim release

The initial release is `0.5.0`. Later Neovim-only changes increment the Neovim
patch version without forcing unrelated tracks to use the same patch number.

Every Pannonico LSP release requires a new Neovim plugin release:

```text
npm run release:build -- neovim <plugin-version> <lsp-version>
npm run release:neovim -- <plugin-version>
```

The build command requires Neovim 0.12, `tar`, and
`PANNONICO_TEST_WASMTIME` pointing to the exact host executable pinned in
`scripts/wasmtime-release.json`. It builds the source-only candidate and runs
the candidate unchanged through the headless installed scenario. A failure
retains `failure.json` and process logs below
`.local/test-results/neovim/runs/`; a successful run removes its run directory.

Pannonico's canonical editor LSP is `pannonico-lsp.wasm`. This plugin executes
it through the repository-pinned, verified Wasmtime release and never resolves
a mutable latest runtime. When the runtime pin changes, update every host
archive identity, acquisition contract, protocol/editor/host acceptance, and
documentation together. A native Pannonico LSP fallback requires a separately
approved architecture change.

The release publishes the reviewed `pannonico-neovim` source commit and signed
tag. Neovim has no central marketplace or publisher account.
