deploy:
	./scripts/deploy.sh


gpu:
	./scripts/gpu

plan:
	terraform -chdir=terraform/dep-staging plan \
		-var azure_client_id=${AZURE_CLIENT_ID} \
		-var azure_client_secret=${AZURE_CLIENT_SECRET} \
		-var azure_tenant_id=${AZURE_TENANT_ID} \
		-var pc_resources_kv=dep-staging-secrets \
		-var pc_resources_rg=dep-staging

apply:
	terraform -chdir=terraform/dep-staging apply \
		-var azure_client_id=${AZURE_CLIENT_ID} \
		-var azure_client_secret=${AZURE_CLIENT_SECRET} \
		-var azure_tenant_id=${AZURE_TENANT_ID} \
		-var pc_resources_kv=dep-staging-secrets \
		-var pc_resources_rg=dep-staging
