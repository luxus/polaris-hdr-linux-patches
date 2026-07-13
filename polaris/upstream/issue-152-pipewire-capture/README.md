# Upstream: `perf/issue-152-pipewire-capture` rebased onto master

**Source branch:** [papi-ux/polaris `perf/issue-152-pipewire-capture`](https://github.com/papi-ux/polaris/tree/perf/issue-152-pipewire-capture)  
**Branch tip (historical):** `c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3`  
**Patch base (current master):** `2008458634c0d3f04f8abc39fab862bc69a47af8`  
**Rebased tip (local only):** cherry-picked 6 commits onto master; only conflict was `docs/changelog.md` (Unreleased + keep v1.3.1 section).

## What this is

Maintainer SDR-first PipeWire / portal DMA-BUF capture (same-GPU check, honest SHM fallback, residency logging). **Not** our experimental gist patches.

## Files

| Path | Use |
|------|-----|
| `combined.patch` | Single `git apply` / Nix `patches` on **master** @ `2008458` |
| `0001`…`0006-*.patch` | Same series as `git format-patch` (apply in order) |
| `0007-portal-assume-encoder-render-node-for-dmabuf.patch` | **PR candidate:** if PW omits capture render node, assume `adapter_name`. Needs `adapter_name = /dev/dri/renderD*`. |
| `0008-portal-dmabuf-and-direct-cuda-encode.patch` | **PR candidate:** (1) offer DmaBuf without SPA modifier; reinit on first DMA-BUF. (2) portal SHM direct RAM→CUDA + prefer 8-bit when client asks 10-bit. |

Verified: `git apply --check combined.patch` on a clean tree at master above.
`0007`+`0008` apply cleanly on top of `combined.patch` (in order).

## Nix

```nix
src = fetchFromGitHub {
  owner = "papi-ux";
  repo = "polaris";
  rev = "2008458634c0d3f04f8abc39fab862bc69a47af8"; # master
  hash = "sha256-e/nltRUAwZ/l6JtBti6uzumzY4zhiwQEA02oPat+7Jw=";
  fetchSubmodules = true;
};
patches = [
  ./combined.patch # or fetch from this repo
];
# Do NOT stack polaris/experimental/*
```

## Test matrix (papi-ux on #152)

1. Keep gamescope `gamescope/pipewire-prefer-dmabuf.patch`.
2. Drop `polaris/experimental/*`.
3. Master + this patch (or branch tip if you prefer).
4. Focus window active; log `render_node`, format/modifier, `capture_transport`, `frame_residency`.
