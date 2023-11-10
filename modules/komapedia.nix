extensionPackages: {
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
    semanticsHostName = mkOption {
      type = types.str;
      description = "Hostname passed to `enableSemantics` (should not be changed and may therefore diverge from `hostName`";
      default = "old.die-koma.org";
    };
    adminAddr = mkOption {
      type = types.str;
      description = "Mail address for the admin user";
      default = "homepage@die-koma.org";
    };
    stateDir = mkOption {
      type = types.path;
      description = "Path where mediawiki state is kept";
      default = "/var/lib/mediawiki";
    };
  };

  config = let
    cfg = config.services.mediawiki;

    pool = config.services.phpfpm.pools.mediawiki;
    php = pool.phpPackage;
    mediawikiConfig = pool.phpEnv.MEDIAWIKI_CONFIG;
    jobrunner = pkgs.writeShellScript "mw-jobrunner" ''
      RUN_JOBS="${cfg.finalPackage}/share/mediawiki/maintenance/runJobs.php --conf ${mediawikiConfig} --maxtime=3600"
      while true; do
        ${php}/bin/php $RUN_JOBS --type="enotifNotify"
        ${php}/bin/php $RUN_JOBS --wait --maxjobs=20
        sleep 10
      done
    '';
  in
    mkIf config.die-koma.komapedia.enable {
      services = {
        phpfpm.pools.mediawiki = {
          settings = {
            "listen.owner" = mkOverride 75 config.services.nginx.user;
            "listen.group" = mkOverride 75 config.services.nginx.user;
          };
          phpPackage = pkgs.php81.withExtensions ({
            all,
            enabled,
          }:
            enabled ++ [all.memcached]);
        };

        memcached = {
          enable = true;
          maxMemory = 128; # MediaWiki requires >= 80
        };

        mediawiki = {
          enable = true;

          extensions =
            (lib.mapAttrs (_: drv: "${drv}") extensionPackages)
            // {
              # in-tree extensions
              Math = null;
              ParserFunctions = null;
              Renameuser = null;
              ReplaceText = null;
              VisualEditor = null;
            };

          database = {createLocally = mkDefault false;};
          webserver = "none";
          name = "KoMapedia";
          passwordSender = config.die-koma.komapedia.adminAddr;
          url = "https://${config.die-koma.komapedia.hostName}";
          uploadsDir = "${config.die-koma.komapedia.stateDir}/images/";
          extraConfig = ''
            $smwgConfigFileDir = "${config.die-koma.komapedia.stateDir}";
            #enableSemantics('${config.die-koma.komapedia.semanticsHostName}');

            $wgReadOnlyFile = "${config.die-koma.komapedia.stateDir}/readonly/msg";
            $wgLogo = "$wgResourceBasePath/resources/assets/komapedia_logo.png";

            $wgEnableEmail = true;
            $wgEnableUserEmail = true; # UPO
            $wgEmergencyContact = "homepage@die-koma.org";
            $wgPasswordSender = "homepage@die-koma.org";

            $wgEnotifUserTalk = true; # UPO
            $wgEnotifWatchlist = true; # UPO
            $wgEmailAuthentication = true;

            $wgLanguageCode = "de";

            # Allow Display names to differ from the url
            $wgRestrictDisplayTitle = false;

            # Allow additional file extensions
            $wgFileExtensions[] = 'pdf';
            $wgFileExtensions[] = 'tex';
            $wgFileExtensions[] = 'txt';
            $wgFileExtensions[] = 'svg';
            $wgFileExtensions[] = 'zip';

            # disable registration
            $wgGroupPermissions['*']['createaccount'] = false;

            $wgGroupPermissions['bureaucrat']['usermerge'] = true;
            $wgGroupPermissions['bureaucrat']['hideuser'] = true;
            $wgShowExceptionDetails = true;
            $wgShowDBErrorBacktrace = true;

            $wgArticlePath = "/wiki/$1";
            $wgUsePathInfo = true;

            # we currently don't support sending mail.
            $wgEnableEmail = false;

            # Caching
            $wgMainCacheType = CACHE_MEMCACHED;
            $smwgMainCacheType = CACHE_MEMCACHED;
            $smwgQueryResultCacheType = CACHE_MEMCACHED;
            $smwgEnabledQueryDependencyLinksStore = true;
          '';
        };
      };

      systemd.services.mw-jobqueue = {
        description = "MediaWiki Job runner";

        serviceConfig = {
          ExecStart = jobrunner;
          Nice = 10;
          ProtectSystem = "full";
          User = "mediawiki";
          OOMScoreAdjust = 200;
          StandardOutput = "journal";
        };

        wantedBy = ["multi-user.target"];
      };
    };
}
