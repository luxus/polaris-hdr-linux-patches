# gamescope with IceDOS/Jovian-oriented HDR PipeWire metadata patches
# (https://github.com/papi-ux/polaris/issues/152). Opt-in for HDR headless sessions.
{ gamescope }:

gamescope.overrideAttrs (old: {
  pname = "gamescope-hdr";

  patches = (old.patches or [ ]) ++ [
    ../../gamescope/pipewire-hdr-metadata.patch
    ../../gamescope/headless-hdr-colorimetry.patch
    ../../gamescope/pipewire-color-mgmt.patch
    # Prefer SPA_DATA_DmaBuf when the consumer allows it (GameStream zero-copy).
    ../../gamescope/pipewire-prefer-dmabuf.patch
  ];

  # PipeWire path: PQ encode only when HDR output is on (runtime; not static const).
  # SDR headless colorimetry is handled in headless-hdr-colorimetry.patch (SetHDR false).
  postPatch = (old.postPatch or "") + ''
    if grep -q 'frameInfo.outputEncodingEOTF   = EOTF_Gamma22;' src/steamcompmgr.cpp; then
      substituteInPlace src/steamcompmgr.cpp \
        --replace-fail 'frameInfo.outputEncodingEOTF   = EOTF_Gamma22;' \
                       'frameInfo.outputEncodingEOTF   = g_bOutputHDREnabled ? EOTF_PQ : EOTF_Gamma22;'
    fi
    if grep -q '.displayColorimetry = displaycolorimetry_2020,' src/steamcompmgr.cpp; then
      substituteInPlace src/steamcompmgr.cpp \
        --replace-fail '.displayColorimetry = displaycolorimetry_2020,' \
                       '.sdrGamutWideness = 0, .flSDROnHDRBrightness = 203, .displayColorimetry = displaycolorimetry_2020,'
    fi
  '';

  meta = old.meta // {
    description = "${
      old.meta.description or "gamescope"
    } (HDR PipeWire metadata patches for polaris/gamescope headless)";
  };
})
