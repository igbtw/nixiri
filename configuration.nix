{ config, pkgs, inputs, ... }:

{
  # Hardware
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

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # Secure DNS
  services.resolved = {
    enable = true;

    settings.Resolve = {
      DNS = [
        "1.1.1.1"
        "1.0.0.1"
      ];

      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
      ];

      DNSSEC = "true";
      DNSOverTLS = "true";
    };
  };

  # Firewall
  networking.firewall.enable = true;
  networking.nftables.enable = true;

  # Kernel hardening
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
  };

  # Firmware updates
  services.fwupd.enable = true;

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

  # Wayland portals
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  # Removable devices
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

    auto-optimise-store = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ZRAM
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

    # Themes and cursor
    adwaita-icon-theme

    # Noctalia
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Steam
  programs.steam.enable = true;

  # Proprietary packages
  nixpkgs.config.allowUnfree = true;

  # Installation baseline
  system.stateVersion = "26.05";
}
