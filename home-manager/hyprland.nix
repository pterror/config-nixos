{ pkgs, inputs, ... }: let
  mod = "SUPER";
  screenshot = "${inputs.qti.packages.${pkgs.system}.qti}/bin/qti --path ${inputs.qti.packages.${pkgs.system}.qti-app-screenshot-editor}/share/qti/screenshot-editor/screenshot-editor.qml";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    settings = {
      general = { border_size = 0; };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
      dwindle = { no_gaps_when_only = 1; };
      cursor = { no_hardware_cursors = 1; };
      decoration = {
        rounding = 10;
        blur = {
          enabled = false;
          size = 3;
          passes = 3;
          vibrancy = 0.1696;
        };
        drop_shadow = false;
        shadow_range = 4;
        shadow_render_power = 3;
        dim_special = 0.7;
        "col.shadow" = "rgba(1a1a1aee)";
      };
      animations = {
        bezier = [
          "linear, 0, 0, 1, 1"
          "md3_standard, 0.2, 0, 0, 1"
          "md3_decel, 0.05, 0.7, 0.1, 1"
          "md3_accel, 0.3, 0, 0.8, 0.15"
          "overshot, 0.05, 0.9, 0.1, 1.1"
          "crazyshot, 0.1, 1.5, 0.76, 0.92"
          "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
          "menu_decel, 0.1, 1, 0, 1"
          "menu_accel, 0.38, 0.04, 1, 0.07"
          "easeInOutCirc, 0.85, 0, 0.15, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutExpo, 0.16, 1, 0.3, 1"
          "softAcDecel, 0.26, 0.26, 0.15, 1"
          "md2, 0.4, 0, 0.2, 1"
        ];
        animation = [
          "windows, 1, 3, md3_decel, popin 60%"
          "windowsIn, 1, 3, md3_decel, popin 60%"
          "windowsOut, 1, 3, md3_accel, popin 60%"
          "border, 1, 10, default"
          "fade, 1, 3, md3_decel"
          "layersIn, 1, 3, menu_decel, slide"
          "layersOut, 1, 1.6, menu_accel"
          "fadeLayersIn, 1, 3, menu_decel"
          "fadeLayersOut, 1, 1.6, menu_accel"
          "workspaces, 1, 7, menu_decel, slide"
          "specialWorkspace, 1, 3, md3_decel, slidevert"
        ];
      };
      env = [
        "XDG_SESSION_TYPE,wayland"
      ];
      monitor = [
        "DP-1, preferred, 0x0, auto"
        "DP-2, preferred, 1920x0, auto"
        "HDMI-A-1, preferred, 3840x0, auto"
      ];
      exec-once = [
        "${inputs.quickshell.packages.${pkgs.system}.default}/bin/quickshell"
      ];
      bindm = [
        "${mod}, mouse:272, movewindow"
        "${mod}, mouse:273, resizewindow"
      ];
      bind = [
        # media
        ", XF86AudioRaiseVolume, global, quickshell:audio:volume_up"
        ", XF86AudioLowerVolume, global, quickshell:audio:volume_down"
        ", XF86AudioMute, global, quickshell:audio:toggle_mute"
        ", XF86AudioMicMute, global, quickshell:audio:toggle_mic_mute"
        ", XF86AudioPlay, global, quickshell:media:play_pause"
        ", XF86AudioStop, global, quickshell:media:pause"
        ", XF86AudioPrev, global, quickshell:media:previous"
        ", XF86AudioNext, global, quickshell:media:next"

        # layershell
        ", Print, exec, [float; monitor DP-2; move -1920 0; size 5760 1080; noanim] ${screenshot}"
        "${mod}, Tab, global, quickshell:workspaces_overview:toggle"
        "${mod}, L, global, quickshell:wlogout:toggle"

        # general
        "${mod}, A, exec, ${pkgs.firefox}/bin/firefox"
        "${mod}, Q, exec, ${pkgs.kitty}/bin/kitty -1"
        "${mod}, C, killactive,"
        "${mod}, M, exit,"
        "${mod}, E, exec, ${pkgs.pcmanfm}/bin/pcmanfm"
        "${mod}, V, togglefloating,"
        "${mod}, R, global, quickshell:launcher:toggle"
        "${mod}, P, pseudo, # dwindle"
        "${mod}, J, togglesplit, # dwindle"

        "${mod}, S, togglespecialworkspace, magic"
        "${mod} SHIFT, S, movetoworkspace, special:magic"

        "${mod}, mouse_down, workspace, e+1"
        "${mod}, mouse_up, workspace, e-1"
      ] ++ (builtins.concatLists (builtins.genList (x: let
        key = toString (x + 1 - ((x + 1) / 10 * 10));
        name = toString (x + 1);
      in [
        "${mod}, ${key}, focusworkspaceoncurrentmonitor, ${name}"
        "${mod} SHIFT, ${key}, movetoworkspace, ${name}"
      ]) 10));
    };
  };
}
