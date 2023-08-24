#!/usr/bin/env sh

set -xe

# Author: Alex Leith
# Date: 2023-08-22
# Copied from Nikita Gandhi

export LC_CTYPE=C

# Random password generator from https://gist.github.com/earthgecko/3089509
random-string()
{
    cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-32} | head -n 1
}

NEW_DB=grafana

# Create grafana login role if it does not exist
echo "Creating grafana login role"
createuser $NEW_DB || true

# Reset grafana DB Password
echo "Resetting grafana DB user password"
random=$(random-string 16)
echo random: ${random}
psql -d postgres -c "ALTER USER $NEW_DB WITH PASSWORD '$random'"

# Create grafana db as grafana User
echo "Creating grafana DB as grafana user"
createdb $NEW_DB || true
psql -d $NEW_DB -c "GRANT $NEW_DB TO superadmin"
psql -d $NEW_DB -c "ALTER DATABASE $NEW_DB OWNER TO $NEW_DB"

echo "Adding grafana admin user credentials to secrets manager"
# Create or update the secret...
az keyvault secret set \
  --name=dep--grafana-db-secret \
  --vault-name=dep-staging-secrets \
  --value="${NEW_DB}@dep-staging-postgres:${random}"
