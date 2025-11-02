{
  pkgs,
  values,
  ...
}:

let
  username = values.user.username;
  appDir = "/Users/${username}/.local/share/cudgel";
  dataDir = "${appDir}/postgres";
  port = "45678";

  initScript = pkgs.writeShellScript "init-cudgel-postgres" ''
    set -euo pipefail
    mkdir -p "${dataDir}"

    if [ ! -f "${dataDir}/PG_VERSION" ]; then
      echo "Initializing cudgel-postgres in ${dataDir}..."
      ${pkgs.postgresql_17}/bin/initdb -D "${dataDir}" \
        --username="${username}" --encoding=UTF8 --locale=C --no-instructions

      echo "port = ${port}" >> "${dataDir}/postgresql.conf"
      echo "unix_socket_directories = '/tmp'" >> "${dataDir}/postgresql.conf"
      echo "shared_preload_libraries = 'vector'" >> "${dataDir}/postgresql.conf"

      ${pkgs.postgresql_17}/bin/pg_ctl -D "${dataDir}" -l /tmp/cudgel-pgctl.log start
      sleep 2
      ${pkgs.postgresql_17}/bin/createdb -h localhost -p ${port} "${username}" || true
      ${pkgs.postgresql_17}/bin/psql -h localhost -p ${port} -U "${username}" -d postgres \
        -c "CREATE EXTENSION IF NOT EXISTS vector;"
      ${pkgs.postgresql_17}/bin/pg_ctl -D "${dataDir}" stop
    fi
  '';
in
{
  home.packages = [ pkgs.postgresql17Packages.pgvector ];

  home.activation.initCudgelPostgres = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      $DRY_RUN_CMD ${initScript} || true
    '';
  };

  launchd.user.agents."cudgel-postgres" = {
    description = "Cudgel PostgreSQL with pgvector on port ${port}";
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.postgresql_17}/bin/postgres"
        "-D"
        dataDir
        "-p"
        port
      ];
      WorkingDirectory = appDir;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cudgel-postgres.log";
      StandardErrorPath = "/tmp/cudgel-postgres.error.log";
      EnvironmentVariables.PGDATA = dataDir;
    };
  };
}
