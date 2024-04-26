{ pkgs, inputs, ... }: let
  terminal = "foot";
  fileManager = "pcmanfm";
  menu = "ags -t launcher";
  browser = "MOZ_ENABLE_WAYLAND=0 firefox";
  mod = "SUPER";
  toggleOverview = "quickshell:workspaces_overview:toggle";
  toggleWLogout = "quickshell:wlogout:toggle";
  special = "magic";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprtrails
      #inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
      inputs.hyprspace.packages.${pkgs.system}.Hyprspace
    ];
    extraConfig = ''
      submap=${toggleOverview}
      bind=${mod}, space, submap, reset
      submap=reset
      submap=${toggleWLogout}
      bind=${mod}, space, submap, reset
      submap=reset
    '';
    settings = {
      general = {
        border_size = 0;
      };
      misc = {
        disable_hyprland_logo = true;
	disable_splash_rendering = true;
      };
      dwindle = {
        no_gaps_when_only = 1;
      };
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
      plugin = {
        hyprtrails = {
	  color = "rgba(ffaaaa80)";
	};
      };
      env = [
        "XDG_SESSION_TYPE,wayland"
      ];
      monitor = [
        "DP-1, preferred, 0x0, auto"
        "DP-2, preferred, 1920x0, auto"
        "HDMI-A-1, preferred, 3840x0, auto"
        ", preferred, auto, auto"
      ];
      exec-once = [
	"quickshell"
      ];
      windowrulev2 = [
        "noanim, class:(satty)"
        "float, class:(satty)"
        "monitor DP-1, class:(satty)"
        "move 0 0, class:(satty)"
        "size 5760 1080, class:(satty)"
      ];
      bindm = [
        "${mod}, mouse:272, movewindow"
        "${mod}, mouse:273, resizewindow"
      ];
      bind = [
        # media
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_SOURCE@ toggle"
        ", XF86AudioPlay, exec, playerctl --player=playerctld play-pause"
        ", XF86AudioStop, exec, playerctl --player=playerctld pause"
        ", XF86AudioPrev, exec, playerctl --player=playerctld previous"
        ", XF86AudioNext, exec, playerctl --player=playerctld next"

        # layershell
	", Print, exec, grim -g '0,0 5760x1080' - | satty --no-resize --initial-tool crop --filename - --early-exit --copy-command wl-copy"
	#", Print, exec, [noanim;float;monitor DP-1;move 0 0;size 5760 1080] satty --initial-tool crop --filename <(grim -g '0,0 5760x1080' -) --early-exit --copy-command wl-copy"
	"${mod}, Tab, exec, hyprctl dispatch submap \"${toggleOverview}\" && hyprctl dispatch submap reset"
	"${mod}, L, exec, hyprctl dispatch submap \"${toggleWLogout}\" && hyprctl dispatch submap reset"
	#"ALT, Tab, hyprexpo:expo"
	"ALT, Tab, overview:toggle"

        # general
        "${mod}, A, exec, ${browser}"
        "${mod}, Q, exec, ${terminal}"
        "${mod}, C, killactive,"
        "${mod}, M, exit,"
        "${mod}, E, exec, ${fileManager}"
        "${mod}, V, togglefloating,"
        "${mod}, R, exec, ${menu}"
        "${mod}, P, pseudo, # dwindle"
        "${mod}, J, togglesplit, # dwindle"

	"${mod}, S, togglespecialworkspace, ${special}"
        "${mod} SHIFT, S, movetoworkspace, special:${special}"

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
