










provider "aws" {
  region = "us-east-1"
}

variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}

resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de um IP específico e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  
  ingress {
    description      = "Allow SSH from a specific IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["YOUR_IP_ADDRESS/32"]  # Substitua por seu IP
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}

data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

resource "aws_instance" "debian_ec2" {
  ami                    = data.aws_ami.debian12.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  key_name               = aws_key_pair.ec2_key_pair.key_name
  security_groups        = [aws_security_group.main_sg.name]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
                #!/bin/bash
                apt-get update -y
                apt-get upgrade -y
                apt-get install nginx -y
                systemctl start nginx
                systemctl enable nginx
                EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}




///
//Descrição Técnica
//Variáveis

//Chave Privada

//hcl
//Copiar código
//resource "tls_private_key" "ec2_key" { ... }
//Descrição: Cria uma chave privada RSA para acesso à instância EC2.

//
//Copiar código
//resource "aws_key_pair" "ec2_key_pair" { ... }
//Descrição: Cria um par de chaves no AWS, utilizando a chave pública gerada anteriormente.

//hcl
//Copiar código
//resource "aws_vpc" "main_vpc" { ... }
//Descrição: Cria uma Virtual Private Cloud (VPC) com suporte a DNS.

//hcl
//Copiar código
//resource "aws_subnet" "main_subnet" { ... }
//Descrição: Cria uma sub-rede dentro da VPC.
//hcl
//Copiar código
//resource "aws_internet_gateway" "main_igw" { ... }
//Descrição: Cria um gateway de internet para permitir acesso à VPC.
//Observação: Essencial para permitir a comunicação entre a VPC e a internet.
//Tabela de Roteamento

//hcl
//Copiar código
//resource "aws_route_table" "main_route_table" { ... }
//Descrição: Define uma tabela de roteamento associando a CIDR block 0.0.0.0/0 ao gateway de internet.
//Observação: Isso permite que as instâncias na sub-rede se comuniquem com a internet.
//Associação de Tabela de Roteamento

//hcl
//Copiar código
//resource "aws_route_table_association" "main_association" { ... }
//Descrição: Associa a tabela de roteamento à sub-rede criada.
//Observação: É crucial para que as regras de roteamento sejam aplicadas à sub-rede.
//Grupo de Segurança

//hcl
//Copiar código
//resource "aws_security_group" "main_sg" { ... }
//Descrição: Cria um grupo de segurança permitindo SSH de qualquer lugar e todo o tráfego de saída.
//Observação: O acesso SSH (port 22) aberto para todos pode ser um risco de segurança. Considere restringir isso a um IP específico.
//AMI (Amazon Machine Image)

//hcl
//Copiar código
//data "aws_ami" "debian12" { ... }
//Descrição: Busca a imagem mais recente do Debian 12 para criar a instância EC2.

//hcl
//Copiar código
//resource "aws_instance" "debian_ec2" { ... }
//Descrição: Lança uma instância EC2 com a AMI do Debian 12 e configurações específicas.
//Observação: O script user_data permite inicializar a instância com atualizações automáticas.
//Saídas

//hcl
//Copiar código
//output "private_key" { ... }
//output "ec2_public_ip" { ... }
//Descrição: Define saídas para mostrar a chave privada e o IP público da instância após a criação.
//Observação


//Melhorias de Segurança no Grupo de Segurança

////Alteração: A regra de entrada para SSH foi modificada para permitir acesso apenas de um IP específico.
//hcl
//Copiar código
//ingress {
 // description      = "Allow SSH from a specific IP"
 // from_port        = 22
 // to_port          = 22
  //protocol         = "tcp"
  //cidr_blocks      = ["YOUR_IP_ADDRESS/32"]  # Substitua por seu IP
//}
//Expectativa:
//Aumento da Segurança: Limitar o acesso SSH a um único IP reduz significativamente a superfície de ataque, tornando a instância menos vulnerável a tentativas de acesso não autorizado.
//Monitoramento e Auditoria: Acesso restrito facilita a auditoria de logs e o monitoramento de tentativas de acesso.
//Automação da Instalação do Nginx

//Alteração: O bloco user_data foi adicionado com comandos para instalar e iniciar o Nginx automaticamente.
//hcl
//Copiar código
//user_data = <<-EOF
              #!/bin/bash
             // apt-get update -y
             // apt-get upgrade -y
             // apt-get install nginx -y
              //systemctl start nginx
              //systemctl enable nginx
              //EOF
//Expectativa:
//Instalação Automatizada: A instância EC2 instalará o Nginx automaticamente ao ser provisionada, eliminando a necessidade de configuração manual após a criação.
//Disponibilidade Imediata: O Nginx será iniciado automaticamente, permitindo que a instância esteja pronta para servir tráfego HTTP imediatamente após a inicialização.
//Persistência em Reinicializações: O comando systemctl enable nginx assegura que o Nginx será iniciado em futuras reinicializações da instância, garantindo que o serviço esteja sempre disponível.
//Resumo das Expectativas Gerais
// na Segurança: O acesso SSH restrito para um único IP significa que menos pessoas podem tentar acessar a instância, resultando em uma postura de segurança mais robusta.
//Eficiência Operacional: A automação da instalação do Nginx reduz o tempo e o esforço necessários para configurar a instância, permitindo um processo de implantação mais rápido e eficiente.
//Confiabilidade do Serviço: Com o Nginx configurado para iniciar automaticamente, o tempo de inatividade é minimizado, e a disponibilidade do serviço é melhorada.
//Essas melhorias ajudam a criar um ambiente mais seguro e eficiente, alinhado com as melhores práticas de gerenciamento de infraestrutura na nuvem. Se precisar de mais detalhes ou alterações, estou à disposição!




