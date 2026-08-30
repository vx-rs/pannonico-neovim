# Neovim release

The initial release is `0.5.0`. Later Neovim-only changes increment the Neovim
patch version without forcing unrelated tracks to use the same patch number.

Every Pannonico LSP release requires a new Neovim plugin release:

```text
npm run release:build -- neovim <plugin-version> <lsp-version>
npm run release:neovim -- <plugin-version>
```

The release publishes the reviewed `pannonico-neovim` source commit and signed
tag. Neovim has no central marketplace or publisher account.
