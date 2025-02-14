pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/kokoball8686/aws_cicd.git'
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    kubectl apply -f k8s/manifests/
                    kubectl apply -f k8s/argocd/
                '''
            }
        }
    }
} 