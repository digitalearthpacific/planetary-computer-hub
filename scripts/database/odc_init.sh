#!/usr/bin/env bash

set -xe

# Author: Alex Leith
# Date: 2023-12-18

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

NEW_DB=odc
ODC_ADMIN=odc_admin
ODC_READ=odc_read

DB_PORT=${DB_PORT:-"5432"}

# Create pgstac db as $ADMIN_USERNAME User
echo "Creating pgstac DB"
PGPASSWORD=${ADMIN_PASSWORD} createdb -h $DB_HOSTNAME -p $DB_PORT -U ${ADMIN_USERNAME} $NEW_DB || true

# create extension PostGIS if not exist
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c \
    "CREATE EXTENSION IF NOT EXISTS postgis ;"

# Create login role if it does not exist
echo "Creating admin role"
createuser -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$ADMIN_USERNAME" $ODC_ADMIN || true
echo "Creating read role"
createuser -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$ADMIN_USERNAME" $ODC_READ || true

# Reset passwords
echo "Resetting admin role password"
admin_random=$(random-string 16)
echo admin_random: ${admin_random}
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c \
    "ALTER USER $ODC_ADMIN WITH PASSWORD '$admin_random'"

echo "Resetting read role password"
read_random=$(random-string 16)
echo read_random: ${read_random}
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c \
    "ALTER USER $ODC_READ WITH PASSWORD '$read_random'"

# Change the owner of $NEW_DB from $ADMIN_USERNAME to $ODC_ADMIN
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c \
    "GRANT $ODC_ADMIN TO superadmin; ALTER DATABASE $NEW_DB OWNER TO $ODC_ADMIN;"

# Grant privileges to $ODC_READ
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c \
    "GRANT CONNECT ON DATABASE $NEW_DB TO $ODC_READ;"

# Grant select privileges on all schemas to $ODC_READ
# public
PGPASSWORD=${ADMIN_PASSWORD} psql -h $DB_HOSTNAME -p $DB_PORT --username ${ADMIN_USERNAME} -d $NEW_DB -c \
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $ODC_READ;"

# Manual grants...
# GRANT USAGE ON SCHEMA agdc TO odc_read;
# GRANT SELECT ON ALL TABLES IN SCHEMA agdc TO odc_read;

# GRANT USAGE ON SCHEMA wms TO odc_read;
# GRANT SELECT ON ALL TABLES IN SCHEMA wms TO odc_read;
# ... after schema creation

# Store the credentials on a secret on Azure
echo "Adding credentials to secrets manager"
# Create or update the secret...
az keyvault secret set \
  --name=dep--odc-admin-db-secret \
  --vault-name=dep-staging-secrets \
  --value="${ODC_ADMIN}:${admin_random}"

az keyvault secret set \
    --name=dep--odc-read-db-secret \
    --vault-name=dep-staging-secrets \
    --value="${ODC_READ}:${read_random}"
