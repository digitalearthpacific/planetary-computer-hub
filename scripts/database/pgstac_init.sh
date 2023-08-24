#!/usr/bin/env bash

set -xe

# Author: Alex Leith
# Date: 2022-01-18
# Copied from Nikita Gandhi and Julia Yun

export LC_CTYPE=C

# Random password generator from https://gist.github.com/earthgecko/3089509
random-string()
{
    cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-32} | head -n 1
}

if [[ -z ${DB_HOSTNAME} || -z ${ADMIN_PASSWORD} || -z ${ADMIN_USERNAME} ]]; then
  echo "Please provide following env variables: DB_HOSTNAME, ADMIN_PASSWORD, ADMIN_USERNAME"
  exit 1;
fi

NEW_DB=pgstac
PGSTAC_ADMIN=pgstac_admin
PGSTAC_READ=pgstac_read
PGSTAC_INGEST=pgstac_ingest

DB_PORT=${DB_PORT:-"5432"}

# Create pgstac db as $ADMIN_USERNAME User
echo "Creating pgstac DB"
PGPASSWORD=${ADMIN_PASSWORD} createdb -h $DB_HOSTNAME -p $DB_PORT -U ${ADMIN_USERNAME} $NEW_DB || true


# create extension PostGIS if not exist
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c "CREATE EXTENSION IF NOT EXISTS postgis ;"

exit 0
# Run pypgstac migrate, copied from here: https://github.com/aodn/aodn-stac/blob/main/migrate.sh
# This results three roles being created: pgstac_admin, pgstac_read, pgstac_ingest (defined as constants above)
# pypgstac migrate --dsn "postgres://superadmin:SECRET@localhost/pgstac
# pypgstac migrate --dsn "postgres://superadmin\@dep-staging-postgres:${ADMIN_PASSWORD}@$DB_HOSTNAME/$NEW_DB"

# Add/reset password for $PGSTAC_ADMIN role
echo "Resetting password for $PGSTAC_ADMIN"
admin_random=$(random-string 16)
echo admin_random: ${admin_random}
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c "ALTER ROLE $PGSTAC_ADMIN LOGIN PASSWORD '$admin_random';"

# Change owner of $NEW_DB from $ADMIN_USERNAME to $PGSTAC_ADMIN
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c "ALTER DATABASE $NEW_DB OWNER TO $PGSTAC_ADMIN;"

# Add/reset password for $PGSTAC_READ role
echo "Resetting password for $PGSTAC_READ"
read_random=$(random-string 16)
echo read_random: ${read_random}
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c "ALTER ROLE $PGSTAC_READ LOGIN PASSWORD '$read_random';"

# Add/reset password for $PGSTAC_INGEST role
echo "Resetting password for $PGSTAC_INGEST"
ingest_random=$(random-string 16)
echo ingest_random: ${ingest_random}
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c "ALTER ROLE $PGSTAC_INGEST LOGIN PASSWORD '$ingest_random';"

# Create or update the secrets for the three pgstac users...
echo "Creating/updating ${PGSTAC_ADMIN} user credentials to secrets manager"
az keyvault secret set \
  --name=dep--grafana-db-secret \
  --vault-name=dep-staging-secrets \
  --value="${PGSTAC_ADMIN}@dep-staging-postgres:${admin_random}"

echo "Creating/updating ${PGSTAC_READ} user credentials to secrets manager"
az keyvault secret set \
  --name=dep--grafana-db-secret \
  --vault-name=dep-staging-secrets \
  --value="${PGSTAC_READ}@dep-staging-postgres:${read_random}"

echo "Creating/updating ${PGSTAC_INGEST} user credentials to secrets manager"
az keyvault secret set \
  --name=dep--grafana-db-secret \
  --vault-name=dep-staging-secrets \
  --value="${PGSTAC_INGEST}@dep-staging-postgres:${ingest_random}"
