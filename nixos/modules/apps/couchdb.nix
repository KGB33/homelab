{self, ...}: {
  flake.modules.nixos.couchdb = {config, ...}: {
    imports = with self.modules.nixos; [sops];

    sops.secrets.couchdb_admin_ini = {
      sopsFile = ../../secrets/couchdbAdmin.ini;
      format = "binary";
      owner = config.services.couchdb.user;
      group = config.services.couchdb.group;
      mode = "0600";
      restartUnits = ["couchdb.service"];
    };

    services.couchdb = {
      enable = true;
      bindAddress = "127.0.0.1";
      port = 5984;
      extraConfigFiles = [config.sops.secrets.couchdb_admin_ini.path];
      extraConfig = ''
        [httpd]
        enable_cors = true

        [chttpd]
        enable_cors = true
        bind_address = 127.0.0.1

        [cors]
        origins = app://obsidian.md,capacitor://localhost,http://localhost
        credentials = true
        headers = accept, authorization, content-type, origin, referer
        methods = GET, PUT, POST, HEAD, DELETE

        [cluster]
        n = 1
        q = 1
      '';
    };
  };
}
