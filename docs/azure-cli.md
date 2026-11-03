# Provisionamento e demonstração na Azure com CLI

Os comandos abaixo são exemplos para uma demonstração temporária. Execute-os no PowerShell com Azure CLI instalado e autenticado. Confira a região, a disponibilidade da VM e as políticas da sua assinatura antes de criar recursos.

## 1. Definir nomes e criar o grupo de recursos

```powershell
az login
az account show --output table

$resourceGroup = "rg-reactio-cloud-demo"
$location = "brazilsouth"
$vmName = "vm-reactio-demo"
$adminUser = "azureuser"
$vmSize = "Standard_B1s"

az group create --name $resourceGroup --location $location
```

O tamanho `Standard_B1s` é um exemplo; confirme que está disponível e permitido na sua assinatura e região. A criação de uma VM pode gerar custos.

## 2. Criar uma VM Ubuntu sem regra de entrada aberta

```powershell
az vm create `
  --resource-group $resourceGroup `
  --name $vmName `
  --location $location `
  --image Ubuntu2204 `
  --size $vmSize `
  --admin-username $adminUser `
  --generate-ssh-keys `
  --nsg-rule NONE `
  --public-ip-sku Standard
```

O comando gera uma chave SSH local se ela ainda não existir. A regra de entrada é criada separadamente para limitar a exposição.

## 3. Permitir acesso de demonstração apenas do seu IP

O acesso público ao endpoint deve ser temporário. A API desta Sprint não autentica os endpoints editoriais.

```powershell
$myIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
$nicId = az network nic list --resource-group $resourceGroup --query "[0].id" --output tsv
$nsgId = az network nic show --ids $nicId --query "networkSecurityGroup.id" --output tsv
$nsgName = Split-Path $nsgId -Leaf

az network nsg rule create `
  --resource-group $resourceGroup `
  --nsg-name $nsgName `
  --name "AllowReactio8080FromDemoIP" `
  --priority 1100 `
  --direction Inbound `
  --access Allow `
  --protocol Tcp `
  --source-address-prefixes "$myIp/32" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 8080
```

Se o professor precisar acessar diretamente, ajuste a regra para o IP dele durante a demonstração e remova-a depois.

## 4. Instalar Docker e iniciar a API

Este exemplo usa Run Command da VM para evitar abrir SSH. A VM baixa este repositório público e inicializa o submódulo Java.

```powershell
$deployScript = @'
set -eux
apt-get update
apt-get install -y docker.io git
systemctl enable --now docker
git clone --recurse-submodules https://github.com/Eric-devops-tech/Reactio-Cloud.git /opt/reactio-cloud
cd /opt/reactio-cloud
docker build -t reactio-api:demo .
docker volume create reactio-data
docker run -d --name reactio-api --restart unless-stopped -p 8080:8080 -v reactio-data:/app/data reactio-api:demo
'@

az vm run-command invoke `
  --resource-group $resourceGroup `
  --name $vmName `
  --command-id RunShellScript `
  --scripts $deployScript
```

Consultar IP público e testar:

```powershell
$publicIp = az vm show --show-details --resource-group $resourceGroup --name $vmName --query publicIps --output tsv
Write-Output "http://$($publicIp):8080/swagger-ui.html"
Invoke-RestMethod -Uri "http://$($publicIp):8080/api/quiz"
```

## 5. Verificar a VM e os recursos

```powershell
az vm show --show-details --resource-group $resourceGroup --name $vmName --output table
az resource list --resource-group $resourceGroup --output table
```

Grave a tela mostrando a criação com Azure CLI, a API em execução e uma chamada bem-sucedida ao endpoint.

## 6. Remover recursos ao concluir

Revise o nome do grupo antes de executar. A exclusão remove todos os recursos dentro dele, incluindo VM, discos, IP público, rede e NSG.

```powershell
az group delete --name $resourceGroup --yes --no-wait
```

## Referências oficiais

- [Criar uma VM Linux com Azure CLI](https://learn.microsoft.com/azure/virtual-machines/linux/quick-create-cli)
- [Referência `az vm`](https://learn.microsoft.com/cli/azure/vm?view=azure-cli-latest)
- [Executar scripts em uma VM Linux com Run Command](https://learn.microsoft.com/azure/virtual-machines/linux/run-command)
