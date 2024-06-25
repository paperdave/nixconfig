{ config, pkgs, lib, user, inputs, ... }:
let
  homeDir = "/home/${user.username}";
  configDir = "${homeDir}/${user.config}";
  scriptsDir = "${configDir}/scripts";
in
{
  imports = [
    inputs.stylix.homeManagerModules.stylix
    ./modules/home-manager/sxhkd.nix
  ];

  home.username = user.username;
  home.homeDirectory = homeDir;
  home.stateVersion = "24.05";
  home.packages = [
    # sort-lines: start
    pkgs.mpv
    pkgs.coreutils
    pkgs.dolphin
    pkgs.ffmpeg
    pkgs.btop
    pkgs.clang_16
    pkgs.curl
    pkgs.davinci-resolve-studio
    pkgs.dconf
    pkgs.flameshot
    pkgs.git
    pkgs.hsetroot
    pkgs.htop
    pkgs.hyfetch
    pkgs.lld_16
    pkgs.neovim
    pkgs.picom
    pkgs.rofi
    pkgs.tree
    pkgs.wget
    pkgs.xclip
    pkgs.keyd
    pkgs.nixpkgs-fmt
    # sort-lines:end

    inputs.blender-bin.packages.x86_64-linux.blender_4_1

    (pkgs.callPackage ./packages/fusion-studio.nix { })
  ];

  home.file = {
    ".config/ghostty/config".text = ''
      theme = catppuccin-mocha
      scrollback-limit = 100000000
      window-decoration = false
      gtk-titlebar = false
    '';

    # Colorset Convention
    #
    #   0 - Default
    #   1 - Inactive Windows
    #   2 - Active Window
    #   3 - Inactive Windows Borders
    #   4 - Active Windows Borders
    #   5 - Menu - Inactive Item
    #   6 - Menu - Active Item
    #   7 - Menu - Grayed Item
    #   8 - Menu - Title
    #   9 - Reserved
    #  10+ Modules
    #      10 - Module Default
    #      11 - Module Hilight
    #      12 - Module ActiveButton (Mouse Hover)
    #      13 - FvwmPager Active Page
    #      14 - FvwmIconMan Iconified Button
    ".fvwm/generated-style".text =
      let
        c = config.lib.stylix.colors;
      in
      ''
        Colorset 0  fg #${c.base05}, bg #${c.base00}, hi, sh, Plain, NoShape
        Colorset 1  fg #${c.base05}, bg #${c.base00}, hi, sh, Plain, NoShape
        Colorset 2  fg #${c.base0A}, bg #${c.base04}, hi, sh, Plain, NoShape
        Colorset 3  fg black, bg #4d4d4d, hi #676767, sh #303030, Plain, NoShape
        Colorset 4  fg black, bg #2d2d2d, hi #474747, sh #101010, Plain, NoShape
        Colorset 5  fg #000000, bg #ffffff, hi, sh, Plain, NoShape
        Colorset 6  fg #ffffff, bg #2d2d2d, hi, sh, Plain, NoShape
        Colorset 7  fg grey30, bg #ffffff, hi, sh, Plain, NoShape
        Colorset 8  fg #ffffff, bg #003c3c, hi, sh, Plain, NoShape
        Colorset 10 fg #ffffff, bg #003c3c, hi #aaaaaa, sh #999999, Plain, NoShape
        Colorset 11 fg #ffffff, bg #1a6e99, hi #ffffff, sh #ffffff, Plain, NoShape
        Colorset 12 fg #2d2d2d, bg #ffffff, hi, sh, Plain, NoShape
        Colorset 13 fg #ffffff, bg #006c6c, hi, sh, Plain, NoShape
        Colorset 14 fg #555555, bg #003c3c, hi #aaaaaa, sh #999999, Plain, NoShape
      '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
  programs.firefox.enable = true;
  programs.git = {
    enable = true;
    userName = user.name;
    userEmail = user.email;
  };

  services.picom = {
    enable = true;
    backend = "glx";
    shadow = true;
  };

  services.sxhkd = {
    enable = true;
    keybindings = {
      "Print" = "${scriptsDir}/capture-image.sh";
    };
  };

  stylix = {
    enable = true;
    image = ./res/THE_PAPER.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };
}
