{ pkgs, lib, ... }:

let
  stopScript = pkgs.writeShellScript "hyprland-stop" ''
    pid=$(pgrep Hyprland)
    if [ -n "$pid" ]; then
      kill -STOP "$pid"
    fi
  '';

  contScript = pkgs.writeShellScript "hyprland-cont" ''
    pid=$(pgrep Hyprland)
    if [ -n "$pid" ]; then
      kill -CONT "$pid"
    fi
  '';
in {
  imports = [
    ../../common/home.nix
  ];

  systemd.user.services.hyprland-pause = {
    Unit = {
      Description = "Pause Hyprland before suspend";
      Before = [ "sleep.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = stopScript;
    };

    Install = {
      WantedBy = [ "sleep.target" ];
    };
  };

  systemd.user.services.hyprland-resume = {
    Unit = {
      Description = "Resume Hyprland after suspend";
      After = [ "sleep.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = contScript;
    };

    Install = {
      WantedBy = [ "suspend.target" ];
    };
  };

  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-gstreamer
      obs-vkcapture
    ];
  };

  # Audio production tools
  home.packages = with pkgs; [
    ardour        # Professional DAW
    guitarix      # Guitar amp simulator and effects
    calf          # Audio plugins (effects, EQ, compressors)
    qjackctl      # JACK control GUI
  ];

}
