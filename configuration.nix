{ config, pkgs, inputs, ... }:

{
  # Hardware

  imports = [
    ./hardware-configuration.nix
  ];

  # Keep the newest kernel for timely security fixes.
  boot.kernelPackages = pkgs.linuxPackages_latest;


  # Bootloader

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };

  boot.loader.efi.canTouchEfiVariables = true;


  # Kernel Hardening

  boot.kernelParams = [
    # Heap/slab hardening
    "slab_nomerge"

    # Poison freed pages
    "page_poison=1"

    # Randomize page allocation
    "page_alloc.shuffle=1"

    # Disable debugfs
    "debugfs=off"
  ];

  security.protectKernelImage = true;

  boot.kernel.sysctl = {
    # Hide kernel pointers
    "kernel.kptr_restrict" = 2;

    # Restrict kernel logs to privileged users
    "kernel.dmesg_restrict" = 1;

    # Disable ftrace debugging
    "kernel.ftrace_enabled" = false;

    # Disable BPF JIT to reduce JIT spray attack surface
    "net.core.bpf_jit_enable" = false;

    # Reverse path filtering
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Ignore ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;

    # Never generate redirects
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;

    # Ignore broadcast ICMP echo requests
    "net.ipv4.icmp_echo_ignore_broadcasts" = true;

    # Log suspicious source addresses
    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.default.log_martians" = true;
  };


  # Networking

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";

    ensureProfiles.profiles."Wired connection 1" = {
      connection = {
        id = "Wired connection 1";
        type = "ethernet";
      };

      ipv4 = {
        method = "auto";
        ignore-auto-dns = true;
      };

      ipv6 = {
        method = "auto";
        ignore-auto-dns = true;
      };
    };
  };

  # Encrypted DNS

  services.resolved = {
    enable = true;

    settings.Resolve = {
      DNS = [
        "194.242.2.2#dns.mullvad.net"
        "2a07:e340::2#dns.mullvad.net"
      ];

      # DNSSEC = "true";
      DNSOverTLS = "true";

      # Route all normal DNS queries through Mullvad.
      Domains = [ "~." ];
    };
  };

  # Firewall

  networking.firewall = {
    enable = true;
  };

  networking.nftables.enable = true;

  # Firmware

  services.fwupd.enable = true;

  # Graphics

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Users

  users.users.ig = {
    isNormalUser = true;
    description = "ig";

    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Prevent root from being used as a normal login account.
  users.users.root.hashedPassword = "!";

  # Desktop

  programs.niri.enable = true;

  services.greetd = {
    enable = true;

    settings.default_session = {
      command = "${config.programs.niri.package}/bin/niri-session";
      user = "ig";
    };
  };

  systemd.user.services.niri.enableDefaultPath = false;

  # Audio

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Wayland Portals

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  # Removable Devices

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Flatpak

  services.flatpak.enable = true;

  # Core Dump Hardening

  systemd.coredump.enable = false;

  # Nix

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    auto-optimise-store = true;

    # Only members of the users group may access the daemon.
    allowed-users = [ "@users" ];
  };

  # Garbage Collection

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ZRAM

  zramSwap.enable = true;

  # Locale / Timezone

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

  # Fonts

  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
  ];

  # Applications

  environment.systemPackages = with pkgs; [
    # Wayland / X11
    xwayland-satellite
    wl-clipboard

    # Core
    curl
    wget
    git

    # Desktop
    alacritty
    neovim
    librewolf
    vesktop
    prismlauncher
    nautilus
    # blender
    obs-studio
    mpv
    # onlyoffice-desktopeditors
    ffmpeg

    # Development
    cargo
    gcc
    rust-analyzer
    rustc
    python3
    xxd

    # Themes
    adwaita-icon-theme

    # Noctalia
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Steam

  programs.steam.enable = true;

  # Unfree

  nixpkgs.config.allowUnfree = true;

  # State Version

  system.stateVersion = "26.05";
}
