variable "region" {
  description = "Región de AWS donde se despliega el ejercicio"
  type        = string
  default     = "us-east-2"
}

variable "nombre_bucket" {
  description = "Nombre del bucket S3 (debe ser único en todo AWS)"
  type        = string
}

variable "nombre_base_datos" {
  description = "Base de datos de Glue Data Catalog"
  type        = string
  default     = "mensajeria"
}

variable "nombre_tabla" {
  description = "Tabla externa de Glue con los intentos de entrega"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Workgroup de Athena para las consultas del ejercicio"
  type        = string
  default     = "wg_mensajeria"
}
