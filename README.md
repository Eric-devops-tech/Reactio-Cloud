# REACTIO Cloud

Entrega de DevOps Tools & Cloud Computing: API Java do REACTIO em container Docker numa VM Linux Azure.

## Integrantes

| Nome | RM | Turma |
| --- | --- | --- |
| Kayque Duarte | 567980 | 2TDSPB |
| Eric Maciel Martins | 567398 | 2TDSPB |
| Gabriel Correa | 567903 | 2TDSPB |

## Escopo e arquitetura

Este repositório contém os arquivos Cloud. A API permanece no [repositório Java original](https://github.com/Kayque2012/REACTIO-java), referenciado no submódulo `api/REACTIO-java`. A API Spring Boot 3.5 / Java 17 oferece CRUD editorial e endpoints de quiz. O banco H2 em arquivo usa volume Docker.

```mermaid
flowchart LR
    U[Usuário / avaliador] -->|HTTP 8080| N[NSG: IP autorizado]
    N --> VM[VM Ubuntu Azure]
    VM --> C[Container Docker: API]
    C --> V[(Volume reactio-data: H2)]
    G[GitHub + submódulo Java] -. build .-> C
```

## Ambiente Azure atual

Provisionado em 03/11/2026 via Azure CLI: grupo `rg-reactio-cloud-demo-20261103`; VM `vm-reactio-demo`; Ubuntu 22.04; Chile Central, zona 3; `Standard_B2s_v2` (2 vCPU, 8 GiB). Container `reactio-api` ativo na porta 8080. A regra TCP 8080 está limitada ao IP autorizado. Os endereços são temporários e só acessíveis dentro dessa regra:

- Quiz: http://68.211.73.197:8080/api/quiz
- Swagger: http://68.211.73.197:8080/swagger-ui.html

## Obter e executar localmente

```bash
git clone --recurse-submodules https://github.com/Eric-devops-tech/Reactio-Cloud.git
cd Reactio-Cloud
docker build -t reactio-api:local .
docker volume create reactio-data
docker run --name reactio-api -p 8080:8080 -v reactio-data:/app/data reactio-api:local
```

Acesse `http://localhost:8080/api/quiz` ou `http://localhost:8080/swagger-ui.html`. Requisitos: Git com submódulos, Docker e Azure CLI para a etapa de nuvem.

## Azure CLI

Veja [docs/azure-cli.md](docs/azure-cli.md) para provisionamento, instalação do Docker, comandos de verificação, histórico e limpeza. Arquitetura: [docs/arquitetura.md](docs/arquitetura.md).

## Arquivos para reprodução

- [`Dockerfile`](Dockerfile) e [`.dockerignore`](.dockerignore): construção da imagem da API;
- [`docs/azure-cli.md`](docs/azure-cli.md): comandos Azure CLI para criar a infraestrutura, implantar e verificar o container, e excluir os recursos;
- [`docs/arquitetura.md`](docs/arquitetura.md): diagrama e descrição dos componentes;
- submódulo [`api/REACTIO-java`](api/REACTIO-java): código-fonte Java necessário para construir a imagem.

## Como Docker e Cloud Computing podem ser utilizados na solução proposta pelo grupo?

O Docker empacota a API Java e suas dependências em uma imagem reproduzível, reduzindo diferenças entre o desenvolvimento local e a demonstração. A Azure fornece a VM Linux e a rede para executar e disponibilizar o container. O volume Docker mantém os dados do H2 quando o container é recriado.

## Entregas

- [x] Dockerfile, arquitetura e instruções Azure CLI
- [x] VM criada via CLI e container em execução
- [ ] Vídeo não listado no YouTube, até 3 min, mínimo 720p
- [ ] PDF final com nomes, RMs, turma e links

Após gravar, remova o grupo dedicado para encerrar os recursos e custos:

```powershell
az group delete --name rg-reactio-cloud-demo-20261103 --yes --no-wait
```
Confira o nome antes da exclusão. O grupo automático `NetworkWatcherRG` não pertence ao projeto.
