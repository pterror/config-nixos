{ pkgs, firefox-transparent, ... }:
{
  enable = true;
  preferences = {
    "gfx.webrender.all" = true; # required to fix transparency on xwayland.
    # transparency is hopelessly broken on native wayland.
    "browser.display.background_color" = "#1c1b2200";
    "browser.display.background_color.dark" = "#1c1b2200";
    "browser.display.foreground_color" = "#ffffff";
    "browser.download.always_ask_before_handling_new_types" = true;
    "browser.download.useDownloadDir" = false;
    "browser.theme.content-theme" = 0; # dark
    "browser.theme.toolbar-theme" = 0; # dark
    "layout.css.prefers-color-scheme.content-override" = 0; # dark
    "font.default.x-western" = "sans-serif";
    "font.name.monospace.x-western" = "FantasqueSansM Nerd Font";
    "font.name.sans-serif.x-western" = "Unicorn Scribbles";
  };
  policies = {
    DontCheckDefaultBrowser = true;
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
      "{bc2166c4-e7a2-46d5-ad9e-342cef57f1f7}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/gloc/latest.xpl";
      };
      "{4a313247-8330-4a81-948e-b79936516f78}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/image-search-options/latest.xpl";
      };
      "{13c9fd7a-58f4-4a28-9ff9-75e54ad1d540}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/local-file-image-viewer/latest.xpl";
      };
      "popup-tab@eight04.blogspot.com" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/popup-tab/latest.xpl";
      };
      "@react-devtools" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpl";
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
    };
  };
}
