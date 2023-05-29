{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options.die-koma.komapedia = {
    enable = mkEnableOption "Configure the KoMaPedia MediaWiki";
    hostName = mkOption {
      type = types.str;
      description = "Hostname for the MediaWiki";
      default = "de.komapedia.org";
    };
    adminAddr = mkOption {
      type = types.str;
      description = "Mail address for the admin user";
      default = "homepage@die-koma.org";
    };
  };

  config = let
    cfg = config.services.mediawiki;

    cacheDir = "/var/cache/mediawiki";
    stateDir = "/var/lib/mediawiki";

    mediawikiConfig = pkgs.writeText "LocalSettings.php" ''
      <?php
        # Protect against web entry
        if ( !defined( 'MEDIAWIKI' ) ) {
          exit;
        }
        $wgSitename = "${cfg.name}";
        $wgMetaNamespace = false;
        ## The URL base path to the directory containing the wiki;
        ## defaults for all runtime URL paths are based off of this.
        ## For more information on customizing the URLs
        ## (like /w/index.php/Page_title to /wiki/Page_title) please see:
        ## https://www.mediawiki.org/wiki/Manual:Short_URL
        $wgScriptPath = "";
        ## The protocol and server name to use in fully-qualified URLs
        $wgServer = "https://${config.die-koma.komapedia.hostName}";
        ## The URL path to static resources (images, scripts, etc.)
        $wgResourceBasePath = $wgScriptPath;
        ## The URL path to the logo.  Make sure you change this from the default,
        ## or else you'll overwrite your logo when you upgrade!
        $wgLogo = "$wgResourceBasePath/resources/assets/wiki.png";
        ## UPO means: this is also a user preference option
        $wgEnableEmail = true;
        $wgEnableUserEmail = true; # UPO
        $wgEmergencyContact = "${config.die-koma.komapedia.adminAddr}";
        $wgPasswordSender = $wgEmergencyContact;
        $wgEnotifUserTalk = false; # UPO
        $wgEnotifWatchlist = false; # UPO
        $wgEmailAuthentication = true;
        ## Database settings
        $wgDBtype = "${cfg.database.type}";
        $wgDBserver = "${cfg.database.host}:${
        if cfg.database.socket != null
        then cfg.database.socket
        else toString cfg.database.port
      }";
        $wgDBname = "${cfg.database.name}";
        $wgDBuser = "${cfg.database.user}";
        ${
        optionalString (cfg.database.passwordFile != null)
        ''$wgDBpassword = file_get_contents("${cfg.database.passwordFile}");''
      }
        ${
        optionalString
        (cfg.database.type == "mysql" && cfg.database.tablePrefix != null) ''
          # MySQL specific settings
          $wgDBprefix = "${cfg.database.tablePrefix}";
        ''
      }
        ${
        optionalString (cfg.database.type == "mysql") ''
          # MySQL table options to use during installation or update
          $wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";
        ''
      }
        ## Shared memory settings
        $wgMainCacheType = CACHE_NONE;
        $wgMemCachedServers = [];
        ${
        optionalString (cfg.uploadsDir != null) ''
          $wgEnableUploads = true;
          $wgUploadDirectory = "${cfg.uploadsDir}";
        ''
      }
        $wgUseImageMagick = true;
        $wgImageMagickConvertCommand = "${pkgs.imagemagick}/bin/convert";
        # InstantCommons allows wiki to use images from https://commons.wikimedia.org
        $wgUseInstantCommons = false;
        # Periodically send a pingback to https://www.mediawiki.org/ with basic data
        # about this MediaWiki instance. The Wikimedia Foundation shares this data
        # with MediaWiki developers to help guide future development efforts.
        $wgPingback = true;
        ## If you use ImageMagick (or any other shell command) on a
        ## Linux server, this will need to be set to the name of an
        ## available UTF-8 locale
        $wgShellLocale = "C.UTF-8";
        ## Set $wgCacheDirectory to a writable directory on the web server
        ## to make your wiki go slightly faster. The directory should not
        ## be publically accessible from the web.
        $wgCacheDirectory = "${cacheDir}";
        # Site language code, should be one of the list in ./languages/data/Names.php
        $wgLanguageCode = "de";
        $wgSecretKey = file_get_contents("${stateDir}/secret.key");
        # Changing this will log out all existing sessions.
        $wgAuthenticationTokenVersion = "";
        ## For attaching licensing metadata to pages, and displaying an
        ## appropriate copyright notice / icon. GNU Free Documentation
        ## License and Creative Commons licenses are supported so far.
        $wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
        $wgRightsUrl = "";
        $wgRightsText = "";
        $wgRightsIcon = "";
        # Path to the GNU diff3 utility. Used for conflict resolution.
        $wgDiff = "${pkgs.diffutils}/bin/diff";
        $wgDiff3 = "${pkgs.diffutils}/bin/diff3";
        # Enabled skins.
        ${
        concatStringsSep "\n"
        (mapAttrsToList (k: v: "wfLoadSkin('${k}');") cfg.skins)
      }
        # Enabled extensions.
        ${
        concatStringsSep "\n"
        (mapAttrsToList (k: v: "wfLoadExtension('${k}');") cfg.extensions)
      }
        # End of automatically generated settings.
        # Add more configuration options below.
        ${cfg.extraConfig}
    '';
  in
    mkIf config.die-koma.komapedia.enable {
      users.groups.wwwrun = {};

      services = {
        phpfpm.pools.mediawiki = {
          phpPackage = pkgs.php71;
          settings = {
            "listen.owner" = mkOverride 75 config.services.nginx.user;
            "listen.group" = mkOverride 75 config.services.nginx.user;
          };
        };
        mediawiki = rec {
          enable = true;
          package = pkgs.komapedia-mediawiki;
          extensions = pipe "${package}/share/mediawiki/extensions" [
            builtins.readDir
            (filterAttrs (key: val: !hasPrefix "." key && val == "directory"))
            (mapAttrs (_: _: null))
          ];
          skins.VectorV2 = "${cfg.package}/share/mediawiki/skins/VectorV2";
          database = {createLocally = mkDefault false;};
          webserver = "none";
          url = "https://${config.die-koma.komapedia.hostName}/wiki/";
        };
      };

      systemd.services.mediawiki-init.script = mkOverride 75 ''
        ${pkgs.php71}/bin/php ${config.services.mediawiki.package}/share/mediawiki/maintenance/update.php --conf ${mediawikiConfig} --quick
      '';
    };
}
