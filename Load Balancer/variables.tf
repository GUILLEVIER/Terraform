variable "puerto_servidor" {
  description = "Puerto para las instancias EC2"
  type        = number
  default     = 8080

  validation {
    # Condition: Expresion de forma booleana
    # 2 elevado a 16 = 65536, para que un puerto sea valido
    # error_message: Un mensaje de error sobre el porque ha fallado
    condition          = var.puerto_servidor > 0 && var.puerto_servidor <= 65536
    error_message = "El valor del puerto debe estar comprendido entre 1 y 65536."
  }
}

variable "puerto_lb" {
  description = "Puerto para el LB"
  type        = number
  default     = 80
}

variable "tipo_instancia" {
  description = "Tipo de las instancias EC2"
  type        = string
  default     = "t2.micro"
}

# Se hace terraform apply sin ningun fichero, sin ningun flag.

# Variables: Tipado dinámico
variable "variable_dinamica" {
  type = any
  # type = list(any)
  # Si deseamos escribir: [1, "maria", true] va a cojer el tipo de dato mas generico, en esta ocasión un String.
}

variable "ubuntu_ami" {
  description = "AMI por región"
  type        = map(string)
  default = {
    us-east-1 = "ami-04505e74c0741db8d"
    us-east-2 = "ami-0fb653ca2d3203ac1"
    us-west-1 = "ami-01f87c43e618bf8f0"
    us-west-2 = "ami-0892d3c7ee96c0bf7"
  }
}

