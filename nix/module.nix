# NixOS module: services.scottbass3-greeter.enable = true;
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.scottbass3-greeter;
  json = pkgs.formats.json { };
  sessions = config.services.displayManager.sessionData.desktops;
  xkb = config.services.xserver.xkb;
  state = "/var/lib/scottbass3-greeter";
in
{
  options.services.scottbass3-greeter = {
    enable = lib.mkEnableOption "scottbass3-greeter, a greetd greeter built on Quickshell";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "scottbass3-greeter.packages.\${system}.default";
      description = "The greeter package.";
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      example = {
        wallpaper = "/etc/scottbass3-greeter/wallpaper.png";
        clock24h = true;
      };
      description = ''
        Written to /etc/scottbass3-greeter/config.json; the keys are listed in
        the README. sessionDirs defaults to the system's sessions.
      '';
    };

    extraHyprlandConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Lua loaded after the greeter's Hyprland config, e.g. to set monitors.
        The keyboard layout already follows services.xserver.xkb.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        # The greeter user's home isn't writable: keep the greeter's state
        # (last user and sessions) and cache in its own directory.
        command = "${pkgs.coreutils}/bin/env XDG_STATE_HOME=${state}/state XDG_CACHE_HOME=${state}/cache ${lib.getExe cfg.package}";
        user = "greeter";
      };
    };

    environment.etc."scottbass3-greeter/config.json".source = json.generate "scottbass3-greeter.json" (
      {
        sessionDirs = [
          "${sessions}/share/wayland-sessions"
          "${sessions}/share/xsessions"
        ];
      }
      // cfg.settings
    );

    environment.etc."scottbass3-greeter/hyprland.lua".text = ''
      hl.config({
          input = {
              kb_layout  = ${builtins.toJSON xkb.layout},
              kb_variant = ${builtins.toJSON xkb.variant},
              kb_options = ${builtins.toJSON xkb.options},
          },
      })
    ''
    + cfg.extraHyprlandConfig;

    # The shared directory users' shells sync their theme to, and the
    # greeter's own state.
    systemd.tmpfiles.packages = [ cfg.package ];
    systemd.tmpfiles.rules = [
      "d ${state}/state 0700 greeter greeter -"
      "d ${state}/cache 0700 greeter greeter -"
    ];

    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  };
}
