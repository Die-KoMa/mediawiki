extensionPackages:
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
{
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
      default = "komapedia@komapedia.org";
    };

    stateDir = mkOption {
      type = types.path;
      description = "Path where mediawiki state is kept";
      default = "/var/lib/mediawiki";
    };

    poweredBy = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            link = mkOption {
              description = "Link for the logo";
              type = types.str;
            };

            logo = mkOption {
              description = "Logo image";
              type = types.str;
            };

            alt = mkOption {
              description = "Alt text for the logo";
              type = types.str;
            };

            height = mkOption {
              description = "Height of the logo";
              default = 31;
              type = types.int;
            };

            width = mkOption {
              description = "Width of the logo";
              default = 88;
              type = types.int;
            };
          };
        }
      );
    };

    mail = mkOption {
      type = types.submodule {
        options = {
          host = mkOption {
            description = "SMTP hostname";
            type = types.str;
            default = "localhost";
          };

          port = mkOption {
            description = "SMTP port";
            type = types.int;
            default = 465;
          };

          domain = mkOption {
            description = "FROM domain";
            type = types.str;
            default = config.networking.fqdn;
          };
        };
      };
      default = { };
    };
  };

  config =
    let
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

      mkLogo = category: key: value: ''
        $wgFooterIcons['${category}']['${key}'] = [
          "src" => "${value.logo}",
          "url" => "${value.link}",
          "alt" => "${value.alt}",
          "height" => "${toString value.height}",
          "width" => "${toString value.width}",
        ];
      '';

      poweredBy = concatStringsSep "\n" (
        mapAttrsToList (mkLogo "poweredby") config.die-koma.komapedia.poweredBy
      );
    in
    mkIf config.die-koma.komapedia.enable {
      services = {
        phpfpm.pools.mediawiki = {
          settings = {
            "listen.owner" = mkOverride 75 config.services.nginx.user;
            "listen.group" = mkOverride 75 config.services.nginx.user;
          };
          phpPackage = lib.mkForce (
            pkgs.php83.withExtensions (
              { all, enabled }:
              enabled
              ++ [
                all.memcached
              ]
            )
          );
          phpOptions = ''
            post_max_size = 100M
            upload_max_filesize = 100M
          '';
          phpEnv.MW_INSTALL_PATH = "${cfg.finalPackage}/share/mediawiki";
        };

        memcached = {
          enable = true;
          maxMemory = 128; # MediaWiki requires >= 80
        };

        mediawiki = {
          enable = true;

          package = extensionPackages.mediawiki;

          extensions =
            (lib.mapAttrs (_: drv: "${drv}") (lib.filterAttrs (k: _: k != "mediawiki") extensionPackages))
            // {
              # in-tree extensions
              Math = null;
              ParserFunctions = null;
              ReplaceText = null;
              VisualEditor = null;
            };

          database = {
            createLocally = mkDefault false;
          };
          webserver = "none";
          name = "KoMapedia";
          passwordSender = config.die-koma.komapedia.adminAddr;
          url = "https://${config.die-koma.komapedia.hostName}";
          uploadsDir = "${config.die-koma.komapedia.stateDir}/images/";
          extraConfig = concatStringsSep "\n" [
            ''
              $smwgConfigFileDir = "${config.die-koma.komapedia.stateDir}";
              #enableSemantics('${config.die-koma.komapedia.semanticsHostName}');

              $wgReadOnlyFile = "${config.die-koma.komapedia.stateDir}/readonly/msg";
              $wgLogo = "/images/komapedia-logo.png";

              $wgEnableEmail = true;
              $wgEnableUserEmail = true; # UPO

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
              $wgFileExtensions[] = 'webp';

              # disable registration
              $wgGroupPermissions['*']['createaccount'] = false;

              $wgGroupPermissions['bureaucrat']['usermerge'] = true;
              $wgGroupPermissions['bureaucrat']['hideuser'] = true;
              $wgShowExceptionDetails = true;
              $wgShowDBErrorBacktrace = true;

              $wgArticlePath = "/wiki/$1";
              $wgUsePathInfo = true;

              # Enable subpages in the main namespace
              $wgNamespacesWithSubpages[NS_MAIN] = true;

              # Enable subpages in the template namespace
              $wgNamespacesWithSubpages[NS_TEMPLATE] = true;

              # Enable string parser functions
              $wgPFEnableStringFunctions = true;

              # it's time to arrive in 2022
              $wgDefaultSkin = 'timeless';
              $wgVectorDefaultSidebarVisibleForAnonymousUser = true;  # but show the sidebar for anonymous users

              # Increase maximum size of server-scaled images
              $wgMaxImageArea = 2.5e7;

              # Caching
              $wgMemCachedServers = [ "${config.services.memcached.listen}:${toString config.services.memcached.port}" ];
              $wgMainCacheType = CACHE_MEMCACHED;
              $wgSessionCacheType = CACHE_DB;  # must be a persistent storage.
              $smwgMainCacheType = CACHE_MEMCACHED;
              $smwgQueryResultCacheType = CACHE_MEMCACHED;
              $smwgEnabledQueryDependencyLinksStore = true;

              # better OpenGraph descriptions
              $wgEnableMetaDescriptionFunctions = true;

              # mail
              $wgPasswordSender = "${config.die-koma.komapedia.adminAddr}";
              $wgEmergencyContact = "${config.die-koma.komapedia.adminAddr}";
              $wgSMTP = [
                'host' => "tlsv1.3://${config.die-koma.komapedia.mail.host}",
                'IDHost' => "${config.die-koma.komapedia.mail.domain}",
                'localhost' => "${config.die-koma.komapedia.mail.domain}",
                'port' => ${toString config.die-koma.komapedia.mail.port},
                'auth' => false,
                'debug' => false,
                'socket_options' => [ 'ssl' => [ 'verify_peer' => false, 'verify_peer_name' => false ]]
              ];

              if (false) {
                error_reporting( -1 );
                ini_set( 'display_errors', 1 );
                $wgShowExceptionDetails = true;
                $wgDebugToolbar = true;
                $wgDevelopmentWarnings = true;
                $wgResourceLoaderDebug = true;
                $egScssCacheType = CACHE_NONE;
                $wgParserCacheType = CACHE_NONE;
                $wgCachePages = false;
              }
            ''
            poweredBy
          ];
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

        wantedBy = [ "multi-user.target" ];
      };
    };
}
