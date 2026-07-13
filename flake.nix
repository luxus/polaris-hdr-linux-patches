{
  description = "Polaris + gamescope packages and patches for Linux HDR GameStream (polaris#152)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays.default = final: prev: {
        gamescope-hdr = final.callPackage ./pkgs/gamescope-hdr { };
        xdg-desktop-portal-gamescope = final.callPackage ./pkgs/xdg-desktop-portal-gamescope { };
        polaris-stream = final.callPackage ./pkgs/polaris-stream { };
        # Shell helper: source ${pkgs.polaris-nvidia-pin}/share/polaris/polaris-nvidia-pin.sh
        polaris-nvidia-pin = final.runCommand "polaris-nvidia-pin" { } ''
          mkdir -p $out/share/polaris
          cp ${./lib/polaris-nvidia-pin.sh} $out/share/polaris/polaris-nvidia-pin.sh
        '';
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs)
            gamescope-hdr
            xdg-desktop-portal-gamescope
            polaris-stream
            polaris-nvidia-pin
            ;
          default = pkgs.polaris-stream;
        }
      );

      # Overlay only — consumers own polaris.service / session units.
      nixosModules.default = {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
