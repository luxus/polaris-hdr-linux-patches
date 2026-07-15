# gamescope HDR capture stack (polaris#152).
# enableWsi=true always: layer built; attach-only has been flaky — keep nested path available.
# Color A+B: 04 ColorMgmt LUTs + postPatch EOTF_PQ when HDR.
{ gamescope }:

(gamescope.override { enableWsi = true; }).overrideAttrs (old: {
  pname = "gamescope-hdr";

  patches = (old.patches or [ ]) ++ [
    ../../gamescope/01-pipewire-hdr-metadata.patch
    ../../gamescope/02-headless-hdr-colorimetry.patch
    # Prefer SPA_DATA_DmaBuf when the consumer allows it (GameStream zero-copy).
    ../../gamescope/03-pipewire-prefer-dmabuf.patch
    # A: IceDOS color-mgmt LUTs on PipeWire path.
    ../../gamescope/04-pipewire-color-mgmt.patch
  ];

  # B: IceDOS postPatch — encode PW capture as PQ when HDR output is on.
  # Pin SDR-on-HDR defaults to session-matching values (CLI can still override).
  # sdrGamutWideness=0, sdrContentNits=203 (BT.2408 reference white).
  postPatch =
    (old.postPatch or "")
    + ''
      substituteInPlace src/steamcompmgr.cpp \
        --replace-fail 'frameInfo.outputEncodingEOTF   = EOTF_Gamma22;' \
                       'frameInfo.outputEncodingEOTF   = g_bOutputHDREnabled ? EOTF_PQ : EOTF_Gamma22;' \
        --replace-fail '.displayColorimetry = displaycolorimetry_2020,' \
                       '.sdrGamutWideness = 0, .flSDROnHDRBrightness = 203, .displayColorimetry = displaycolorimetry_2020,'
    '';

  meta = old.meta // {
    description = "${
      old.meta.description or "gamescope"
    } (HDR PW metadata + WSI; ColorMgmt LUTs + EOTF_PQ paint_pipewire)";
  };
})
