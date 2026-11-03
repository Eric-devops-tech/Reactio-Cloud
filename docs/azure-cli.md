# Azure CLI: provisionamento e demonstração

Comandos PowerShell usados nesta entrega e passos para reproduzir em uma implantação nova. Recursos Azure podem gerar custos.

## Configuração criada

Grupo `rg-reactio-cloud-demo-20261103`, Chile Central (`chilecentral`), VM `vm-reactio-demo`, Ubuntu 22.04 (`Ubuntu2204`), zona 3, tamanho `Standard_B2s_v2`, usuário `azureuser`. Chave SSH gerada pelo CLI; SSH não foi aberto. O container `reactio-api` publica TCP 8080 e persiste H2 no volume `reactio-data`.

## 1. Login e grupo

```powershell
az login
az account show --output table
$resourceGroup = "rg-reactio-cloud-demo-20261103"
$location = "chilecentral"
$vmName = "vm-reactio-demo"
az group create --name $resourceGroup --location $location --tags project=REACTIO purpose=academic-demo
```

## 2. Provisionar a VM via CLI

Este é o comando usado para criar a VM existente. Não execute novamente enquanto ela estiver em uso.

```powershell
az vm create `
  --resource-group $resourceGroup `
  --name $vmName `
  --location $location `
  --zone 3 `
  --image Ubuntu2204 `
  --size Standard_B2s_v2 `
  --admin-username azureuser `
  --generate-ssh-keys `
  --nsg-rule NONE `
  --public-ip-sku Standard `
  --tags project=REACTIO purpose=academic-demo
```

## 3. Regra de rede restrita ao IP do demonstrador

A API não autentica as operações editoriais. Restrinja a porta 8080 ao IP de origem:

```powershell
$myIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
$nicId = az network nic list --resource-group $resourceGroup --query "[0].id" --output tsv
$nsgId = az network nic show --ids $nicId --query "networkSecurityGroup.id" --output tsv
$nsgName = ($nsgId -split "/")[-1]
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name AllowReactio8080FromDemoIP --priority 1100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "$myIp/32" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 8080
```

## 4. Instalar Docker e executar a API

Run Command executa comandos na VM sem abrir SSH. O comando clona este repositório, constrói a imagem e inicia o container:

```powershell
$deployScript = "set -eux && apt-get update && apt-get install -y docker.io git && systemctl enable --now docker && git clone --recurse-submodules https://github.com/Eric-devops-tech/Reactio-Cloud.git /opt/reactio-cloud && cd /opt/reactio-cloud && docker build -t reactio-api:demo . && docker volume create reactio-data && docker run -d --name reactio-api --restart unless-stopped -p 8080:8080 -v reactio-data:/app/data reactio-api:demo"
az vm run-command invoke --resource-group $resourceGroup --name $vmName --command-id RunShellScript --scripts $deployScript
```

Verificação do container:

```powershell
az vm run-command invoke --resource-group $resourceGroup --name $vmName --command-id RunShellScript --scripts "docker ps"
az vm list --resource-group $resourceGroup --show-details --output table
```

## 5. Evidências do Azure

O Azure mantém o histórico de implantação e de atividade, mesmo depois de fechar o terminal:

```powershell
az deployment group list --resource-group $resourceGroup --query "[].{implantacao:name,status:properties.provisioningState,data:properties.timestamp}" --output table
az monitor activity-log list --resource-group $resourceGroup --offset 1d --max-events 50 --query "[?operationName.localizedValue=='Create or Update Virtual Machine'].{data:eventTimestamp,status:status.value,operacao:operationName.localizedValue}" --output table
```

Consultar o endpoint:

```powershell
$publicIp = az network public-ip list --resource-group $resourceGroup --query "[0].ipAddress" --output tsv
Invoke-RestMethod -Uri "http://$($publicIp):8080/api/quiz"
```

Grave VM, container e resposta da API. O vídeo deve ser não listado no YouTube, máximo 3 minutos e mínimo 720p. Se o professor usar outra rede, inclua o IP dele temporariamente na regra.

## 6. Limpeza

Revise o nome e remova o grupo dedicado após a demonstração:

```powershell
az group delete --name $resourceGroup --yes --no-wait
```

Isso remove VM, disco, IP, rede e NSG do projeto. Mantenha o grupo automático `NetworkWatcherRG`.

## Referências

- [Criar uma VM Linux com Azure CLI](https://learn.microsoft.com/azure/virtual-machines/linux/quick-create-cli)
- [Referência az vm](https://learn.microsoft.com/cli/azure/vm?view=azure-cli-latest)
- [Azure Run Command](https://learn.microsoft.com/azure/virtual-machines/linux/run-command)
