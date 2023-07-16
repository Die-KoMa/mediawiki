{packages}: {
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
          phpPackage = pkgs.php71;
          settings = {
            "listen.owner" = mkOverride 75 config.services.nginx.user;
            "listen.group" = mkOverride 75 config.services.nginx.user;
          };
        };
        mediawiki = {
          enable = true;
          package = packages.komapedia-mediawiki;
          extensions = let
            path = ../mediawiki/extensions;
          in
            pipe path [
              builtins.readDir
              (filterAttrs (key: val: !hasPrefix "." key && val == "directory"))
              (mapAttrs (_: _: null))
            ];
          skins.VectorV2 = "${cfg.package}/share/mediawiki/skins/VectorV2";

          database = {createLocally = mkDefault false;};
          webserver = "none";
          name = "KoMapedia";
          passwordSender = config.die-koma.komapedia.adminAddr;
          url = "https://${config.die-koma.komapedia.hostName}/wiki/";
          uploadsDir = "${config.die-koma.komapedia.stateDir}/uploads";
          extraConfig = ''
            $smwgConfigFileDir = "${config.die-koma.komapedia.stateDir}";
            #enableSemantics('${config.die-koma.komapedia.semanticsHostName}');
          '';
        };
      };

      systemd.services.mediawiki-init.script = mkOverride 75 ''
        ${pkgs.php71}/bin/php ${config.services.mediawiki.finalPackage}/share/mediawiki/maintenance/update.php --conf ${config.services.phpfpm.pools.mediawiki.phpEnv.MEDIAWIKI_CONFIG} --quick
      '';
    };
}
