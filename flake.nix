{
  description = "greetd greeter for Hyprland built on Quickshell, with the scottbass3-shell lock screen look";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # nixpkgs-style unstable version from the commit date: 0-unstable-YYYY-MM-DD
      date = self.lastModifiedDate or "19700101";
      version = "0-unstable-${builtins.substring 0 4 date}-${builtins.substring 4 2 date}-${builtins.substring 6 2 date}";

      mkPackage =
        pkgs:
        pkgs.callPackage ./nix/package.nix {
          src = self;
          inherit version;
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        scottbass3-greeter = mkPackage pkgs;
        default = scottbass3-greeter;
      });

      overlays.default = final: _prev: { scottbass3-greeter = mkPackage final; };

      nixosModules.default = import ./nix/module.nix self;

      # Evaluates the module in a minimal system, without building it.
      checks = forAllSystems (
        pkgs:
        let
          system = nixpkgs.lib.nixosSystem {
            inherit (pkgs.stdenv.hostPlatform) system;
            modules = [
              self.nixosModules.default
              {
                services.scottbass3-greeter.enable = true;
                services.xserver.xkb.layout = "fr";
                fileSystems."/" = {
                  device = "/dev/null";
                  fsType = "ext4";
                };
                boot.loader.grub.enable = false;
                system.stateVersion = "25.11";
              }
            ];
          };
          c = system.config;
        in
        {
          module = pkgs.writeText "scottbass3-greeter-module" ''
            ${c.services.greetd.settings.default_session.command}
            ${c.environment.etc."scottbass3-greeter/config.json".source}
            ${c.environment.etc."scottbass3-greeter/hyprland.lua".text}
            ${builtins.concatStringsSep "\n" c.systemd.tmpfiles.rules}
          '';
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
