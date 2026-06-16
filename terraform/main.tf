# ==========================================
# 1. ROL DE AWS ACADEMY
# ==========================================
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ==========================================
# 2. RED VIRTUAL (VPC NATIVA)
# ==========================================
resource "aws_vpc" "techmarket_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "techmarket-vpc"
  }
}

resource "aws_internet_gateway" "techmarket_igw" {
  vpc_id = aws_vpc.techmarket_vpc.id

  tags = {
    Name = "techmarket-igw"
  }
}

# EKS Requiere 2 subredes en zonas distintas
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.techmarket_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "techmarket-public-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.techmarket_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "techmarket-public-2"
  }
}

resource "aws_route_table" "techmarket_rt" {
  vpc_id = aws_vpc.techmarket_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techmarket_igw.id
  }

  tags = {
    Name = "techmarket-rt"
  }
}

resource "aws_route_table_association" "rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.techmarket_rt.id
}

resource "aws_route_table_association" "rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.techmarket_rt.id
}

# ==========================================
# 3. CLÚSTER EKS Y NODOS NATIVOS
# ==========================================
resource "aws_eks_cluster" "techmarket" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id
    ]
    endpoint_public_access = true
  }
}

resource "aws_eks_node_group" "techmarket_nodes" {
  cluster_name    = aws_eks_cluster.techmarket.name
  node_group_name = "nodos-techmarket"
  node_role_arn   = data.aws_iam_role.lab_role.arn

  subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.techmarket
  ]
}