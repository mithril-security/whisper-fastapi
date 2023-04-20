
set -e

SUBSCRIPTION="Microsoft Azure Sponsorship"
RESOURCE_GROUP=TestACIGroup
LOCATION="North Europe"
# ACR_NAME=testacigroupcontainerregistry
IMAGE_VER=v1
IMAGE_NAME=testsev

DOCKER_LOGIN=TODO
DOCKER_PASSWORD=TODO

az account set --subscription "$SUBSCRIPTION"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# ACR_LOGIN_SERVER=$
# az acr create -g "$RESOURCE_GROUP" --name "$ACR_NAME" --sku Basic
# ACR_LOGIN_SERVER=$(
#     az acr show -g "$RESOURCE_GROUP" --name "$ACR_NAME" \
#     | jq -r .loginServer
# )
# ACR_ID=$(
#     az acr show -g "$RESOURCE_GROUP" --name "$ACR_NAME" \
#     | jq -r .id
# )

# echo "[sh] Container registry login server: $ACR_LOGIN_SERVER"

# az acr login --name "$ACR_NAME"

# az identity create -g "$RESOURCE_GROUP" --name acr-pull-id

# USERID=$(az identity show -g "$RESOURCE_GROUP" --name acr-pull-id --query id --output tsv)
# SPID=$(az identity show -g "$RESOURCE_GROUP" --name acr-pull-id --query principalId --output tsv)

# az role assignment create --assignee "$SPID" --scope "$ACR_ID" --role acrpull

# DOCKER_IMAGE="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_VER"
DOCKER_IMAGE="registry.mithrilsecurity.io/sev/$IMAGE_NAME:$IMAGE_VER"

docker build -t "$DOCKER_IMAGE" -f ./sev.dockerfile ..
docker push "$DOCKER_IMAGE"

echo "[sh] Docker image name: $DOCKER_IMAGE"

STORAGE_ACCOUNT="modelstorage223"

az storage account create \
    -g "$RESOURCE_GROUP" \
    --name "$STORAGE_ACCOUNT" \
    --location "$LOCATION" \
    --sku Standard_LRS

az storage share create \
  --name modelstorageshare \
  --account-name "$STORAGE_ACCOUNT"

STORAGE_KEY=$(
  az storage account keys list -g "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" --query "[0].value" --output tsv
)
echo "Storage Key is '$STORAGE_KEY'."

POLICY=$(
  az confcom acipolicygen --print-policy --image "$DOCKER_IMAGE"
)
cat template.json | jq ".resources[0].properties.confidentialComputeProperties.ccePolicy=\"$POLICY\"" > template-filled.json

echo "[sh] Deploying"

az deployment group create \
  -g "$RESOURCE_GROUP" \
  --name helloworld \
  --template-file ./template-filled.json \
  --parameters registryServer="registry.mithrilsecurity.io" \
  --parameters registryUsername="$DOCKER_LOGIN" \
  --parameters registryPassword="$DOCKER_PASSWORD" \
  --parameters volumeShareName=modelstorageshare \
  --parameters volumeAccountKey="$STORAGE_KEY" \
  --parameters volumeAccountName="$STORAGE_ACCOUNT" \
  --parameters name=helloworld \
  --parameters location="$LOCATION" \
  --parameters image="$DOCKER_IMAGE" \
  --parameters port=22 \
  --parameters cpuCores=1 \
  --parameters memoryInGb=8 \
  --parameters restartPolicy=Always

# Teardown:
# az group delete --name "$RESOURCE_GROUP"
