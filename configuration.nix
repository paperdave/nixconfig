# This is the global system configuration, shared between all systems.
{ config, pkgs, hostname, inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix
    ./modules/nixos/ly.nix
    ./modules/nixos/keyd.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  services = {
    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          capslock = "overload(control, esc)";
          insert = "S-insert";
        };
      };
    };

    # FVWM is my window manager of choice.
    # to properly log in, this needs to be system-wide
    xserver = {
      enable = true;
      windowManager.fvwm3.enable = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    displayManager.sddm = {
      enable = true;
    };

    printing.enable = true;
    openssh.enable = true;
    openssh.settings.X11Forwarding = true;

    udev.extraRules = ''
      # BMD hardware (such as Speed Editor)
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1edb", MODE="0666"
      # Fusion Activation Dongle
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="096e", MODE="0666"
    '';

  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  users.defaultUserShell = pkgs.fish;

  environment.systemPackages = [ pkgs.home-manager ];

  environment.variables = {
    CUDA_PATH = pkgs.cudatoolkit;
    EXTRA_LDFLAGS = "-L${pkgs.cudatoolkit}/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I${pkgs.cudatoolkit}/usr/include";
  };

  programs = {
    fish.enable = true;

    ssh.forwardX11 = true;

    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    nix-ld = {
      enable = true;
      libraries = [
        pkgs.stdenv.cc.cc.lib

        # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L72-L79
        pkgs.xorg.libXcomposite
        pkgs.xorg.libXtst
        pkgs.xorg.libXrandr
        pkgs.xorg.libXext
        pkgs.xorg.libX11
        pkgs.xorg.libXfixes
        pkgs.libGL
        pkgs.libva

        # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L124-L136
        pkgs.fontconfig
        pkgs.freetype
        pkgs.xorg.libXt
        pkgs.xorg.libXmu
        pkgs.libogg
        pkgs.libvorbis
        pkgs.SDL
        pkgs.SDL2_image
        pkgs.glew110
        pkgs.libdrm
        pkgs.libidn
        pkgs.tbb
        pkgs.zlib
        pkgs.alsa-lib
        pkgs.at-spi2-atk
        pkgs.at-spi2-core
        pkgs.atk
        pkgs.cairo
        pkgs.cups
        pkgs.curl
        pkgs.dbus
        pkgs.expat
        pkgs.fontconfig
        pkgs.freetype
        pkgs.fuse3
        pkgs.gdk-pixbuf
        pkgs.glib
        pkgs.gtk3
        pkgs.icu
        pkgs.libappindicator-gtk3
        pkgs.libdrm
        pkgs.libglvnd
        pkgs.libnotify
        pkgs.libpulseaudio
        pkgs.libunwind
        pkgs.libusb1
        pkgs.libuuid
        pkgs.libxkbcommon
        pkgs.libxml2
        pkgs.mesa
        pkgs.nspr
        pkgs.nss
        pkgs.openssl
        pkgs.pango
        pkgs.pipewire
        pkgs.systemd
        pkgs.vulkan-loader
        pkgs.xorg.libXScrnSaver
        pkgs.xorg.libXcursor
        pkgs.xorg.libXdamage
        pkgs.xorg.libXi
        pkgs.xorg.libXrender
        pkgs.xorg.libxcb
        pkgs.xorg.libxkbfile
        pkgs.xorg.libxshmfence
        pkgs.zlib

        pkgs.libGLU
      ];
    };
  };

  system.stateVersion = "24.05";
}
