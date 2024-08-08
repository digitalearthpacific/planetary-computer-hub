deploy:
	./scripts/deploy.sh


gpu:
	./scripts/gpu


# -var azure_client_id=${AZURE_CLIENT_ID} \
# -var azure_client_secret=${AZURE_CLIENT_SECRET} \
# -var azure_tenant_id=${AZURE_TENANT_ID} \

plan:
	terraform -chdir=terraform/dep-staging plan \
		-var pc_resources_kv=dep-staging-secrets \
		-var pc_resources_rg=dep-staging

apply:
	terraform -chdir=terraform/dep-staging apply \
		-var pc_resources_kv=dep-staging-secrets \
		-var pc_resources_rg=dep-staging

init:
	terraform -chdir=terraform/dep-staging init -upgrade


