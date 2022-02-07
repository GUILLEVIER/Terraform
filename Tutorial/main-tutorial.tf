# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

# resource "<nombre del proveedor>_<resource_type>"" "name" {
#   config_option
#   key = "value"
#   key2 = "value2"
# }

resource "aws_instance" "my-first-server" {
  ami = "my-ami"
  instance_type = "t2.micro"

  tags = {
    Name = "my-first-server" # Sirve para buscar la instancia en AWS, en AWS es el Name
  }
}

# Create VPC
resource "aws_vpc" "my-first-vpc" {
  cidr_block =  "10.0.0.0/16"
  tags = {
    Name = "my-first-vpc" # Sirve para buscar la instancia en AWS, en AWS es el Name
  }
}

# Create SUBNET
resource "aws_subnet" "my-first-subnet" {
  vpc_id = aws_vpc.my-first-vpc.id # Sintaxis: nombre_del_proveedor.name_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "my-first-subnet"
  }
}

# Pasos TEST
# 1. Create vpc
# 2. Create Internet Gateway
# 3. Create Custom Route Table
# 4. Create a Subnet
# 5. Associate subnbet with Route Table
# 6. Create Security Group to allow port 22 (SSH), 80, 443 (HTTPS)
# 7. Create a network interface with an ip in the subnet that was created in step 4
# 8. Assign an elastic IP to the network interface created in step 7
# 9. Create Ubuntu server and install/enable apache2

# 1.
resource "aws_vpc" "vpc-test" {
  cidr_block =  "10.0.0.0/16"
}

# 2.
resource "aws_intenet_gateway" "gw-test" {
  vpc_id = aws_vpc.vpc-test.id
}

# 3.
resource "aws_route_table" "rt-test" {
  vpc_id = aws_vpc.vpc-test.id

  # Lo que quiere decir es que toda ip que corresponde a una subred o conjunto de IP,
  # sea enviado al gateway
  # Lo que queremos configurar es que una ruta predeterminada, lo que significa que todo
  # el trafico se enviará a la puerta de enlace de internet. Todas las IP, todas las ipv4.
  route {
    #cidr_block = "10.0.1.0/24" # Esta corresponde a una subred
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-test.id
  }

  # Mismo ejemplo pero para la ipv6
  # route {
  #   ipv6_cidr_block        = "::/0"
  #   gateway_id = aws_internet_gateway.gw-test.id
  # }
}


variable "subnet_prefix" {
  description = "CIDR block for the subnet"
  # default = "10.0.200.0/24" # Valor que tiene por defecto, si este se define, debe estar comentado en tfvars.
  type = String
  # "10.0.1.0/24" This is the value
}

variable "subnet_prefix_subnet_2" {
  description = "CIDR block for the subnet 2"
}

variable "subnet_object" {
  description = "CIDR block for the subnet 1"
}

# 4.
resource "aws_subnet" "subnet-test" {
  vpc_id = aws_vpc.vpc-test.id
  cidr_block = var.subnet_prefix
  availability_zone = "us-east-1"

  tags = {
    Name = var.subnet_object[0].name
  }
}

resource "aws_subnet" "subnet-test-2" {
  vpc_id = aws_vpc.vpc-test.id
  cidr_block = var.subnet_prefix_subnet_2[1]
  availability_zone = "us-east-1"

  tags = {
    Name = var.subnet_object[1].name
  }
}

# 5. Asignar la subnet a la tabla de rutas personalizada.
resource "aws_route_table_association" "association-test" {
  subnet_id      = aws_subnet.subnet-test.id
  route_table_id = aws_route_table.rt-test.id
}

# 6. Solo va a permitir el trafico en el puerto 22, 80, y 443
resource "aws_security_group" "allow-web-test" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc-test.id

  # Permitir el trafico TCP en el puerto 443
  # Permite especificar el ragon de puertos (from_port - to_port)
  # Cuando se especifica solo un puerto tanto en from como to, solo permitira ese puerto.
  # Tipo de protocolo (TCP, UDP)
  # Se puede restringir las subredes que realmente pueden llegar.
  # Si es abierto a todo el publico, se cambia a --> "0.0.0.0/0"

  # INGRESO
  # HTTPS
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  # HTTP
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  # SSH
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  # SALIDA
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7.
# Como especificamos la IP?: Que IP queremos darle al servidor?
# Para asignar una IP publica? Se necesita una IP elástica de AWS
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-test.id
  private_ips     = ["10.0.1.50"] # Se asigno una IP privada para el host, recordar que esta puede ser una lista.
  security_groups = [allow-web-test.id]

  # Esto sirve para atacharlo a un dispositivo. Opcional, puede realizarse en AWS
  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}

# 8.
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw-test] # Se genera una dependencia explicita a IG, a todo el objeto
}

# 9.
resource "aws_instance" "web-server-instance" {
  ami = "ami-123123123123"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a" # Asegurarse que este en la misma región que la subred, si no se codifica elegira una zona de diponibilidad aleatoria para implementarla.
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  # Realizar instalaciones dentro del SO de la instancia
  user_data = <<-EOF
              #l/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

output "server_private_ip" {
  value = aws_instance.web-server-instance.private_ip
}

output "server_id" {
  value = aws_instance.web-server-instance.id
}