{ pkgs, inputs, ... }:
{
  enable = true;
  package = inputs.firefox-transparent.packages.${pkgs.system}.default;
  policies = {
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;
    DisableFirefoxAccounts = false;
    NoDefaultBookmarks = true;
    DontCheckDefaultBrowser = true;
    UserMessaging = {
      ExtensionRecommendations = false;
      SkipOnboarding = true;
    };
    ExtensionUpdate = true;
    ExtensionSettings = {
      "addon@darkreader.org" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpl";
      };
      "maksimovic@outlook.com" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/github-whitespace-disabler/latest.xpl";
      };
      "{4a313247-8330-4a81-948e-b79936516f78}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/image-search-options/latest.xpl";
      };
      "popup-tab@eight04.blogspot.com" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/popup-tab/latest.xpl";
      };
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpl";
      };
      "{3c078156-979c-498b-8990-85f7987dd929}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpl";
      };
      "{145b460b-95c7-4d6c-800f-351bd1d5471d}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/screen-recorder/latest.xpl";
      };
      "sponsorBlocker@ajay.app" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpl";
      };
      "firefox-extension@steamdb.info" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/steam-database/latest.xpl";
      };
      "firefox@tampermonkey.net" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpl";
      };
      "uBlock0@raymondhill.net" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpl";
      };
      "{0d7cafdd-501c-49ca-8ebb-e3341caaa55e}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-nonstop/latest.xpl";
      };
      "{2766e9f7-7bf2-4c72-81b9-d119eb54c753}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/remove-youtube-shorts/latest.xpl";
      };
    };
  };
  profiles = {
    me = {
      id = 0;
      name = "me";
      search = {
        force = true;
	default = "Google";
	engines = {
          Bing.metaData.hidden = true;
          DuckDuckGo.metaData.hidden = true;
	  eBay.metaData.hidden = true;
	  "Wikipedia (en)".metaData.hidden = true;
	};
      };
      userChrome = builtins.readFile ./firefox/userChrome.css;
      userContent = builtins.readFile ./firefox/userContent.css;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # userChrome.css, userContent.css
        "browser.tabs.inTitlebar" = 1; # required for transparency
        "gfx.webrender.all" = true; # fix transparency on xwayland
        # transparency is hopelessly broken on native wayland.
        # "gfx.webrender.software" = true; # fix missing glyphs in url bar
        "browser.display.background_color" = "#1c1b2200";
        "browser.display.background_color.dark" = "#1c1b2200";
        "browser.display.foreground_color" = "#FBFBFE";
        "browser.download.always_ask_before_handling_new_types" = true;
        "browser.download.useDownloadDir" = false;
        # https://www.reddit.com/r/FirefoxCSS/comments/105xnku/sidebar_autohides_when_trying_to_move_tabs/
        "widget.gtk.ignore-bogus-leave-notify" = 1;
        "browser.theme.content-theme" = 0; # dark
        "browser.theme.toolbar-theme" = 0; # dark
        "layout.css.prefers-color-scheme.content-override" = 0; # dark
        "font.default.x-western" = "sans-serif";
        "font.name-list.monospace.x-western" = "Monofur Nerd Font";
        "font.name-list.sans-serif.x-western" = "Unicorn Scribbles";
        "font.name-list.cursive.x-western" = "Unicorn Scribbles";
      };
    };
  };
}
