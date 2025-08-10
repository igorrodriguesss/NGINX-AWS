# 🚀 Laboratório DevOps - Projeto 2: Automatização de Infraestrutura com Terraform (IaC)
## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [O Problema Real: Por Que Isso Importa?](#o-problema-real-por-que-isso-importa)
3. [Pré-requisitos](#pré-requisitos)
4. [Arquitetura do Projeto](#arquitetura-do-projeto)
5. [Fase 1: Identificando o Problema no Processo Manual](#fase-1-identificando-o-problema-no-processo-manual)
6. [Fase 2: Introduzindo Infrastructure as Code (IaC)](#fase-2-introduzindo-infrastructure-as-code-iac)
7. [Fase 3: Instalação e Configuração do Terraform](#fase-3-instalação-e-configuração-do-terraform)
8. [Fase 4: Estrutura do Projeto Terraform](#fase-4-estrutura-do-projeto-terraform)
9. [Fase 5: Criando os Arquivos Terraform](#fase-5-criando-os-arquivos-terraform)
10. [Fase 6: Inicializando e Aplicando o Terraform](#fase-6-inicializando-e-aplicando-o-terraform)
11. [Fase 7: Configurando Armazenamento Remoto do Estado Terraform (Backend S3)](#fase-7-configurando-armazenamento-remoto-do-estado-terraform-backend-s3)
12. [Fase 8: Integrando com o Docker do Projeto 1](#fase-8-integrando-com-o-docker-do-projeto-1)
13. [Fase 9: Deploy Automatizado na Infra Provisionada](#fase-9-deploy-automatizado-na-infra-provisionada)
14. [Verificação e Testes](#verificação-e-testes)
15. [Troubleshooting](#troubleshooting)
16. [Limpeza de Recursos](#limpeza-de-recursos)
---
## 🎯 Visão Geral
### O que vamos construir?
Neste laboratório, vamos pegar o deploy manual de um website estático (do Projeto 1) e automatizá-lo usando Terraform para provisionar a infraestrutura na AWS de forma declarativa. Você criará recursos como ECR, EC2, Security Groups e IAM Roles automaticamente, eliminando cliques manuais no console.
### Por que isso é importante?
- **Reprodutibilidade**: Recrie ambientes idênticos em segundos, sem erros humanos.
- **Versionamento**: Trate sua infra como código, usando Git para rastrear mudanças.
- **Escalabilidade**: Base para ambientes complexos, como dev/staging/prod.
- **Padrão da Indústria**: Terraform é uma ferramenta essencial para DevOps Engineers, usada em empresas como HashiCorp, AWS e Google.
### Conexão com o Projeto 1
No Projeto 1, você fez tudo manualmente: criou ECR, lançou EC2 via console e deployou o container Docker. Aqui, vamos "retrofitar" isso com IaC, resolvendo os problemas de configuração manual. Isso é como adicionar uma camada de automação ao quebra-cabeça, preparando para o Projeto 3 (CI/CD full).
### Tempo estimado: 2-4 horas (dependendo da depuração)
---
## ❓ O Problema Real: Por Que Isso Importa?
Imagine que você é um DevOps Engineer em uma startup em crescimento. Seu time desenvolveu um site estático (como no Projeto 1) e o deployou manualmente na AWS. Agora, o CEO quer replicar isso para um ambiente de staging e produção em regiões diferentes. Você clica no console AWS repetidamente, mas:
- **Problema 1**: Erros humanos – Esqueceu de abrir a porta 80 no Security Group? O site não acessa.
- **Problema 2**: Não reproduzível – Um colega tenta recriar e erra uma configuração, causando downtime.
- **Problema 3**: Não versionado – Mudanças na infra (ex.: adicionar uma nova regra de firewall) não são rastreadas, levando a "drift" (desalinhamento entre o que está no console e o que deveria ser).
- **Problema 4**: Demorado e não escalável – Para 10 ambientes, você gasta horas; imagine em uma crise de escala.
Situação real: Sua app vai ao ar, mas um deploy de emergência falha porque a EC2 não tem as permissões corretas para o ECR. O time perde horas debugando. Como resolver? Vamos "de trás pra frente": Primeiro, identifique esses problemas no seu setup do Projeto 1. Depois, busque uma solução que automatize tudo. Isso nos leva a Infrastructure as Code (IaC), onde declaramos o que queremos (não como fazer), e ferramentas como Terraform executam.
**Desafio para você**: Antes de prosseguir, tente recriar manualmente o ambiente do Projeto 1 em uma nova região AWS. Note os pontos de dor – isso vai motivar o uso do Terraform.
---
## 🔧 Pré-requisitos
### Ferramentas Necessárias
#### 1. **Terraform**
- Baixe em [terraform.io/downloads](https://www.terraform.io/downloads.html)
- **Instalação (Mac/Linux)**:
```bash
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```
- **Windows**: Use o instalador ou Chocolatey: `choco install terraform`
- Verifique:
```bash
terraform --version
```
#### 2. **AWS CLI** (do Projeto 1)
- Já configurada com `aws configure`
#### 3. **Docker** (do Projeto 1)
- Imagem do website pronta e pushada para ECR (ou recrie do Projeto 1)
#### 4. **Git** (para versionar o código IaC)
- Instale se necessário: `sudo apt install git` (Linux) ou baixe em [git-scm.com](https://git-scm.com/)
#### 5. **Editor de Código**
- VS Code com extensões: Terraform, AWS Toolkit
### Estrutura do Projeto
Baseado no Projeto 1, adicione uma pasta para Terraform:
```
meu-projeto/
├── website/ # Do Projeto 1
├── Dockerfile # Do Projeto 1
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── provider.tf
    ├── backend.tf # Adicionado para configuração de backend S3
    └── (outros arquivos que criaremos)
```
---
## 🏗️ Arquitetura do Projeto
```
┌─────────────────┐ ┌─────────────────┐
│ Código Local │────▶│ Terraform │
│ (TF Files + │ │ (IaC) │
│ Docker Image) │ └─────────────────┘
└─────────────────┘ │
                                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Amazon ECR │◀────│ AWS Infra │────▶│ Amazon EC2 │
│ (Registry) │ │ (Automated) │ │ (Container) │
└─────────────────┘ └─────────────────┘ └─────────────────┘
                                                          │
                                                          ▼
                        ┌─────────────────┐
                        │ Browser │
                        │ (User Access) │
                        └─────────────────┘
```
Aqui, o Terraform orquestra a criação de ECR, EC2, etc., antes do deploy Docker.
---
## 🔍 Fase 1: Identificando o Problema no Processo Manual
### Passo 1.1: Revise o Projeto 1
- Volte ao seu setup manual. Tente criar uma segunda EC2 via console.
- Pergunte-se: "O que deu errado? Por que demorou? Como versiono isso?"
- Anote problemas (ex.: "Esqueci o IAM Role – ECR pull falhou").
### Passo 1.2: Simule um Erro Real
- Delete manualmente o Security Group do Projeto 1 e tente acessar o site. Veja o downtime.
- Isso destaca a necessidade de automação: IaC previne "drift" detectando mudanças.
**Lição prática**: Problemas manuais são comuns em equipes DevOps. Agora, busque soluções: Pesquise "como automatizar infra AWS" – você descobrirá IaC e ferramentas como Terraform.
---
## 📚 Fase 2: Introduzindo Infrastructure as Code (IaC)
Agora que vimos o problema, vamos à solução. IaC trata infra como código: Declare o estado desejado (ex.: "Quero uma EC2 com porta 80 aberta"), e a ferramenta aplica.
**Por que Terraform?** É multi-cloud, open-source, e usa HCL (linguagem simples). Alternativas: CloudFormation (AWS-only), Pulumi (programável).
**Teoria simples**: Terraform tem providers (plugins para clouds), resources (o que criar), variables (parâmetros) e outputs (resultados). Ciclo: init → plan → apply → destroy.
**Desafio**: Pense como um DevOps Engineer: "Como mapear o ECR manual para código?"
---
## 🛠️ Fase 3: Instalação e Configuração do Terraform
### Passo 3.1: Verificar Instalação
```bash
terraform --version
```
Espere algo como: `Terraform v1.5.7`
### Passo 3.2: Configurar AWS Provider
- No diretório `terraform/`, crie `provider.tf` (ver Fase 5).
### Passo 3.3: Inicializar um Projeto Teste
```bash
mkdir terraform-test
cd terraform-test
echo 'provider "aws" { region = "us-east-1" }' > main.tf
terraform init
```
- Isso baixa o provider AWS. Veja o problema resolvido: Automação começa aqui.
---
## 📂 Fase 4: Estrutura do Projeto Terraform
Crie a pasta `terraform/` na raiz do projeto.
Arquivos chave:
- `main.tf`: Recursos principais.
- `variables.tf`: Entradas configuráveis.
- `outputs.tf`: Saídas úteis (ex.: IP da EC2).
- `provider.tf`: Configuração do provider.
- `backend.tf`: Configuração do backend remoto para armazenamento do tfstate (ver Fase 7).
**Dica prática**: Use Git: `git init` e commit mudanças para versionar.
---
## ✍️ Fase 5: Criando os Arquivos Terraform
### Passo 5.1: Provider e Variáveis
Crie `provider.tf`:
```hcl
provider "aws" {
  region = var.aws_region
}
```
Crie `variables.tf`:
```hcl
variable "aws_region" {
  default = "us-east-1"
}
variable "ecr_repo_name" {
  default = "meu-website"
}
variable "ec2_instance_type" {
  default = "t2.micro"
}
variable "key_pair_name" {
  default = "meu-website-key"
}
variable "tfstate_bucket_name" {
  default = "meu-terraform-state-bucket" # Nome único para o bucket S3
}
variable "tfstate_dynamodb_table" {
  default = "meu-terraform-lock-table" # Para locking do state
}
```
### Passo 5.2: Recursos Principais (main.tf)
Aqui, declaramos o que criamos no Projeto 1:
```hcl
# VPC (simples, use default para free tier)
data "aws_vpc" "default" {
  default = true
}
# Security Group
resource "aws_security_group" "website_sg" {
  name = "meu-website-sg"
  description = "Security group for website"
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrinja ao seu IP em prod
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# IAM Role para EC2 acessar ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "EC2-ECR-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name
}
# ECR Repository
resource "aws_ecr_repository" "website_repo" {
  name = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
# EC2 Instance
resource "aws_instance" "website_server" {
  ami = "ami-0abcdef1234567890" # Amazon Linux 2023 - busque o ID atual na região
  instance_type = var.ec2_instance_type
  key_name = var.key_pair_name # Crie manualmente ou adicione resource para key
  vpc_security_group_ids = [aws_security_group.website_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              EOF
  tags = {
    Name = "meu-website-server"
  }
}
# Recursos para Backend S3 (Bucket e DynamoDB para locking)
resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = var.tfstate_bucket_name
  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_encryption" {
  bucket = aws_s3_bucket.tfstate_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name           = var.tfstate_dynamodb_table
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "Terraform Lock Table"
  }
}
```
**Entendendo de trás pra frente**: Começamos com o problema (ex.: Security Group manual), depois declaramos o resource. Note: AMI ID varia por região – busque no console AWS. Adicionamos recursos para o bucket S3 e tabela DynamoDB para armazenar o tfstate de forma segura e com locking para evitar conflitos em equipes.
### Passo 5.3: Outputs
Crie `outputs.tf`:
```hcl
output "ec2_public_ip" {
  value = aws_instance.website_server.public_ip
}
output "ecr_repository_url" {
  value = aws_ecr_repository.website_repo.repository_url
}
```
---
## ⚙️ Fase 6: Inicializando e Aplicando o Terraform
### Passo 6.1: Init
```bash
cd terraform/
terraform init
```
### Passo 6.2: Plan (Pré-visualização)
```bash
terraform plan
```
- Veja o que será criado. Resolva erros (ex.: AMI inválida).
### Passo 6.3: Apply
```bash
terraform apply
```
- Digite "yes". Aguarde ~5 min.
**Lições**: Se falhar (ex.: permissão), debugue – isso simula problemas reais em DevOps.
---
## 🗄️ Fase 7: Configurando Armazenamento Remoto do Estado Terraform (Backend S3)
Por padrão, o Terraform armazena o estado localmente em `terraform.tfstate`, o que pode causar problemas em equipes (ex.: conflitos de edição) ou perda de dados. Para resolver isso, configure um backend remoto no S3 para armazenamento seguro, versionado e com locking via DynamoDB.

### Por Que Isso Importa?
- **Colaboração**: Vários engenheiros podem trabalhar no mesmo projeto sem sobrescrever o state.
- **Segurança**: O state contém dados sensíveis (ex.: IDs de recursos); S3 oferece encriptação e versionamento.
- **Recuperação**: Recupere states antigos em caso de falhas.
- **Melhor Prática**: Essencial para ambientes de produção, evitando "state drift" ou perda.

### Passo 7.1: Criar Arquivo backend.tf
Crie `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "meu-terraform-state-bucket" # Use o valor de var.tfstate_bucket_name
    key            = "terraform.tfstate"          # Nome do arquivo state no bucket
    region         = "us-east-1"                  # Mesma região do provider
    dynamodb_table = "meu-terraform-lock-table"   # Para locking
    encrypt        = true                         # Encriptação obrigatória
  }
}
```
**Explicação passo a passo**:
- **Bucket**: Armazena o arquivo tfstate.
- **Key**: Caminho dentro do bucket (use paths diferentes para multi-ambientes, ex.: "dev/terraform.tfstate").
- **DynamoDB Table**: Fornece locking para prevenir applies simultâneos.
- **Encrypt**: Usa SSE-S3 para segurança.

### Passo 7.2: Inicializar com Backend
Após adicionar `backend.tf`, rode:
```bash
terraform init -migrate-state
```
- Isso migra o state local para o S3. Confirme com "yes".
- Em projetos novos, basta `terraform init`.

### Passo 7.3: Verificar Configuração
- Após init, o Terraform usará o S3 automaticamente em futuros plans/applies.
- Verifique no console AWS: Vá ao S3 e veja o bucket com o arquivo tfstate; no DynamoDB, veja a tabela de lock.

### Problemas Comuns e Soluções
- **Bucket Já Existe?** O Terraform criará via resources em main.tf, mas garanta nome único globalmente.
- **Permissões**: Seu IAM user precisa de `s3:PutObject`, `s3:GetObject`, `dynamodb:PutItem`, etc. Adicione policy como "TerraformBackendAccess".
- **Migração Falha**: Se state local não existe, ignore; para equipes, use workspaces: `terraform workspace new dev`.

**Dica DevOps**: Em cenários complexos, integre com Terragrunt para gerenciar múltiplos backends. Isso resolve problemas reais como state locking em pipelines CI/CD.

---
## 🔗 Fase 8: Integrando com o Docker do Projeto 1
### Passo 8.1: Push Imagem para Novo ECR
- Use o output `ecr_repository_url`.
```bash
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)
docker tag meu-website:v1.0 $(terraform output -raw ecr_repository_url):v1.0
docker push $(terraform output -raw ecr_repository_url):v1.0
```
### Passo 8.2: Verifique no Console
- ECR e EC2 criados automaticamente!
---
## 🚀 Fase 9: Deploy Automatizado na Infra Provisionada
### Passo 9.1: SSH na EC2 (usando output IP)
```bash
ssh -i meu-website-key.pem ec2-user@$(terraform output -raw ec2_public_ip)
```
### Passo 9.2: Pull e Run Docker
- Como no Projeto 1, mas agora a infra é auto-provisionada.
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [ECR_URL]
docker pull [ECR_URL]:v1.0
docker run -d -p 80:80 --name meu-website-prod --restart always [ECR_URL]:v1.0
```
**Problema resolvido**: Tudo versionado e reproduzível!
---
## ✅ Verificação e Testes
### Teste 1: Acessar o Site
- `http://$(terraform output -raw ec2_public_ip)`
### Teste 2: Verificar Drift
```bash
terraform plan
```
- Deve mostrar "no changes" se tudo alinhado.
### Teste 3: Simule Mudança
- Altere manualmente o Security Group no console, rode `terraform apply` – Terraform corrige!
### Teste 4: Verificar State no S3
- Baixe o state via AWS CLI: `aws s3 cp s3://meu-terraform-state-bucket/terraform.tfstate .` e inspecione (não edite manualmente!).
---
## 🔧 Troubleshooting
### Problema 1: "Error: no matching AMI found"
**Solução**: Busque AMI ID correto para sua região: `aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].ImageId"`
### Problema 2: Permissões IAM Falhando
**Solução**: Verifique `aws configure` e adicione permissões ao seu user (ex.: EC2FullAccess).
### Problema 3: Terraform State Lock
**Solução**: Com backend S3 + DynamoDB, locks são automáticos. Para unlock manual: `terraform force-unlock <LOCK_ID>`.
### Problema 4: Backend Initialization Failed
**Solução**: Verifique nome do bucket/tabela, região e permissões. Rode `terraform init -reconfigure` para reset.
---
## 🧹 Limpeza de Recursos
```bash
terraform destroy
```
- Digite "yes". Evite custos! Note: O backend S3 mantém o state histórico; delete manualmente se necessário.

## 🎓 Conceitos Aprendidos

✅ **IaC**: Tratar infra como código para resolver problemas de manualidade.
✅ **Terraform**: Providers, resources, plan/apply/destroy.
✅ **Drift Detection**: Manter alinhamento entre código e realidade.
✅ **Outputs**: Extrair infos úteis para integrações.
✅ **Backend Remoto**: Armazenar tfstate no S3 para colaboração e segurança.


## 🚀 Próximos Passos
1. **Projeto 3**: Automatize o push Docker e deploy com CI/CD (GitHub Actions + Terraform).
2. **Explorar**: Modules Terraform, backends (S3), workspaces para multi-ambientes.
---
## 📚 Recursos Adicionais
- [Terraform Docs](https://www.terraform.io/docs)
- [AWS Provider Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Best Practices IaC](https://www.hashicorp.com/resources/terraform-best-practices)
- [Terraform Backends](https://www.terraform.io/language/settings/backends/s3)
---
## 📝 Notas
Use este espaço para suas anotações pessoais:
```
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
```
---
**Parabéns! 🎉** Você resolveu problemas reais com IaC e está pronto para automações full no Projeto 3!
Desenvolvido com ❤️ para a jornada DevOps