output "vpc_id" {
  value = aws_vpc.dev-vpc.id
}

output "pub_subnet_id" {
  value = aws_subnet.Dev-public[*].id
}

output "private_subnet_id" {
  value = aws_subnet.Dev-private[*].id
}

output "vpc_cidr_block" {
  value = aws_vpc.dev-vpc.cidr_block
  
}