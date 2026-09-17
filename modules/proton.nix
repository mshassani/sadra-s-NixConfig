{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.protonRunner;

  protonPackage = pkgs.proton-ge-bin;
  proton = "${protonPackage.steamcompattool}/proton";
  steamRun = "${pkgs.steam-run}/bin/steam-run";

  protonRun = pkgs.writeShellScriptBin "proton-run" ''
    set -euo pipefail

    usage() {
      echo "Usage: proton-run <prefix> <exe> [args...]"
      echo
      echo "Example:"
      echo "  proton-run myapp ~/Games/myapp/app.exe"
    }

    if [ "$#" -lt 2 ]; then
      usage >&2
      exit 2
    fi

    prefix_name="$1"
    shift
    exe="$1"
    shift

    case "$prefix_name" in
      ""|*[!A-Za-z0-9._-]*)
        echo "proton-run: invalid prefix name: $prefix_name" >&2
        echo "Use only letters, numbers, '.', '_' and '-'" >&2
        exit 2
        ;;
    esac

    case "$exe" in
      "~/"*) exe="$HOME/''${exe#~/}" ;;
    esac

    if [ ! -f "$exe" ]; then
      echo "proton-run: executable not found: $exe" >&2
      exit 1
    fi

    prefix="$HOME/.local/share/proton-prefixes/$prefix_name"
    mkdir -p "$prefix"

    export STEAM_COMPAT_DATA_PATH="$prefix"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="${pkgs.steam}/share/steam"

    exec ${steamRun} ${proton} run "$exe" "$@"
  '';

  appLaunchers = mapAttrsToList
    (name: app:
      let
        launcher = pkgs.writeShellScriptBin "proton-${name}" ''
          exec ${protonRun}/bin/proton-run \
            ${escapeShellArg app.prefix} \
            ${escapeShellArg app.exe}
        '';
      in
      {
        inherit name;
        inherit app launcher;
      }
    )
    cfg.apps;

in
{
  options.programs.protonRunner = {
    enable = mkEnableOption "Proton-GE runner for non-Steam Windows applications";

    apps = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          exe = mkOption {
            type = types.str;
            description = "Path to the Windows executable. ~/ is expanded at runtime.";
            example = "~/Games/example/example.exe";
          };

          prefix = mkOption {
            type = types.strMatching "[A-Za-z0-9._-]+";
            description = "Isolated Proton prefix name under ~/.local/share/proton-prefixes/.";
            example = "example";
          };

          name = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Display name for the desktop entry. Defaults to the attribute name.";
          };

          comment = mkOption {
            type = types.str;
            default = "Windows application running with Proton-GE";
          };

          categories = mkOption {
            type = types.listOf types.str;
            default = [ "Utility" ];
          };
        };
      }));
      default = { };
      description = "Non-Steam Windows applications to expose through Proton-GE desktop launchers.";
    };
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      extraCompatPackages = [ protonPackage ];
    };

    environment.systemPackages = [ protonRun ];

    xdg.desktopEntries = listToAttrs (map (entry: {
      name = "proton-${entry.name}";
      value = {
        name = if entry.app.name != null then entry.app.name else entry.name;
        comment = entry.app.comment;
        exec = "${entry.launcher}/bin/proton-${entry.name}";
        terminal = false;
        type = "Application";
        categories = entry.app.categories;
      };
    }) appLaunchers);
  };
}
