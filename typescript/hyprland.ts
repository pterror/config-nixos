import type { BindDef, HyprlandConfig, ModKey } from "./defs/hyprland/types";

// Define a MOD key constant. 'SUPER' is a common choice.
const MOD = "SUPER" satisfies ModKey;

// Placeholders for Nix package paths. These would be replaced at build time.
const quickshellPath =
  "${inputs.quickshell.packages.${pkgs.system}.default}/bin/quickshell";
const screenshotPath = "${screenshot}";
const firefoxPath = "${pkgs.firefox}/bin/firefox";
const kittyPath = "${pkgs.kitty}/bin/kitty -1";
const itchPath = "${pkgs.itch}/bin/itch";
const pcmanfmPath = "${pkgs.pcmanfm}/bin/pcmanfm";

// --- Dynamic Bind Generation ---
// Replicates the Nix logic to generate binds for workspaces 1-10 on keys 1-0.
const workspaceBinds = Array.from({ length: 10 }, (_, i): BindDef[] => {
  const workspace = i + 1;
  const key = workspace === 10 ? "0" : String(workspace);
  return [
    {
      mods: [MOD],
      key,
      dispatcher: "focusworkspaceoncurrentmonitor",
      params: String(workspace),
    },
    {
      mods: [MOD, "SHIFT"],
      key,
      dispatcher: "movetoworkspace",
      params: String(workspace),
    },
  ];
}).flat();

// --- Main Configuration Object ---
export default {
  // NOTE: 'bezier' is not in the current HyprlandConfig type. This would cause a type error.
  bezier: [
    "linear, 0, 0, 1, 1",
    "md3_standard, 0.2, 0, 0, 1",
    "md3_decel, 0.05, 0.7, 0.1, 1",
    "md3_accel, 0.3, 0, 0.8, 0.15",
    "overshot, 0.05, 0.9, 0.1, 1.1",
    "crazyshot, 0.1, 1.5, 0.76, 0.92",
    "hyprnostretch, 0.05, 0.9, 0.1, 1.0",
    "menu_decel, 0.1, 1, 0, 1",
    "menu_accel, 0.38, 0.04, 1, 0.07",
    "easeInOutCirc, 0.85, 0, 0.15, 1",
    "easeOutCirc, 0, 0.55, 0.45, 1",
    "easeOutExpo, 0.16, 1, 0.3, 1",
    "softAcDecel, 0.26, 0.26, 0.15, 1",
    "md2, 0.4, 0, 0.2, 1",
  ],

  general: {
    border_size: 0,
  },

  misc: {
    disable_hyprland_logo: true,
    disable_splash_rendering: true,
    // NOTE: 'no_hardware_cursors' is not in the current Misc type. This would cause a type error.
    no_hardware_cursors: true,
  },

  dwindle: {
    // NOTE: Assuming 'smart_split' from source maps to 'smart_resizing'.
    smart_resizing: true,
  },

  decoration: {
    rounding: 10,
    blur: {
      enabled: false,
      size: 3,
      passes: 3,
      // NOTE: 'vibrancy' is not in the current BlurSettings type. This would cause a type error.
      vibrancy: 0.1696,
    },
    shadow: {
      enabled: false,
      range: 4,
      render_power: 3,
    },
    dim_special: 0.7,
  },

  animations: {
    // NOTE: Individual animation toggles are done via the 'animation' keyword array.
  },

  animation: [
    {
      name: "windows",
      enabled: true,
      speed: 3,
      curve: "md3_decel",
      style: "popin 60%",
    },
    // NOTE: 'windowsIn' and 'windowsOut' are not valid AnimationNames. This will cause a type error.
    // They are typically handled by the 'windows' animation. Assuming intent.
    // { name: 'windowsIn', enabled: true, speed: 3, curve: 'md3_decel', style: 'popin 60%' },
    // { name: 'windowsOut', enabled: true, speed: 3, curve: 'md3_accel', style: 'popin 60%' },
    { name: "border", enabled: true, speed: 10, curve: "default" },
    { name: "fade", enabled: true, speed: 3, curve: "md3_decel" },
    // NOTE: 'layersIn', 'layersOut', 'fadeLayersIn', 'fadeLayersOut' are not valid AnimationNames.
    // Layer animations are not individually configurable this way.
    // { name: 'layersIn', enabled: true, speed: 3, curve: 'menu_decel', style: 'slide' },
    // { name: 'layersOut', enabled: true, speed: 1.6, curve: 'menu_accel' },
    // { name: 'fadeLayersIn', enabled: true, speed: 3, curve: 'menu_decel' },
    // { name: 'fadeLayersOut', enabled: true, speed: 1.6, curve: 'menu_accel' },
    {
      name: "workspaces",
      enabled: true,
      speed: 7,
      curve: "menu_decel",
      style: "slidefade 20%",
    },
    // NOTE: 'specialWorkspace' is not a valid AnimationName. It's handled by 'workspaces'.
    // { name: 'specialWorkspace', enabled: true, speed: 3, curve: 'md3_decel', style: 'slidevert' },
  ],

  workspace: [
    { name: "w[tv1]", rules: { gapsOut: 0, gapsIn: 0 } },
    { name: "f[1]", rules: { gapsOut: 0, gapsIn: 0 } },
  ],

  windowrule: [
    // NOTE: 'bordersize' and 'rounding' are not in the WindowRuleProperties type.
    // This will cause a type error.
    {
      rule: { floating: false, workspace: /w\[tv1\]/ },
      properties: { bordersize: 0 },
    },
    {
      rule: { floating: false, workspace: /w\[tv1\]/ },
      properties: { rounding: 0 },
    },
    {
      rule: { floating: false, workspace: /f\[1\]/ },
      properties: { bordersize: 0 },
    },
    {
      rule: { floating: false, workspace: /f\[1\]/ },
      properties: { rounding: 0 },
    },
  ],

  env: {
    QT_QPA_PLATFORM: "wayland",
    XDG_SESSION_TYPE: "wayland",
  },

  monitor: [
    { name: "DP-1", resolution: "preferred", position: "0x0", scale: 1 }, // Assuming auto scale is 1
    { name: "DP-2", resolution: "preferred", position: "1920x0", scale: 1 },
    { name: "HDMI-A-1", resolution: "preferred", position: "3840x0", scale: 1 },
  ],

  "exec-once": [
    quickshellPath,
    "wlsunset -L 153 -T 6500 -g 1.000000 -l -27.5 -t 4000",
  ],

  bindm: [
    { mods: [MOD], key: "mouse:272", dispatcher: "movewindow" },
    { mods: [MOD], key: "mouse:273", dispatcher: "resizewindow" },
  ],

  bind: [
    // Media
    {
      mods: [],
      key: "XF86AudioRaiseVolume",
      dispatcher: "global",
      params: "quickshell:audio:volume_up",
    },
    {
      mods: [],
      key: "XF86AudioLowerVolume",
      dispatcher: "global",
      params: "quickshell:audio:volume_down",
    },
    {
      mods: [],
      key: "XF86AudioMute",
      dispatcher: "global",
      params: "quickshell:audio:toggle_mute",
    },
    {
      mods: [],
      key: "XF86AudioMicMute",
      dispatcher: "global",
      params: "quickshell:audio:toggle_mic_mute",
    },
    {
      mods: [],
      key: "XF86AudioPlay",
      dispatcher: "global",
      params: "quickshell:media:play_pause",
    },
    {
      mods: [],
      key: "XF86AudioStop",
      dispatcher: "global",
      params: "quickshell:media:pause",
    },
    {
      mods: [],
      key: "XF86AudioPrev",
      dispatcher: "global",
      params: "quickshell:media:previous",
    },
    {
      mods: [],
      key: "XF86AudioNext",
      dispatcher: "global",
      params: "quickshell:media:next",
    },
    // Layershell
    {
      mods: [],
      key: "Print",
      dispatcher: "exec",
      params: `[float; monitor DP-2; move -1920 0; size 5760 1080; noanim] ${screenshotPath}`,
    },
    {
      mods: [MOD, "SHIFT"],
      key: "S",
      dispatcher: "exec",
      params: `[float; monitor DP-2; move -1920 0; size 5760 1080; noanim] ${screenshotPath}`,
    },
    {
      mods: [MOD],
      key: "Tab",
      dispatcher: "global",
      params: "quickshell:workspaces_overview:toggle",
    },
    {
      mods: [MOD],
      key: "L",
      dispatcher: "global",
      params: "quickshell:wlogout:toggle",
    },
    // General
    { mods: [MOD], key: "A", dispatcher: "exec", params: firefoxPath },
    { mods: [MOD], key: "Q", dispatcher: "exec", params: kittyPath },
    { mods: [MOD], key: "C", dispatcher: "killactive", params: "" },
    { mods: [MOD], key: "D", dispatcher: "exec", params: itchPath },
    { mods: [MOD], key: "M", dispatcher: "exit", params: "" },
    { mods: [MOD], key: "E", dispatcher: "exec", params: pcmanfmPath },
    { mods: [MOD], key: "V", dispatcher: "togglefloating", params: "" },
    {
      mods: [MOD],
      key: "R",
      dispatcher: "global",
      params: "quickshell:launcher:toggle",
    },
    { mods: [MOD], key: "P", dispatcher: "pseudo", params: "" },
    { mods: [MOD], key: "J", dispatcher: "togglesplit", params: "" },
    // Special Workspace
    {
      mods: [MOD],
      key: "Z",
      dispatcher: "togglespecialworkspace",
      params: "magic",
    },
    {
      mods: [MOD, "SHIFT"],
      key: "Z",
      dispatcher: "movetoworkspace",
      params: "special:magic",
    },
    // Movement
    { mods: [MOD], key: "left", dispatcher: "movefocus", params: "l" },
    { mods: [MOD], key: "right", dispatcher: "movefocus", params: "r" },
    { mods: [MOD], key: "up", dispatcher: "movefocus", params: "u" },
    { mods: [MOD], key: "down", dispatcher: "movefocus", params: "d" },
    {
      mods: [MOD, "SHIFT"],
      key: "left",
      dispatcher: "movewindow",
      params: "l",
    },
    {
      mods: [MOD, "SHIFT"],
      key: "right",
      dispatcher: "movewindow",
      params: "r",
    },
    { mods: [MOD, "SHIFT"], key: "up", dispatcher: "movewindow", params: "u" },
    {
      mods: [MOD, "SHIFT"],
      key: "down",
      dispatcher: "movewindow",
      params: "d",
    },
    // Mouse binds
    { mods: [MOD], key: "mouse_down", dispatcher: "workspace", params: "e+1" },
    { mods: [MOD], key: "mouse_up", dispatcher: "workspace", params: "e-1" },
    // Add the dynamically generated workspace binds
    ...workspaceBinds,
  ],
} satisfies HyprlandConfig;
