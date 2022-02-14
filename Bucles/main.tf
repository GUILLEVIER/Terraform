provider "aws" {
  region = "eu-east-1"
}

variable "usuarios_count" {
  description = "Nombre de usuarios IAM count"
  type        = list(string)
}
resource "aws_iam_user" "ejemplo_count" {
  count = length(var.usuarios_count)
  name  = "usuario-${var.usuarios_count[count.index]}"
}

output "arn_usuario" {
  description = "ARN del usuario 2 (indice 1)"
  value       = aws_iam_user.ejemplo_count[1].arn
}

output "arn_todos_usuarios" {
  description = "ARN de todos los usuarios"
  value       = [for usuario in aws_iam_user.ejemplo_count : usuario.arn]
}

# Para crear dos usuario se usa count.
# En AWS no se permite crear un usuario con el mismo nombre.
# El orden de la lista de string si importa al utilizar count.
# Para evitar esto, se utiliza for_each

variable "usuarios_for_each" {
  description = "Nombre de usuarios IAM for_each"
  type        = set(string)
}

# each.value va a ser el valor actual de la iteracion actual.
# Por lo tanto si cambiamos el orden de entrada de los elementos, no nos va a reflajar un cambio en los recursos.
resource "aws_iam_user" "ejemplo_for_each" {
  for_each = var.usuarios_for_each
  name     = "usuario-${each.value}"
}

output "arn_usuario_for_each" {
  description = "ARN del usuario maria"
  value       = aws_iam_user.ejemplo_count["maria"].arn
}

output "arn_todos_usuarios_for_each" {
  description = "ARN de todos los usuarios"
  value       = [for usuario in aws_iam_user.ejemplo_for_each : usuario.arn]
}

output "arn_nombre_a_arn" {
  description = "ARN de todos los usuarios"
  value       = { for usuario in aws_iam_user.ejemplo_for_each : usuario.name => usuario.arn }
}

# Expresion splat, simplifica el for.
output "arn_nombre_a_arn_splat" {
  description = "ARN de todos los usuarios"
  value       = aws_iam_user.ejemplo[*].arn
  #value       = aws_iam_user.ejemplo[*].name
}
