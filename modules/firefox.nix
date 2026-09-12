{ pkgs, my-config, inputs, ... }:
{
  enable = true;
  wrapperConfig = {
    speechSynthesisSupport = true;
  };
  preferences = {
    "browser.tabs.allow_transparent_browser" = true; # transparency
    "browser.tabs.inTitlebar" = 1; # required for transparency
    # transparency is hopelessly broken on native wayland.
    "browser.display.background_color" = "#1c1b2200";
    "browser.display.background_color.dark" = "#1c1b2200";
    "browser.display.foreground_color" = "#ffffff";
    "browser.download.always_ask_before_handling_new_types" = true;
    "browser.download.useDownloadDir" = false;
    "browser.theme.content-theme" = 0; # dark
    "browser.theme.toolbar-theme" = 0; # dark
    "layout.css.prefers-color-scheme.content-override" = 0; # dark
    # font.* prefs moved to profile user.js: policies.json can't set them,
    # Firefox's policy engine blocks any "font." pref regardless of lock status.
    "browser.eme.ui.enabled" = false; # disable DRM ui. media.eme.enabled is disabled by default
    "media.eme.enabled" = true; # allow DRM playback despite disabling the UI above
    "dom.events.testing.asyncClipboard" = true; # paste support for dance for vscode
    # https://www.reddit.com/r/FirefoxCSS/comments/105xnku/sidebar_autohides_when_trying_to_move_tabs/
    "widget.gtk.ignore-bogus-leave-notify" = 1;

    # privacy/network hardening
    # network.proxy.* removed: policies.json locks these, which blocks the
    # WebExtensions proxy API entirely (breaks Proton VPN's extension, "Not
    # able to control the browser network settings"). Set proxy manually in
    # about:config (like font.* prefs) if you want the Tor SOCKS proxy back.
    "media.peerconnection.ice.default_address_only" = true; # prevent WebRTC leaking local IPs
    "media.peerconnection.ice.no_host" = true;
    "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
    "network.dns.disablePrefetch" = true;
    "network.prefetch-next" = false;
    "network.http.speculative-parallel-limit" = 0;

    # misc UI/behavior
    "browser.cache.disk.capacity" = 8000000;
    "browser.cache.disk.smart_size.enabled" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.toolbars.bookmarks.visibility" = "never";
    "layout.spellcheckDefault" = 0;
    "security.dialog_enable_delay" = 0;
    "accessibility.typeaheadfind.flashBar" = 0;
    "findbar.highlightAll" = true;
    "devtools.chrome.enabled" = true;
    "devtools.debugger.remote-enabled" = true;
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
      #"@react-devtools" = {
      #  installation_mode = "force_installed";
      #  install_url = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpl";
      #};
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpl";
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
      "deArrow@ajay.app" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/dearrow/latest.xpl";
      };
      "jid1-xUfzOsOFlzSOXg@jetpack" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/reddit-enhancement-suite/latest.xpl";
      };
      "vpn@proton.ch" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpl";
      };
      "{cb31ec5d-c49a-4e5a-b240-16c767444f62}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/indie-wiki-buddy/latest.xpl";
      };
      "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/video-downloadhelper/latest.xpl";
      };
      "{799c0914-748b-41df-a25c-22d008f9e83f}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/web-scrobbler/latest.xpl";
      };
      "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/search_by_image/latest.xpl";
      };
      "{d835e0f8-dc63-4800-8036-80e25890fb41}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/oneko/latest.xpl";
      };
    };
  };
}
