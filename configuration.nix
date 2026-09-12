{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ----------------------------------------------------------
  # Boot
  # ----------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ----------------------------------------------------------
  # Networking
  # ----------------------------------------------------------
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # ----------------------------------------------------------
  # Locale / Time
  # ----------------------------------------------------------
  time.timeZone = "Asia/Tehran";
  i18n.defaultLocale = "en_US.UTF-8";

  # ----------------------------------------------------------
  # User
  # ----------------------------------------------------------
  users.users.sadra = {
    isNormalUser = true;

    shell = pkgs.zsh;

    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
  };

  # ----------------------------------------------------------
  # Unfree
  # ----------------------------------------------------------
  nixpkgs.config = {
    allowUnfree = true;

    permittedInsecurePackages = [
      "libsoup-2.74.3"
    ];
  };

  # ----------------------------------------------------------
  # NVIDIA RTX Laptop
  # ----------------------------------------------------------
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    modesetting.enable = true;

    powerManagement.enable = true;

    nvidiaSettings = true;

    open = true;
  };

  
  hardware.nvidia.prime = {
    intelBusId = "PCI:0@0:2:0";
    nvidiaBusId = "PCI:1@0:0:0";

    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
  };

  boot = {
    blacklistedKernelModules = [ "nouveau" ];

    kernelParams = [
      "nvidia-drm.modeset=1"
    ];
  };

  # ----------------------------------------------------------
  # Environment / Wayland / Dark Theme
  # ----------------------------------------------------------
  environment.sessionVariables = {

    # Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # GTK
    GTK_THEME = "Adwaita:dark";

    # Qt
    QT_QPA_PLATFORMTHEME = "gnome";
    QT_STYLE_OVERRIDE = "adwaita-dark";

    # NVIDIA
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_SYNC_DISPLAY_DEVICE = "eDP-1";

    # GSettings
    GSETTINGS_SCHEMA_DIR =
      "/run/current-system/sw/share/glib-2.0/schemas";
  };

  # ----------------------------------------------------------
  # Niri
  # ----------------------------------------------------------
  programs.niri.enable = true;

  # ----------------------------------------------------------
  # Zsh
  # ----------------------------------------------------------
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;

      theme = "robbyrussell";

      plugins = [
        "git"
        "sudo"
        "history"
        "colored-man-pages"
      ];
    };

    promptInit =
      "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  # ----------------------------------------------------------
  # Qt
  # ----------------------------------------------------------
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # ----------------------------------------------------------
  # Programs
  # ----------------------------------------------------------
  programs.steam.enable = true;

  programs.throne.enable = true;
  programs.throne.tunMode.enable = true;

  programs.dconf.enable = true;


  # ----------------------------------------------------------
  # Login Manager
  # ----------------------------------------------------------
  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = "sadra";
      };
    };
  };

  systemd.user.services.niri.enableDefaultPath = false;

  # ----------------------------------------------------------
  # Desktop Applications
  # ----------------------------------------------------------
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    noctalia-shell
    firefox
    xwayland-satellite
    wl-clipboard
    grim
    slurp
    swaybg
    swaylock
    swayidle
    nautilus
    polkit_gnome
    blueman
    git
    neovim
    curl
    wget
    btop
    zsh-powerlevel10k
    adwaita-icon-theme
    gnome-themes-extra
    gtk3
    gtk4
    glib
    dconf
    gsettings-desktop-schemas
    adwaita-qt
    telegram-desktop
    mpv
    opencode
    rmpc
    mpc
    ollama-cuda
    python314
    python314Packages.pip
    vscode
  ];

  # ----------------------------------------------------------
  # Music
  # ----------------------------------------------------------
  services.mpd = {
    enable = true;
    user = "sadra";

    settings = {
      music_directory = "/home/sadra/Music";

      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire";
        }
      ];
    };
  };

systemd.services.mpd.environment = {
  XDG_RUNTIME_DIR = "/run/user/1000";
};
  # ----------------------------------------------------------
  # Fonts
  # ----------------------------------------------------------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ----------------------------------------------------------
  # GTK 3
  # ----------------------------------------------------------
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-icon-theme-name=Adwaita
    gtk-application-prefer-dark-theme=1
  '';

  # ----------------------------------------------------------
  # GTK 4
  # ----------------------------------------------------------
  environment.etc."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-icon-theme-name=Adwaita
    gtk-application-prefer-dark-theme=1
  '';

  # ----------------------------------------------------------
  # GSettings / GNOME Dark Mode
  # ----------------------------------------------------------
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
          icon-theme = "Adwaita";
        };
      };
    }
  ];

  # ----------------------------------------------------------
  # XDG Desktop Portals
  # ----------------------------------------------------------
  xdg.portal = {
    enable = true;

    wlr.enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # ----------------------------------------------------------
  # Audio / PipeWire
  # ----------------------------------------------------------
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;
  };

  # ----------------------------------------------------------
  # Bluetooth
  # ----------------------------------------------------------
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # ----------------------------------------------------------
  # Power / Storage
  # ----------------------------------------------------------
  services.upower.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # ----------------------------------------------------------
  # Polkit
  # ----------------------------------------------------------
  security.polkit.enable = true;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "Polkit GNOME Authentication Agent";

    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

      Restart = "on-failure";
    };
  };

  # ----------------------------------------------------------
  # GNOME Keyring
  # ----------------------------------------------------------
  services.gnome.gnome-keyring.enable = true;

  # ----------------------------------------------------------
  # Swaylock PAM
  # ----------------------------------------------------------
  security.pam.services.swaylock = {};

  # ----------------------------------------------------------
  # Nix
  # ----------------------------------------------------------
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ----------------------------------------------------------
  # NixOS Version
  # ----------------------------------------------------------
  system.stateVersion = "26.05";
}
