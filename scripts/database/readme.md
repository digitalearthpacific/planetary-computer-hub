# Database initialisation scripts

## How to use them

First you must be able to connect to Kubernetes and run commands like `kubectl get pods -A`.

When you can connect, run this command to set up port forwarding from the DB Proxy:

`kubectl port-forward deployment/pg-proxy 5432:5432`

Now you can connect from your local machine. Make sure you have postgres installed, then you
should export the appropriate credentials and can connect with `psql` or PGAdmin.

The scripts require three environment variables to be set:

* DB_HOSTNAME, which is probably `localhost`
* ADMIN_PASSWORD, which you can get from the secret `db-admin`
* ADMIN_USERNAME, which is also in `db-admin`.

To get the creds, you can run this: `kubectl -n default get secret db-admin -o yaml | ksd`

Test your connection with:

`PGPASSWORD=${ADMIN_PASSWORD} psql -h ${DB_HOSTNAME} -U ${ADMIN_USERNAME} -d rimrep`

If you can connect, then you can run the init script.
