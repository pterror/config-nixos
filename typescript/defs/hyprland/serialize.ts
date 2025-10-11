import type {
  HyprlandConfig,
  BindDef,
  UnbindDef,
  MonitorDef,
  WindowRule,
  LayerRule,
  WorkspaceRuleDef,
  AnimationRule,
  SubmapDef,
  DeviceConfig,
} from "./types.ts";

// ~~~~~~~~~~~~~~~~~~~~~~~~~~ Helper Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~

/**
 * Formats a configuration value into its string representation for the .conf file.
 * @param value The value to format.
 * @returns A string representation of the value.
 */
const formatValue = (value: unknown): string => {
  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }
  if (value instanceof RegExp) {
    // Hyprland expects the regex source without enclosing slashes.
    return value.source;
  }
  if (value === null || value === undefined) {
    return "";
  }
  return String(value);
};

/**
 * Serializes a simple key-value pair.
 * @param key The configuration key.
 * @param value The configuration value.
 * @returns A formatted string line.
 */
const serializeKV = (key: string, value: unknown): string => {
  return `${key} = ${formatValue(value)}`;
};

/**
 * Flattens and serializes a configuration section object.
 * It handles nested objects by joining keys with a dot.
 * @param sectionName The name of the section (e.g., 'general', 'decoration').
 * @param config The section's configuration object.
 * @returns An array of formatted string lines for the section.
 */
export const serializeHyprlandSection = (
  sectionName: string,
  config: Record<string, unknown>,
): string[] => {
  const lines: string[] = [];
  const prefixMappings: Record<string, string> = {
    border_colors: "col.",
    shadow: "shadow_",
  };

  const processObject = (obj: Record<string, any>, prefix = "") => {
    for (const [key, value] of Object.entries(obj)) {
      if (value === undefined) continue;

      if (
        typeof value === "object" &&
        value !== null &&
        !Array.isArray(value) &&
        !(value instanceof RegExp)
      ) {
        const newPrefix = prefixMappings[key] || `${key}_`;
        processObject(value, prefix + newPrefix);
      } else {
        let finalKey = prefix + key;
        // Special mapping for border color group keys
        if (prefix === "col.") {
          if (key === "group") finalKey = "col.group_border";
          if (key === "group_active") finalKey = "col.group_border_active";
          if (key === "active") finalKey = "col.active_border";
          if (key === "inactive") finalKey = "col.inactive_border";
        }
        lines.push(serializeKV(finalKey, value));
      }
    }
  };

  processObject(config);

  if (lines.length === 0) return [];

  // Wrap the lines in a section block
  return [`${sectionName} {`, ...lines.map((line) => `    ${line}`), "}"];
};

// ~~~~~~~~~~~~~~~~~~~~~~~~ Keyword Serializers ~~~~~~~~~~~~~~~~~~~~~~~~

export const serializeHyprlandMonitor = (monitor: MonitorDef): string => {
  let parts = [
    monitor.name,
    monitor.resolution,
    monitor.position || "auto",
    monitor.scale || 1,
  ];
  let line = `monitor = ${parts.join(",")}`;

  if (monitor.transform) {
    const transformMap = {
      normal: 0,
      "rotate-90": 1,
      "rotate-180": 2,
      "rotate-270": 3,
    };
    line += `,transform,${transformMap[monitor.transform]}`;
  }
  if (monitor.mirror) {
    line += `,mirror,${monitor.mirror}`;
  }
  if (monitor.bitdepth10) {
    line += `,bitdepth,10`;
  }
  return line;
};

export const serializeHyprlandBind = (
  keyword: string,
  bind: BindDef,
): string => {
  const mods = bind.mods.join(""); // SUPERWIN etc.
  const params = bind.params ? `,${bind.params}` : "";
  return `${keyword} = ${mods},${bind.key},${bind.dispatcher}${params}`;
};

export const serializeHyprlandUnbind = (unbind: UnbindDef): string => {
  const mods = unbind.mods.join("");
  return `unbind = ${mods},${unbind.key}`;
};

export const serializeHyprlandWindowRule = (rule: WindowRule): string[] => {
  const lines: string[] = [];
  const matcherParts: string[] = [];

  for (const [key, value] of Object.entries(rule.rule)) {
    if (value === undefined) continue;
    matcherParts.push(`${key}:${formatValue(value)}`);
  }
  const matcherString = matcherParts.join(" ");

  for (const [prop, value] of Object.entries(rule.properties)) {
    if (value === undefined) continue;
    lines.push(`windowrule = ${prop} ${formatValue(value)},${matcherString}`);
  }
  return lines;
};

export const serializeHyprlandLayerRule = (rule: LayerRule): string[] => {
  const lines: string[] = [];
  for (const [prop, value] of Object.entries(rule.properties)) {
    if (value === undefined) continue;
    lines.push(`layerrule = ${prop},namespace:${rule.namespace}`);
  }
  return lines;
};

export const serializeHyprlandWorkspaceRule = (
  rule: WorkspaceRuleDef,
): string[] => {
  const lines: string[] = [];
  for (const [prop, value] of Object.entries(rule.rules)) {
    if (value === undefined) continue;
    lines.push(`workspace = ${rule.name},${prop}:${formatValue(value)}`);
  }
  return lines;
};

export const serializeHyprlandAnimation = (anim: AnimationRule): string => {
  const style = anim.style ? `,${anim.style}` : "";
  return `animation = ${anim.name},${formatValue(anim.enabled)},${anim.speed},${
    anim.curve
  }${style}`;
};

// ~~~~~~~~~~~~~~~~~~~~~~~~~~ Main Serializer ~~~~~~~~~~~~~~~~~~~~~~~~~~

/**
 * Serializes a HyprlandConfig object into a valid hyprland.conf string.
 * @param config The Hyprland configuration object.
 * @returns A string representing the complete hyprland.conf file.
 */
export const serializeHyprlandConfig = (config: HyprlandConfig): string => {
  const lines: string[] = [
    "# Generated by TypeScript Hyprland Serializer",
    "# Do not edit manually!",
    "",
  ];

  for (const [key, value] of Object.entries(config)) {
    if (value === undefined || value === null) continue;

    switch (key) {
      // --- Sections ---
      case "general":
      case "decoration":
      case "animations":
      case "input":
      case "gestures":
      case "misc":
      case "binds":
      case "dwindle":
      case "master":
        lines.push(
          ...serializeHyprlandSection(key, value as Record<string, unknown>),
          "",
        );
        break;

      // --- Simple Keyword Arrays ---
      case "exec-once":
      case "exec":
      case "source":
        (value as string[]).forEach((v) => lines.push(`${key} = ${v}`));
        lines.push("");
        break;

      // --- Complex Keyword Arrays ---
      case "monitor":
        (value as MonitorDef[]).forEach((v) =>
          lines.push(serializeHyprlandMonitor(v)),
        );
        lines.push("");
        break;
      case "bind":
      case "bindl":
      case "bindr":
      case "bindm":
      case "binde":
        (value as BindDef[]).forEach((v) =>
          lines.push(serializeHyprlandBind(key, v)),
        );
        lines.push("");
        break;
      case "unbind":
        (value as UnbindDef[]).forEach((v) =>
          lines.push(serializeHyprlandUnbind(v)),
        );
        lines.push("");
        break;
      case "windowrule":
        (value as WindowRule[]).forEach((v) =>
          lines.push(...serializeHyprlandWindowRule(v)),
        );
        lines.push("");
        break;
      case "layerrule":
        (value as LayerRule[]).forEach((v) =>
          lines.push(...serializeHyprlandLayerRule(v)),
        );
        lines.push("");
        break;
      case "workspace":
        (value as WorkspaceRuleDef[]).forEach((v) =>
          lines.push(...serializeHyprlandWorkspaceRule(v)),
        );
        lines.push("");
        break;
      case "animation":
        (value as AnimationRule[]).forEach((v) =>
          lines.push(serializeHyprlandAnimation(v)),
        );
        lines.push("");
        break;

      // --- Record<string, -> Keywords ---
      case "env":
        Object.entries(
          value as Record<string, string | number | boolean>,
        ).forEach(([k, v]) => lines.push(`env = ${k},${formatValue(v)}`));
        lines.push("");
        break;
      case "device":
        Object.entries(value as Record<string, DeviceConfig>).forEach(
          ([name, config]) => {
            lines.push(
              `device:${name} {`,
              ...serializeHyprlandSection("", config).slice(1, -1),
              "}",
            );
          },
        );
        lines.push("");
        break;
      case "submap":
        Object.entries(value as Record<string, SubmapDef>).forEach(
          ([name, submapConfig]) => {
            lines.push(`submap = ${name}`);
            if (submapConfig.bind) {
              submapConfig.bind.forEach((b) =>
                lines.push(serializeHyprlandBind("bind", b)),
              );
            }
            lines.push("submap = reset");
          },
        );
        lines.push("");
        break;

      // --- Debug flags ---
      case "overlay":
      case "damage_blink":
      case "disable_logs":
      case "disable_time":
      case "damage_whole":
        lines.push(`debug:${key} = ${formatValue(value)}`);
        break;

      default:
        // For any keys that might be missed or are simple top-level KV pairs.
        lines.push(serializeKV(key, value));
        break;
    }
  }

  return lines.join("\n");
};
