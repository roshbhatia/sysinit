{ pkgs, values, ... }:

let
  username = values.user.username;
  appDir = "/Users/${username}/.local/share/cudgel";
  dataDir = "${appDir}/postgres";
  port = "45678";

  startScript = pkgs.writeShellScript "cudgel-postgres-start" ''
    set -euo pipefail

    mkdir -p "${dataDir}"

    if [ ! -f "${dataDir}/PG_VERSION" ]; then
      echo "Initializing cudgel-postgres in ${dataDir}..."
      ${pkgs.postgresql_17}/bin/initdb -D "${dataDir}" \
        --username="${username}" --encoding=UTF8 --locale=C --no-instructions

      cat >> "${dataDir}/postgresql.conf" <<EOF
    port = ${port}
    unix_socket_directories = '/tmp'
    shared_preload_libraries = 'vector'
    EOF

      ${pkgs.postgresql_17}/bin/pg_ctl -D "${dataDir}" -l /tmp/cudgel-pgctl.log start
      sleep 2
      ${pkgs.postgresql_17}/bin/createdb -h localhost -p ${port} "${username}" || true
      ${pkgs.postgresql_17}/bin/psql -h localhost -p ${port} -U "${username}" -d postgres \
        -c "CREATE EXTENSION IF NOT EXISTS vector;"
      ${pkgs.postgresql_17}/bin/pg_ctl -D "${dataDir}" stop
    fi

    exec ${pkgs.postgresql_17}/bin/postgres -D "${dataDir}" -p ${port}
  '';
in
{
  launchd.user.agents."cudgel-postgres" = {
    description = "Cudgel PostgreSQL with pgvector on port ${port}";
    serviceConfig = {
      Program = "${startScript}";
      WorkingDirectory = appDir;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cudgel-postgres.log";
      StandardErrorPath = "/tmp/cudgel-postgres.error.log";
      EnvironmentVariables = {
        PGDATA = dataDir;
      };
    };
  };
}
