{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  mod = "SUPER";
  screenshot = "${inputs.qti.packages.${system}.qti}/bin/qti --path ${
    inputs.qti.packages.${system}.qti-app-screenshot-editor
  }/share/qti/screenshot-editor/screenshot-editor.qml";
  quickshell = "${inputs.quickshell.packages.${system}.default}/bin/quickshell";
  browser = "${pkgs.firefox}/bin/firefox";
  terminal = "${pkgs.ghostty}/bin/ghostty";
  file-browser = "${pkgs.pcmanfm}/bin/pcmanfm";
in
''
  exec-once = ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target
  exec-once = ${quickshell} # Assuming 'quickshell' is a package available in your PATH
  exec-once = wlsunset -L 153 -T 6500 -g 1.000000 -l -27.5 -t 4000

  env = QT_QPA_PLATFORM,wayland
  env = XDG_SESSION_TYPE,wayland

  monitor = DP-2, preferred, 0x0, auto
  monitor = DP-3, preferred, 1920x0, auto
  monitor = HDMI-A-2, preferred, 3840x0, auto

  animations {
    bezier = linear, 0, 0, 1, 1
    bezier = md3_standard, 0.2, 0, 0, 1
    bezier = md3_decel, 0.05, 0.7, 0.1, 1
    bezier = md3_accel, 0.3, 0, 0.8, 0.15
    bezier = overshot, 0.05, 0.9, 0.1, 1.1
    bezier = crazyshot, 0.1, 1.5, 0.76, 0.92
    bezier = hyprnostretch, 0.05, 0.9, 0.1, 1.0
    bezier = menu_decel, 0.1, 1, 0, 1
    bezier = menu_accel, 0.38, 0.04, 1, 0.07
    bezier = easeInOutCirc, 0.85, 0, 0.15, 1
    bezier = easeOutCirc, 0, 0.55, 0.45, 1
    bezier = easeOutExpo, 0.16, 1, 0.3, 1
    bezier = softAcDecel, 0.26, 0.26, 0.15, 1
    bezier = md2, 0.4, 0, 0.2, 1
    animation = windows, 1, 3, md3_decel, popin 60%
    animation = windowsIn, 1, 3, md3_decel, popin 60%
    animation = windowsOut, 1, 3, md3_accel, popin 60%
    animation = border, 1, 10, default
    animation = fade, 1, 3, md3_decel
    animation = layersIn, 1, 3, menu_decel, slide
    animation = layersOut, 1, 1.6, menu_accel
    animation = fadeLayersIn, 1, 3, menu_decel
    animation = fadeLayersOut, 1, 1.6, menu_accel
    animation = workspaces, 1, 7, menu_decel, slidefade 20%
    animation = specialWorkspace, 1, 3, md3_decel, slidevert
  }

  cursor {
    no_hardware_cursors = 1
  }

  decoration {
    rounding = 10
    blur {
      enabled = false
      size = 3
      passes = 3
      vibrancy = 0.169600
    }
    shadow {
      enabled = false
      range = 4
      render_power = 3
    }
    dim_special = 0.700000
  }

  dwindle {
    smart_split = true
  }

  general {
    border_size = 0
  }

  misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
  }

  bind = , XF86AudioRaiseVolume, global, quickshell:audio:volume_up
  bind = , XF86AudioLowerVolume, global, quickshell:audio:volume_down
  bind = , XF86AudioMute, global, quickshell:audio:toggle_mute
  bind = , XF86AudioMicMute, global, quickshell:audio:toggle_mic_mute
  bind = , XF86AudioPlay, global, quickshell:media:play_pause
  bind = , XF86AudioStop, global, quickshell:media:pause
  bind = , XF86AudioPrev, global, quickshell:media:previous
  bind = , XF86AudioNext, global, quickshell:media:next
  bind = , Print, exec, [float; monitor DP-3; move -1920 0; size 5760 1080; noanim] ${screenshot}
  bind = ${mod} SHIFT, S, exec, [float; monitor DP-3; move -1920 0; size 5760 1080; noanim] ${screenshot}
  bind = ${mod}, Tab, global, quickshell:workspaces_overview:toggle
  bind = ${mod}, L, global, quickshell:wlogout:toggle
  bind = ${mod}, A, exec, ${browser}
  bind = ${mod}, Q, exec, ${terminal}
  bind = ${mod}, E, exec, ${file-browser}
  bind = ${mod}, C, killactive,
  bind = ${mod}, M, exit,
  bind = ${mod}, V, togglefloating,
  bind = ${mod}, R, global, quickshell:launcher:toggle
  bind = ${mod}, P, pseudo, # dwindle
  bind = ${mod}, J, togglesplit, # dwindle
  bind = ${mod}, Z, togglespecialworkspace, magic
  bind = ${mod} SHIFT, Z, movetoworkspace, special:magic
  bind = ${mod}, left, movefocus, l
  bind = ${mod}, right, movefocus, r
  bind = ${mod}, up, movefocus, u
  bind = ${mod}, down, movefocus, d
  bind = ${mod} SHIFT, left, movewindow, l
  bind = ${mod} SHIFT, right, movewindow, r
  bind = ${mod} SHIFT, up, movewindow, u
  bind = ${mod} SHIFT, down, movewindow, d
  bind = ${mod}, mouse_down, workspace, e+1
  bind = ${mod}, mouse_up, workspace, e-1

  # Workspace binds 1-10
  bind = ${mod}, 1, focusworkspaceoncurrentmonitor, 1
  bind = ${mod} SHIFT, 1, movetoworkspace, 1
  bind = ${mod}, 2, focusworkspaceoncurrentmonitor, 2
  bind = ${mod} SHIFT, 2, movetoworkspace, 2
  bind = ${mod}, 3, focusworkspaceoncurrentmonitor, 3
  bind = ${mod} SHIFT, 3, movetoworkspace, 3
  bind = ${mod}, 4, focusworkspaceoncurrentmonitor, 4
  bind = ${mod} SHIFT, 4, movetoworkspace, 4
  bind = ${mod}, 5, focusworkspaceoncurrentmonitor, 5
  bind = ${mod} SHIFT, 5, movetoworkspace, 5
  bind = ${mod}, 6, focusworkspaceoncurrentmonitor, 6
  bind = ${mod} SHIFT, 6, movetoworkspace, 6
  bind = ${mod}, 7, focusworkspaceoncurrentmonitor, 7
  bind = ${mod} SHIFT, 7, movetoworkspace, 7
  bind = ${mod}, 8, focusworkspaceoncurrentmonitor, 8
  bind = ${mod} SHIFT, 8, movetoworkspace, 8
  bind = ${mod}, 9, focusworkspaceoncurrentmonitor, 9
  bind = ${mod} SHIFT, 9, movetoworkspace, 9
  bind = ${mod}, 0, focusworkspaceoncurrentmonitor, 10
  bind = ${mod} SHIFT, 0, movetoworkspace, 10

  bindm = ${mod}, mouse:272, movewindow
  bindm = ${mod}, mouse:273, resizewindow

  windowrulev2 = bordersize 0, floating:0, onworkspace:w[tv1]
  windowrulev2 = rounding 0, floating:0, onworkspace:w[tv1]
  windowrulev2 = bordersize 0, floating:0, onworkspace:f[1]
  windowrulev2 = rounding 0, floating:0, onworkspace:f[1]

  workspace = w[tv1], gapsout:0, gapsin:0
  workspace = f[1], gapsout:0, gapsin:0
''
