# The built in one to home-manager does not use a systemd service therefore, it
# does not guarentee execution of the program. This behavior was unfortunately
# removed in https://github.com/nix-community/home-manager/pull/1892
#
# This change uses a nix anti-pattern: Inheriting the user's profile. Ideally
# all keybindings and scripts can be perfectly described using the Nix build
# system, reality proves that to be annoying, verbose, and a waste of my time.
{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkEnableOption mkIf;
  cfg = config.services.sxhkd;

  keybindingsStr = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (hotkey: command:
      lib.optionalString (command != null) ''
        ${hotkey}
          ${command}
      '')
    cfg.keybindings);
in
{
  disabledModules = [ "services/sxhkd.nix" ];

  options.services.sxhkd = {
    enable = mkEnableOption "simple X hotkey daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.sxhkd;
      defaultText = "pkgs.sxhkd";
      description = "Package containing the {command}`sxhkd` executable.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Command line arguments to invoke {command}`sxhkd` with.";
      example = lib.literalExpression ''[ "-m 1" ]'';
    };

    keybindings = mkOption {
      type =
        types.attrsOf (types.nullOr (types.oneOf [ types.str types.path ]));
      default = { };
      description = "An attribute set that assigns hotkeys to commands.";
      example = lib.literalExpression ''
        {
          "super + shift + {r,c}" = "i3-msg {restart,reload}";
          "super + {s,w}"         = "i3-msg {stacking,tabbed}";
          "super + F1"            = pkgs.writeShellScript "script" "echo $USER";
        }
      '';
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
      example = lib.literalExpression ''
        super + {_,shift +} {1-9,0}
          i3-msg {workspace,move container to workspace} {1-10}
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.sxhkd" pkgs
        lib.platforms.linux)
    ];

    xdg.configFile."sxhkd/sxhkdrc".text = lib.concatStringsSep "\n" [
      keybindingsStr
      cfg.extraConfig
    ];

    systemd.user.services.sxhkd = {
      Unit = {
        Description = "Simple X Hot Key Daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = "${pkgs.bash}/bin/bash ${pkgs.writeScript "sxhkd-wrapper" ''
            # Hack to make environment sync up
            export PATH="${config.home.profileDirectory}/bin:$PATH"

            exec ${lib.escapeShellArgs ([
                (lib.getExe cfg.package)
                "-c" 
                "${config.xdg.configFile."sxhkd/sxhkdrc".source}"
            ] ++ cfg.extraArgs)}
        ''}";

        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
