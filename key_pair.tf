# SSH 키 페어 생성
resource "tls_private_key" "cicd_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS 키 페어 생성
resource "aws_key_pair" "cicd_key" {
  key_name   = "cicd-key"
  public_key = tls_private_key.cicd_key.public_key_openssh
}

# 프라이빗 키를 로컬 파일로 저장
resource "local_file" "private_key" {
  content  = tls_private_key.cicd_key.private_key_pem
  filename = "cicd-key.pem"

  provisioner "local-exec" {
    command = "chmod 400 cicd-key.pem"
  }
} 