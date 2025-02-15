pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'kokoball8686/pika'
        GIT_CREDS = credentials('github-credentials')
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
                    sh """
                        git config --global user.email "jenkins@example.com"
                        git config --global user.name "Jenkins"
                        git remote set-url origin https://${GIT_CREDS_USR}:${GIT_CREDS_PSW}@github.com/kokoball8686/aws_cicd.git
                        sed -i 's|${DOCKER_IMAGE}:.*|${DOCKER_IMAGE}:${BUILD_NUMBER}|' pika/deployment.yaml
                        git add pika/deployment.yaml
                        git commit -m "Update image tag to ${BUILD_NUMBER}"
                        git push origin HEAD:main
                    """
                }
            }
        }
    }
}
