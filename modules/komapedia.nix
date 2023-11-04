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
  in
    mkIf config.die-koma.komapedia.enable {
      services = {
        phpfpm.pools.mediawiki = {
          settings = {
            "listen.owner" = mkOverride 75 config.services.nginx.user;
            "listen.group" = mkOverride 75 config.services.nginx.user;
          };
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
          url = "https://${config.die-koma.komapedia.hostName}/wiki/";
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

            # Allow adiitional file extensions
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

            # we currently don't support sending mail.
            $wgEnableEmail = false;
          '';
        };
      };
    };
}
