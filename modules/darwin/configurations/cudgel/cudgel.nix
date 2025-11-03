{ pkgs, values, ... }:

let
  username = values.user.username;
  cudgelBaseDir = "/Users/${username}/.local/share/cudgel";
  pgDataDir = "${cudgelBaseDir}/postgres";
  pgPort = "45678";

  postgresql = pkgs.postgresql_17.withPackages (ps: [ ps.pgvector ]);

  startScript = pkgs.writeShellScript "cudgel-postgres-start" ''
    set -euo pipefail

    mkdir -p "${pgDataDir}"

    if [ ! -f "${pgDataDir}/PG_VERSION" ]; then
      echo "Initializing cudgel-postgres in ${pgDataDir}..."
      ${postgresql}/bin/initdb -D "${pgDataDir}" \
        --username="${username}" --encoding=UTF8 --locale=C --no-instructions

      cat >> "${pgDataDir}/postgresql.conf" <<EOF
    port = ${pgPort}
    unix_socket_directories = '/tmp'
    shared_preload_libraries = 'vector'
    EOF

      ${postgresql}/bin/pg_ctl -D "${pgDataDir}" -l /tmp/cudgel-pgctl.log start
      sleep 2
      ${postgresql}/bin/createdb -h localhost -p ${pgPort} "${username}" || true
      ${postgresql}/bin/psql -h localhost -p ${pgPort} -U "${username}" -d postgres \
        -c "CREATE EXTENSION IF NOT EXISTS vector;"
      ${postgresql}/bin/pg_ctl -D "${pgDataDir}" stop
    fi

    exec ${postgresql}/bin/postgres -D "${pgDataDir}" -p ${pgPort}
  '';
in
{
  launchd.user.agents.cudgel_postgres = {
    serviceConfig = {
      Program = toString startScript;
      WorkingDirectory = cudgelBaseDir;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cudgel-postgres.log";
      StandardErrorPath = "/tmp/cudgel-postgres.error.log";
      EnvironmentVariables = {
        PGDATA = pgDataDir;
      };
    };
  };
}
