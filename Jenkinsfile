pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'kokoball8686/pika'
    }
    
    stages {
        stage('Git Clone') {
            steps {
                checkout scm
            }
        }
        
        stage('Update Kubernetes manifests') {
            steps {
                script {
                    // pika/deployment.yaml의 이미지 태그를 빌드 번호로 업데이트
                    sh """
                        sed -i 's|${DOCKER_IMAGE}:.*|${DOCKER_IMAGE}:${BUILD_NUMBER}|' pika/deployment.yaml
                        git config --global user.email "jenkins@example.com"
                        git config --global user.name "Jenkins"
                        git add pika/deployment.yaml
                        git commit -m "Update image tag to ${BUILD_NUMBER}"
                        git push origin HEAD:main
                    """
                }
            }
        }
    }
} 