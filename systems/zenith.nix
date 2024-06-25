{ config, pkgs, ... }:
{
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users = {
    dave = {
      isNormalUser = true;
      description = "Davey Caruso";
      extraGroups = [ "networkmanager" "wheel" "docker" "keyd" ];
    };

    cat.isNormalUser = true;
    cat90n.isNormalUser = true;
    catmarks.isNormalUser = true;
    catnos.isNormalUser = true;
    catdegrace.isNormalUser = true;
    catlina.isNormalUser = true;
    lino.isNormalUser = true;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  services = {
    openssh.enable = true;
    openssh.settings.X11Forwarding = true;

    ollama.enable = true;
  };
}

