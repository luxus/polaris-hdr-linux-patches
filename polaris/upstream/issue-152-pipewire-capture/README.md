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
| `0009-portal-dmabuf-gl-import.patch` | (optional/archive) GL import retries; **not applied** — superseded by 0014 on NVIDIA. |
| `0010`…`0012` | Web session persist; portal HDR metadata; force-file gate. |
| `0013-portal-dmabuf-negotiate-diag.patch` | Diag: log `dmabuf_eligibility` / `dmabuf_negotiate`. |
| `0014-portal-dmabuf-linear-mmap-fallback.patch` | DmaBuf when may_use (LINEAR if SPA silent); EGL + mmap fallback. |
| `0015-portal-prefer-xbgr-210le.patch` | Prefer gamescope HDR **xBGR_210LE** (10-bit) over BGRx; XB30 + LINEAR offer. |

See `pkgs/polaris-stream/default.nix` for apply order (combined → 0007–0008 → 0010–0015; no 0009).
