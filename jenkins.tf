# Jenkins IAM Role
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Jenkins IAM Policy (Administrator Access)
resource "aws_iam_role_policy_attachment" "jenkins_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Jenkins Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_profile"
  role = aws_iam_role.jenkins_role.name
}

# Jenkins Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Jenkins web interface"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ArgoCD UI"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins Instance
resource "aws_instance" "jenkins" {
  ami           = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2
  instance_type = "t3.small"
  key_name      = aws_key_pair.cicd_key.key_name
  
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              # 기본 패키지 설치
              sudo yum update -y
              sudo yum install -y git jq

              # Java 11 설치
              sudo amazon-linux-extras install java-openjdk11 -y

              # Jenkins 설치
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              sudo yum install -y jenkins

              # kubectl 설치
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # AWS CLI 설치
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo yum install -y unzip
              unzip awscliv2.zip
              sudo ./aws/install
              rm -rf aws awscliv2.zip

              # EKS 클러스터 설정
              aws eks update-kubeconfig --region ap-northeast-2 --name cicd-cluster-v1

              # kubectl 설정 파일 권한 설정
              sudo mkdir -p /var/lib/jenkins/.kube
              sudo cp ~/.kube/config /var/lib/jenkins/.kube/
              sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

              # EKS 클러스터가 완전히 준비될 때까지 대기
              sleep 60

              # aws-auth ConfigMap 업데이트
              kubectl apply -f - <<YAML
              apiVersion: v1
              kind: ConfigMap
              metadata:
                name: aws-auth
                namespace: kube-system
              data:
                mapRoles: |
                  - rolearn: ${aws_iam_role.jenkins_role.arn}
                    username: jenkins
                    groups:
                      - system:masters
              YAML

              # ArgoCD 설치
              kubectl create namespace argocd
              kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

              # Jenkins 시작
              sudo systemctl start jenkins
              sudo systemctl enable jenkins

              # Jenkins 초기 비밀번호 출력
              echo "Jenkins initial admin password:"
              sudo cat /var/lib/jenkins/secrets/initialAdminPassword

              # ArgoCD 초기 비밀번호 출력 (60초 대기 후)
              sleep 60
              echo "ArgoCD initial admin password:"
              kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
              echo ""

              sudo chown -R jenkins:jenkins /var/lib/jenkins
              EOF

  tags = {
    Name = "jenkins-test"
  }
} 