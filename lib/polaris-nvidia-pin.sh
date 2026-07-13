# Dual-GPU pin for Polaris / gamescope / labwc (source from bash wrappers).
# Prefer NVIDIA dGPU for capture + NVENC so DmaBuf and encode share one device.
# Common on hybrid boxes (RTX + Raphael/Rembrandt iGPU). No-op if no NVIDIA DRM.
#
# Exports (when NVIDIA found):
#   WLR_RENDER_DRM_DEVICE, WLR_DRM_DEVICES (labwc/wlroots)
#   POLARIS_NVIDIA_RENDER_NODE, POLARIS_NVIDIA_VK_DEVICE (gamescope --prefer-vk-device)
#   VK_ICD_FILENAMES, __GLX_VENDOR_LIBRARY_NAME, __EGL_VENDOR_LIBRARY_FILENAMES
#
# Escape: POLARIS_PORTAL_DMABUF=0 still forces portal CPU path (portal_grab).

polaris_pin_nvidia_gpu() {
  local rend sys vend dev card cards="" node="" vk="" egl="" icd=""

  # Already set by admin → respect.
  if [ -n "${WLR_RENDER_DRM_DEVICE:-}" ] && [ -n "${POLARIS_NVIDIA_VK_DEVICE:-}" ]; then
    return 0
  fi

  for rend in /dev/dri/renderD*; do
    [ -e "$rend" ] || continue
    sys="/sys/class/drm/$(basename "$rend")/device"
    [ -r "$sys/vendor" ] || continue
    vend=$(cat "$sys/vendor" 2>/dev/null || true)
    dev=$(cat "$sys/device" 2>/dev/null || true)
    if [ "$vend" = "0x10de" ]; then
      node="$rend"
      # gamescope --prefer-vk-device wants 10de:2684 (no 0x on product)
      vk="10de:${dev#0x}"
      break
    fi
  done

  if [ -z "$node" ]; then
    return 0
  fi

  export POLARIS_NVIDIA_RENDER_NODE="$node"
  export POLARIS_NVIDIA_VK_DEVICE="$vk"
  export WLR_RENDER_DRM_DEVICE="${WLR_RENDER_DRM_DEVICE:-$node}"

  # Prefer NVIDIA card first in multi-card lists (cardN linked from same PCI device).
  for card in /dev/dri/card*; do
    [ -e "$card" ] || continue
    sys="/sys/class/drm/$(basename "$card")/device"
    [ -r "$sys/vendor" ] || continue
    vend=$(cat "$sys/vendor" 2>/dev/null || true)
    if [ "$vend" = "0x10de" ]; then
      cards="${cards:+$cards:}$card"
    fi
  done
  for card in /dev/dri/card*; do
    [ -e "$card" ] || continue
    sys="/sys/class/drm/$(basename "$card")/device"
    [ -r "$sys/vendor" ] || continue
    vend=$(cat "$sys/vendor" 2>/dev/null || true)
    if [ "$vend" != "0x10de" ]; then
      cards="${cards:+$cards:}$card"
    fi
  done
  if [ -n "$cards" ]; then
    export WLR_DRM_DEVICES="${WLR_DRM_DEVICES:-$cards}"
  fi

  for icd in \
    /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json \
    /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json; do
    if [ -f "$icd" ]; then
      export VK_ICD_FILENAMES="$icd"
      break
    fi
  done

  export __GLX_VENDOR_LIBRARY_NAME="${__GLX_VENDOR_LIBRARY_NAME:-nvidia}"

  for egl in \
    /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json \
    /run/opengl-driver/share/glvnd/egl_vendor.d/nvidia.json; do
    if [ -f "$egl" ]; then
      export __EGL_VENDOR_LIBRARY_FILENAMES="$egl"
      break
    fi
  done
}
