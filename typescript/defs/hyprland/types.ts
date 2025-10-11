// ~~~~~~~~~~~~~~~~~~~~~~~~~~ Core & Utility Types ~~~~~~~~~~~~~~~~~~~~~~~~~~

/** A string representing a color, can be rgb, rgba, or hex (0x prefixed). */
export type Color = `rgb(${string})` | `rgba(${string})` | `0x${string}`;

/** A string representing a color gradient. e.g., "rgba(ff0000ee) rgba(00ff00ee) 45deg" */
export type Gradient = string;

/** A two-dimensional vector, represented as space-separated numbers. e.g., "10 10" */
export type Vec2 = `${number} ${number}`;

/** Represents a boolean-like state that can be on/off, true/false, or 0/1. */
export type OnOff = "on" | "off" | "true" | "false" | boolean | 0 | 1;

/** Represents a modifier key. */
export type ModKey =
  | "SHIFT"
  | "CAPS"
  | "CTRL"
  | "CONTROL"
  | "ALT"
  | "MOD1"
  | "MOD2"
  | "MOD3"
  | "MOD4"
  | "MOD5"
  | "SUPER"
  | "WIN"
  | "LOGO";

/** Animation curves available in Hyprland. */
export type AnimationCurve =
  | "linear"
  | "overshot"
  | "easeInSine"
  | "easeOutSine"
  | "easeInOutSine"
  | "easeInQuad"
  | "easeOutQuad"
  | "easeInOutQuad"
  | "easeInCubic"
  | "easeOutCubic"
  | "easeInOutCubic"
  | "easeInQuart"
  | "easeOutQuart"
  | "easeInOutQuart"
  | "easeInQuint"
  | "easeOutQuint"
  | "easeInOutQuint"
  | "easeInExpo"
  | "easeOutExpo"
  | "easeInOutExpo"
  | "easeInCirc"
  | "easeOutCirc"
  | "easeInOutCirc"
  | "easeInBack"
  | "easeOutBack"
  | "easeInOutBack"
  | "easeInElastic"
  | "easeOutElastic"
  | "easeInOutElastic";

/** Animation styles for windows. */
export type WindowAnimationStyle = "slide" | "popin" | "slidevert" | "fade";

// ~~~~~~~~~~~~~~~~~~~~~~~~ Enums & Type Aliases ~~~~~~~~~~~~~~~~~~~~~~~

/** `0`: disabled, `1`: full, `2`: loose */
export type FollowMouseMode = "none" | "full" | "loose";

/** `0`: don't focus, `1`: focus the window */
export type FloatSwitchFocusMode = "none" | "focus";

/** `0`: normal, `1`: 90 deg, `2`: 180 deg, `3`: 270 deg */
export type TransformMode =
  | "normal"
  | "rotate-90"
  | "rotate-180"
  | "rotate-270";

/** `0`: off, `1`: on, `2`: fullscreen only */
export type VRRMode = "off" | "on" | "fullscreen";

/** `0`: none, `1`: monitor, `2`: full */
export type DamageTrackingMode = "none" | "monitor" | "full";

/** `0`: none, `1`: simple, `2`: full */
export type NewWindowFullscreenMode = "none" | "simple" | "full";

/** `0`: disabled, `1`: always, `2`: if floating */
export type ForceSplitMode = "off" | "always" | "if-floating";

/** `0`: history, `1`: closest, `2`: closest on top */
export type FocusPreferredMethod = "history" | "closest" | "closest_top";

/** Defines how a window should be moved. Can be absolute coordinates or relative to cursor. */
export type WindowRuleMoveType = Vec2 | `cursor ${Vec2}`;

/** Defines idle-inhibit behavior for a window. */
export type IdleInhibitMode = "none" | "focus" | "fullscreen" | "always";

/** Monitor resolution and refresh rate options. */
export type MonitorResolution =
  | "preferred"
  | "auto"
  | "highrr"
  | "disabled"
  | `${number}x${number}`
  | `${number}x${number}@${number}`;

/** Animation names. */
export type AnimationName =
  | "workspaces"
  | "windows"
  | "border"
  | "borderangle"
  | "fade";

/** Workspace layout types. */
export type LayoutType = "dwindle" | "master";

/** Mouse acceleration profiles. */
export type AccelProfile = "default" | "flat" | "adaptive" | "none";

/** Master layout orientation. */
export type MasterOrientation = "left" | "top" | "right" | "bottom" | "center";

/** Workspace border styles. */
export type BorderStyle = "simple" | "round";

// ~~~~~~~~~~~~~~~~~~~~~~~~ Structured Keyword Types ~~~~~~~~~~~~~~~~~~~~~~~~

/**
 * A structured representation of a monitor configuration.
 * Note: The string equivalent is positional: `name,resolution,position,scale`.
 * Some properties like 'disabled' or 'mirror' are mutually exclusive with layout properties.
 */
export interface MonitorDef {
  /** The name of the monitor (e.g., DP-1), or empty for a rule. */
  name: string;
  /** The resolution and refresh rate. Use 'disabled' to disable the monitor. */
  resolution: MonitorResolution;
  /** The position on the global layout. */
  position?: Vec2 | "auto";
  /** The scaling factor. */
  scale?: number;
  /** Transform mode for the monitor. */
  transform?: TransformMode;
  /** Mirrors another monitor. If set, other layout properties are ignored. */
  mirror?: string;
  /** Force 10-bit color depth. */
  bitdepth10?: boolean;
}

/** A structured representation of a keybind. */
export interface BindDef {
  mods: ModKey[];
  key: string;
  dispatcher: string;
  params?: string;
}

/** A structured representation of an unbind rule. */
export interface UnbindDef {
  mods: ModKey[];
  key: string;
}

/** Describes the conditions to match for a window rule. */
export interface WindowRuleMatcher {
  class?: RegExp;
  title?: RegExp;
  xwayland?: boolean;
  floating?: boolean;
  tiled?: boolean;
  fullscreen?: boolean;
  pinned?: boolean;
  initialClass?: RegExp;
  initialTitle?: RegExp;
}

/** Describes the properties to apply when a window rule matches. */
export interface WindowRuleProperties {
  float?: OnOff;
  tile?: OnOff;
  fullscreen?: OnOff;
  pseudo?: OnOff;
  pin?: OnOff;
  move?: WindowRuleMoveType;
  size?: Vec2;
  minsize?: Vec2;
  maxsize?: Vec2;
  opacity?: number;
  workspace?: string;
  idleinhibit?: IdleInhibitMode;
}

/** A structured representation of a window rule (v2 syntax). */
export interface WindowRule {
  rule: WindowRuleMatcher;
  properties: WindowRuleProperties;
}

/** Properties for a layer rule. */
export interface LayerRuleProperties {
  blur?: OnOff;
  blur_new?: OnOff;
  ignorealpha?: number;
}

/** A structured representation of a layer rule for popups and notifications. */
export interface LayerRule {
  namespace: string;
  properties: LayerRuleProperties;
}

/** A structured representation of a workspace rule. */
export interface WorkspaceRuleProperties {
  monitor?: string;
  gapsIn?: number;
  gapsOut?: number;
  borderSize?: number;
  border_style?: BorderStyle;
  rounding?: boolean;
  decorate?: boolean;
  default?: boolean;
  persistent?: boolean;
  onCreated?: string; // Command
}

/** A structured representation of a workspace definition. */
export interface WorkspaceRuleDef {
  name: string | number;
  rules: WorkspaceRuleProperties;
}

/** A structured representation of an animation rule. */
export interface AnimationRule {
  name: AnimationName;
  enabled: OnOff;
  speed: number;
  curve: AnimationCurve;
  style?: WindowAnimationStyle | string;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~ Configuration Sections ~~~~~~~~~~~~~~~~~~~~~~~~~~

export interface ShadowSettings {
  /** enable drop shadows on windows */
  enabled?: OnOff;
  /** shadow range */
  range?: number;
  /** shadow render power */
  render_power?: number;
  /** if true, the shadow will not be rendered behind the window */
  ignore_window?: boolean;
  /** shadow color */
  color?: Color;
  /** shadow opacity */
  opacity?: number;
  /** shadow offset */
  offset?: Vec2;
  /** if true, the shadow will scale with the window */
  scale?: boolean;
}

export interface BlurSettings {
  /** enables blur */
  enabled?: boolean;
  /** blur size (larger is blurrier) */
  size?: number;
  /** the amount of passes to perform */
  passes?: number;
  /** whether to enable further optimizations to the blur */
  new_optimizations?: OnOff;
  /** whether to blur behind the transparent enabled window. Do not use with popups */
  xray?: boolean;
  /** how much noise to apply */
  noise?: number;
  /** how much contrast to apply */
  contrast?: number;
  /** how much brightness to apply */
  brightness?: number;
  /** whether to blur popups (e.g. notifications) */
  popups?: boolean;
}

export interface TouchpadSettings {
  /** invert scrolling direction */
  natural_scroll?: boolean;
  /** disables the touchpad while typing */
  disable_while_typing?: boolean;
  /** enables clickfinger behavior */
  clickfinger_behavior?: boolean;
  /** enables middle button emulation */
  middle_button_emulation?: boolean;
  /** enables tap to click */
  tap_to_click?: boolean;
  /** enables drag lock */
  drag_lock?: boolean;
}

export interface TouchDeviceSettings {
  /** transform the input from touchdevices. */
  transform?: TransformMode;
  /** the output to bind touch devices to */
  output?: string;
}

export interface BorderColors {
  /** active window border color */
  active?: Color | Gradient;
  /** inactive window border color */
  inactive?: Color;
  /** border color for windows in a group */
  group?: Color;
  /** active border color for windows in a group */
  group_active?: Color;
}

export interface General {
  /** gaps between windows */
  gaps_in?: number;
  /** gaps between windows and monitor edges */
  gaps_out?: number;
  /** border size in pixels */
  border_size?: number;
  /** border colors */
  border_colors?: BorderColors;
  /** layout of the workspace */
  layout?: LayoutType;
  /** allow tearing in games */
  allow_tearing?: boolean;
  /** master switch for resizing windows by dragging their borders */
  resize_on_border?: boolean;
  /** extend the sensitivity area around borders */
  sensitivity_to_borders?: boolean;
  /** if on, will also extend the sensitivity to raw mouse events */
  apply_sens_to_raw?: boolean;
}

export interface Decoration {
  /** corner radius in pixels */
  rounding?: number;
  /** opacity of active windows */
  active_opacity?: number;
  /** opacity of inactive windows */
  inactive_opacity?: number;
  /** opacity of fullscreen windows */
  fullscreen_opacity?: number;
  /** enables dimming of inactive windows */
  dim_inactive?: boolean;
  /** how much to dim inactive windows */
  dim_strength?: number;
  /** how much to dim behind a special workspace */
  dim_special?: number;
  /** a path to a custom shader to apply to the screen */
  screen_shader?: string;
  /** shadow settings */
  shadow?: ShadowSettings;
  /** settings for the kawase blur */
  blur?: BlurSettings;
}

export interface Animations {
  /** master switch for animations */
  enabled?: OnOff;
  /** enable animations on first launch (if you have an empty policy) */
  first_launch_animation?: boolean;
}

export interface Input {
  /** keyboard layout */
  kb_layout?: string;
  /** keyboard variant */
  kb_variant?: string;
  /** keyboard model */
  kb_model?: string;
  /** keyboard options */
  kb_options?: string;
  /** keyboard rules */
  kb_rules?: string;
  /** key repeat rate in repeats/s */
  repeat_rate?: number;
  /** key repeat delay in ms */
  repeat_delay?: number;
  /** sets the numlock state on compositor start */
  numlock_by_default?: boolean;
  /** sets the way the mouse is followed */
  follow_mouse?: FollowMouseMode;
  /** `none`: don't focus, `focus`: focus the window */
  float_switch_override_focus?: FloatSwitchFocusMode;
  /** mouse sensitivity */
  sensitivity?: number;
  /** mouse acceleration profile */
  accel_profile?: AccelProfile;
  /** inverts the scrolling direction */
  natural_scroll?: boolean;
  /** if enabled, will use per-device settings for input devices */
  per_device_input?: boolean;
  touchpad?: TouchpadSettings;
  touchdevice?: TouchDeviceSettings;
}

export interface Gestures {
  /** enables workspace swipe gestures */
  workspace_swipe?: OnOff;
  /** how many fingers for the swipe gesture */
  workspace_swipe_fingers?: number;
  /** in pixels, how many pixels to swipe for a workspace switch */
  workspace_swipe_distance?: number;
  /** whether to invert the swipe direction */
  workspace_swipe_invert?: boolean;
  /** in pixels/ms, the minimum speed to force a swipe */
  workspace_swipe_min_speed_to_force?: number;
  /** how much (0.0 - 1.0) of the swipe to cancel it */
  workspace_swipe_cancel_ratio?: number;
  /** whether to create a new workspace on overswipe */
  workspace_swipe_create_new?: boolean;
  /** whether to use the r prefix for workspaces */
  workspace_swipe_use_r?: boolean;
}

export interface Misc {
  /** disables the hyprland logo background */
  disable_hyprland_logo?: boolean;
  /** disables the splash rendering. (requires a monitor reload to take effect) */
  disable_splash_rendering?: boolean;
  /** in how many frames to fade out the splash */
  force_default_wallpaper?: number;
  /** use vfr for rendering. can reduce battery usage. */
  vfr?: boolean;
  /** control the vrr (variable refresh rate) of your monitors */
  vrr?: VRRMode;
  /** the damage tracking mode */
  damage_tracking?: DamageTrackingMode;
  /** enable swallow */
  enable_swallow?: boolean;
  /** the regex to use for swallowing */
  swallow_regex?: RegExp;
  /** whether to focus on activate */
  focus_on_activate?: boolean;
  /** disables direct scanout */
  no_direct_scanout?: boolean;
  /** hides the cursor on touch events */
  hide_cursor_on_touch?: boolean;
  /** enables dpms on mouse move */
  mouse_move_enables_dpms?: boolean;
  /** enables focusing monitors on mouse move */
  mouse_move_focuses_monitor?: boolean;
  /** if true, will not check the focus on layers */
  layers_dont_check_focus?: boolean;
  /** if true, will close the special workspace if it's empty */
  close_special_on_empty?: boolean;
  /** controls how new windows behave when a fullscreen window is open */
  new_window_takes_over_fullscreen?: NewWindowFullscreenMode;
  /** suppress xdg-portal warnings */
  suppress_portal_warnings?: boolean;
}

export interface DwindleLayout {
  /** make new windows dwindle bitches */
  pseudotile?: boolean;
  /** `off`: disabled, `always`: always, `if-floating`: if the window is floating */
  force_split?: ForceSplitMode;
  /** if enabled, will preserve the split when switching layouts */
  preserve_split?: boolean;
  /** the scale factor for the special workspace */
  special_scale_factor?: number;
  /** the multiplier for the split width */
  split_width_multiplier?: number;
  /** if there is only one window, it will not have gaps */
  no_gaps_when_only?: boolean;
  /** if enabled, will resize the windows smarter */
  smart_resizing?: boolean;
}

export interface MasterLayout {
  /** whether new windows should be master */
  new_is_master?: boolean;
  /** whether new windows should be on top */
  new_on_top?: boolean;
  /** if there is only one window, it will not have gaps */
  no_gaps_when_only?: boolean;
  /** whether to drop the new window at the cursor position */
  drop_at_cursor?: boolean;
  /** the master factor */
  mfact?: number;
  /** the scale factor for the special workspace */
  special_scale_factor?: number;
  /** the orientation of the master window */
  orientation?: MasterOrientation;
}

export interface Binds {
  /** if enabled, will pass mouse events to the bound window */
  pass_mouse_when_bound?: boolean;
  /** if enabled, will pass scroll events to the bound window */
  scroll_event_passes_through?: boolean;
  /** if enabled, will allow you to switch back and forth between workspaces */
  workspace_back_and_forth?: boolean;
  /** the preferred method of focusing */
  focus_preferred_method?: FocusPreferredMethod;
}

export interface DeviceConfig {
  enabled?: boolean;
  sensitivity?: number;
  accel_profile?: AccelProfile;
  [key: string]: unknown;
}

export interface SubmapDef {
  bind?: BindDef[];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~ Main Configuration Type ~~~~~~~~~~~~~~~~~~~~~~~~~~

export interface HyprlandConfig {
  // --- Debug ---
  /** prints the debug performance overlay. Do not enable on laptops. */
  overlay?: boolean;
  /** makes the compositor blink damaged pixels. */
  damage_blink?: boolean;
  /** disables logging */
  disable_logs?: boolean;
  /** disables time logging */
  disable_time?: boolean;
  /** forces the compositor to render the entire screen */
  damage_whole?: boolean;

  // --- Top-level Keywords (arrays for multiple entries) ---
  monitor?: MonitorDef[];
  "exec-once"?: string[];
  exec?: string[];
  bind?: BindDef[];
  bindl?: BindDef[];
  bindr?: BindDef[];
  bindm?: BindDef[];
  binde?: BindDef[];
  unbind?: UnbindDef[];
  windowrule?: WindowRule[];
  layerrule?: LayerRule[];
  workspace?: WorkspaceRuleDef[];
  animation?: AnimationRule[];
  source?: string[];
  env?: Record<string, string | number | boolean>;

  // --- Configuration Sections ---
  general?: General;
  decoration?: Decoration;
  animations?: Animations;
  input?: Input;
  gestures?: Gestures;
  misc?: Misc;
  binds?: Binds;
  dwindle?: DwindleLayout;
  master?: MasterLayout;

  // --- Special Block Types ---
  device?: Record<string, DeviceConfig>;
  submap?: Record<string, SubmapDef>;
}
