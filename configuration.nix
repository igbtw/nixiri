{ config, lib, pkgs, inputs, ... }:

{
  # Hardware

  imports = [
    ./hardware-configuration.nix
  ];

  # Keep the newest kernel for timely security fixes.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader

  boot.loader = {
    systemd-boot = {
        enable = true;
        configurationLimit = 5;
    };
    # No boot menu countdown
    timeout = 0;
  };

  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel Hardening

  # Prefer the kernel selected by your NixOS channel.
  # Remove boot.kernelPackages = pkgs.linuxPackages_latest;
  # unless you specifically need it.

  boot.kernelParams = [
    "slab_nomerge"
    "page_alloc.shuffle=1"
    "debugfs=off"
    "ima_policy=tcb"

    # Optional: stronger page-poisoning protection.
    "page_poison=1"
  ];

  security.protectKernelImage = true;

  boot.kernel.sysctl = {
    # Kernel Swappiness (32GiB = 5 ~ 30; 16GiB = 30 ~ 60; 60 is the normal)
    "vm.swappiness" = 60;

    # Restrict information leaks.
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;

    # Disable unprivileged BPF instead of disabling BPF JIT globally.
    "kernel.unprivileged_bpf_disabled" = 1;

    # Limit ptrace access while retaining ordinary parent/child debugging.
    "kernel.yama.ptrace_scope" = 1;

    # Filesystem hardening
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 1;
    "fs.protected_regular" = 1;

    # Network filtering.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;

    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;

    "net.ipv4.icmp_echo_ignore_broadcasts" = true;

    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.default.log_martians" = true;

    # Reject IP source routing
    "net.ipv4.conf.all.accept_source_route" = false;
    "net.ipv4.conf.default.accept_source_route" = false;

    "net.ipv6.conf.all.accept_source_route" = -1;
    "net.ipv6.conf.default.accept_source_route" = -1;
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

      ethernet.cloned-mac-address = "random";

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

  # To DISEABLE Wifi!
  networking.wireless.enable = lib.mkForce false;

  # I2Pd private networking

  services.i2pd = {
    enable = true;

    settings = {
      http = {
        enabled = false;
      };

      httpproxy = {
        address = "127.0.0.1";
        port = 4444;
        enabled = true;
      };

      socksproxy = {
        address = "127.0.0.1";
        port = 4447;
        enabled = true;
      };
    };
  };

  systemd.services.i2pd.serviceConfig = {
    # Files created by i2pd are private by default.
    UMask = "0077";

    # The daemon does not need Linux capabilities.
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";

    # Prevent the daemon from creating additional namespaces.
    RestrictNamespaces = true;
  };

  # Do not start i2pd automatically.
  systemd.services.i2pd.wantedBy = lib.mkForce [];

  # Encrypted DNS

  services.resolved = {
    enable = true;

    settings.Resolve = {
      DNS = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
        "2620:fe::fe#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
      ];

      DNSSEC = "true";
      DNSOverTLS = "true";

      # Route all normal DNS queries through Quad9.
      Domains = [ "~." ];

      LLMNR = "false";
      MulticastDNS = "false";
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
      "libvirtd" # for the virtualisation
      "networkmanager"
      "wheel"
    ];
  };

  # Prevent root from being used as a normal login account.
  users.users.root.hashedPassword = "!";

  # Keep sudo authentication enabled for wheel.
  security.sudo = {
    wheelNeedsPassword = true;

    extraConfig = ''
      Defaults use_pty
      Defaults timestamp_timeout=5
    '';
};

  # Virtualisation
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Desktop

  programs.niri.enable = true;

  # Display manager

  services.displayManager.ly = {
    enable = true;

    # This machine uses Niri/Wayland, not X11 desktop sessions.
    # This does not disable XWayland support inside Niri.
    x11Support = false;
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

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    config.niri = {
      default = [ "gnome" "gtk" ];

      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };


  # Removable Devices

  services.gvfs = {
    enable = true;

    package = pkgs.gnome.gvfs.override {
      udevSupport = true;
      gnomeSupport = false;
      samba = null;
      avahi = null;
    };
  };

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

    # Only your normal account needs ordinary daemon access.
    allowed-users = [ "ig" ];

    # Avoid deduplication work on every store-path addition.
    auto-optimise-store = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.sandbox = true;


  # App Armor (WIP)

  # security.apparmor = {
  #   enable = true;
  #
  #   policies = {
  #   };
  # };

  # ZRAM

  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "lz4";
    memoryPercent = 50;
  };

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
    git

    # Desktop
    alacritty
    neovim
    librewolf
    vesktop
    element-desktop
    prismlauncher
    nautilus
    mpv
    # obs-studio
    # onlyoffice-desktopeditors

    # Development
    cargo
    rust-analyzer
    rustc
    gcc

    # Themes
    adwaita-icon-theme

    # Noctalia
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Bash config

  programs.bash = {
    shellAliases = {
      l = "ls -alh";
      ll = "ls -l";
      ls = "ls --color=tty";
      nv = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      update = "sudo nix flake update";
      update-rebuild = "sudo nix flake update && sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      clean = "sudo nix store gc && sudo nix store optimise";
    };
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Steam

  programs.steam.enable = true;

  # Unfree

  nixpkgs.config.allowUnfree = true;

  # State Version

  system.stateVersion = "26.05";
}
