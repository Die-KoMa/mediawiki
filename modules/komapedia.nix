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

          extensions = {
            SemanticMediaWiki = pkgs.fetchFromGitHub {
              owner = "SemanticMediaWiki";
              repo = "SemanticMediaWiki";
              rev = "5c94879171d5f741b896828c25a9f2bb07a03dff";
              sha256 = "ZNnd3fB4MhDd4xBHivBKWwVjTT0j/Jy2X3v7LFjkrcQ=";
            };

            SemanticResultFormats = pkgs.fetchFromGitHub {
              owner = "SemanticMediaWiki";
              repo = "SemanticResultFormats";
              rev = "d5196722a56f9b65475be68d1e97063d7b975cb9";
              sha256 = "uXgNLw7484Bvns2Aa57EuFmNnfeikNzLQIf+F/KNN64=";
            };

            PageForms = pkgs.fetchFromGitHub {
              owner = "wikimedia";
              repo = "mediawiki-extensions-PageForms";
              rev = "f90d67ecc2c111e82db454c71592c83384ff9704";
              sha256 = "m9e0uQtVdQkMZLwGLb9BOC/bsUpTs0V1fg9Tcuo6xiY=";
            };
          };

          database = {createLocally = mkDefault false;};
          webserver = "none";
          name = "KoMapedia";
          passwordSender = config.die-koma.komapedia.adminAddr;
          url = "https://${config.die-koma.komapedia.hostName}/wiki/";
          uploadsDir = "${config.die-koma.komapedia.stateDir}/uploads";
          extraConfig = ''
            $smwgConfigFileDir = "${config.die-koma.komapedia.stateDir}";
            enableSemantics('${config.die-koma.komapedia.semanticsHostName}');
          '';
        };
      };

      # systemd.services.mediawiki-init.script = mkOverride 75 ''
      #   ${pkgs.php71}/bin/php ${config.services.mediawiki.finalPackage}/share/mediawiki/maintenance/update.php --conf ${config.services.phpfpm.pools.mediawiki.phpEnv.MEDIAWIKI_CONFIG} --quick
      # '';
    };
}
