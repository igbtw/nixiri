# /etc/nixos/configuration.nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # Locale and timezone
  time.timeZone = "America/Sao_Paulo";

  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };
  };

  # Keyboard
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # User
  users.users.ig = {
    isNormalUser = true;
    description = "ig";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Desktop
  programs.niri.enable = true;

  # Display manager
  services.greetd = {
    enable = true;

    settings.default_session = {
      command = "${config.programs.niri.package}/bin/niri-session";
      user = "ig";
    };
  };

  # Niri session environment
  systemd.user.services.niri.enableDefaultPath = false;

  # Audio
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Desktop portals and removable devices
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Nix
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Avoid duplicate store paths when possible.
    auto-optimise-store = true;
  };

  # Periodically remove old generations/store paths.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ZRAM reduces the need for disk-backed swap.
  zramSwap.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    # Wayland / X11 compatibility
    xwayland-satellite
    wl-clipboard

    # Core utilities
    curl
    wget
    git

    # Desktop applications
    alacritty
    neovim
    librewolf
    vesktop
    prismlauncher
    nautilus
    onlyoffice-desktopeditors

    # Development
    cargo
    gcc
    go
    gopls
    rust-analyzer
    rustc

    # Theming / desktop integration
    adwaita-icon-theme

    # Noctalia
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Steam
  programs.steam.enable = true;

  # Allow proprietary packages.
  nixpkgs.config.allowUnfree = true;

  # Keep this at the version your installation was originally created with.
  system.stateVersion = "26.05";
}
