# Upstream: `perf/issue-152-pipewire-capture` rebased onto master

**Source branch:** [papi-ux/polaris `perf/issue-152-pipewire-capture`](https://github.com/papi-ux/polaris/tree/perf/issue-152-pipewire-capture)  
**Branch tip (historical):** `c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3`  
**Patch base (current master):** `2008458634c0d3f04f8abc39fab862bc69a47af8`  
**Rebased tip (local only):** cherry-picked 6 commits onto master; only conflict was `docs/changelog.md` (Unreleased + keep v1.3.1 section).

## What this is

Maintainer SDR-first PipeWire / portal DMA-BUF capture (same-GPU check, honest SHM fallback, residency logging), plus local follow-ups that made **gamescope portal video work** on lea.

## Files

| Path | Use |
|------|-----|
| `combined.patch` | Single `git apply` / Nix `patches` on **master** @ `2008458` (= 0001…0006) |
| `0001`…`0006-*.patch` | Same series as `git format-patch` (apply in order) |
| `0007-portal-assume-encoder-render-node-for-dmabuf.patch` | If PW omits capture render node, assume `adapter_name` for same-GPU eligibility. Needs `adapter_name = /dev/dri/renderD*`. |
| `0008-portal-dmabuf-and-direct-cuda-encode.patch` | **Portal SHM → CUDA NV12 + prefer_8bit** when client asks 10-bit (fallback when DMA-BUF import fails). |
| `0009-portal-dmabuf-gl-import.patch` | Re-offer DmaBuf without SPA modifier (no reinit thrash) + **GL import retries** (LINEAR/fourcc flip/`EGL_IMAGE_PRESERVED`) for gamescope linear BGRx on NVIDIA. |

Apply order in `pkgs/polaris-stream/default.nix`:

```nix
patches = [
  ../../polaris/upstream/issue-152-pipewire-capture/combined.patch
  ../../polaris/upstream/issue-152-pipewire-capture/0007-portal-assume-encoder-render-node-for-dmabuf.patch
  ../../polaris/upstream/issue-152-pipewire-capture/0008-portal-dmabuf-and-direct-cuda-encode.patch
  ../../polaris/upstream/issue-152-pipewire-capture/0009-portal-dmabuf-gl-import.patch
];
```

## Known-good host pairing (luxusAi)

- Idle gamescope: `--hdr-enabled --hdr-debug-force-output --hdr-debug-force-support` + paper-white nits (module `polaris-hdr-session`).
- Capture: portal + gamescope ScreenCast (`polaris-hdr-use-portal`).
- Expect web UI: encode CUDA/GPU/NV12, copy CPU (SHM) until DMA-BUF import is fixed.

## Nix

```nix
src = fetchFromGitHub {
  owner = "papi-ux";
  repo = "polaris";
  rev = "2008458634c0d3f04f8abc39fab862bc69a47af8"; # master
  hash = "sha256-e/nltRUAwZ/l6JtBti6uzumzY4zhiwQEA02oPat+7Jw=";
  fetchSubmodules = true;
};
# Do NOT stack polaris/experimental/*
```

Verified: `git apply --check combined.patch` on a clean tree at master above.
`0007`+`0008` apply cleanly on top of `combined.patch` (in order).
| `0013-portal-dmabuf-negotiate-diag.patch` | **Diag only**: log `dmabuf_eligibility` + `dmabuf_negotiate` (SHM vs DMA-BUF why). |
| `0014-portal-dmabuf-linear-mmap-fallback.patch` | **DMA-BUF**: offer when may_use (LINEAR if SPA silent); TexStorageEXT+LINEAR import; mmap fallback; `POLARIS_PORTAL_DMABUF=0` escape. |
