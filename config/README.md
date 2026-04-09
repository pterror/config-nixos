# Config Management Strategy

This directory contains configs managed via `lib/mkUserConfig.nix` - they're written to the nix store and symlinked to `~/.config/`.

## Managed Configs (in nix store)

- **hyprland.nix** - Window manager config. Benefits from nix templating for package paths (screenshot tool, browser, terminal, etc.)
- **ghostty.nix** - Terminal config. Simple and benefits from nix font references

## NOT Managed (mutable in ~/.config/)

- **fish** - Contains personal/sensitive data (IP addresses, personal abbrs, custom functions). Keep mutable.
- **quickshell** - Hot reload is critical for development workflow. Nix store paths would break this.
- **omf** (oh-my-fish) - Fish theme manager. Restored from backup, no need to template.
- **neovim** - Currently inline in configuration.nix. Simple enough that extraction isn't worth it yet.

## Philosophy

Optimize for:
1. **Understandability** - Explicit paths, no magic auto-imports
2. **Fast eval** - Minimal abstractions, no flake-parts overhead
3. **Practical trade-offs** - Don't force everything into nix if mutable works better
