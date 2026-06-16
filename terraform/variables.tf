variable "aws_region" {
  description = "Región de AWS para el despliegue"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nombre del clúster EKS"
  type        = string
  default     = "techmarket-cluster"
}