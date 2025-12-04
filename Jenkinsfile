pipeline {
    agent any

    environment {
        // Auto-detect current server IP
        DEPLOY_SERVER_IP = sh(script: "hostname -I | awk '{print $1}'", returnStdout: true).trim()

        REGISTRY_URL = "localhost:5000"
        IMAGE_NAME = "react-app"
        IMAGE_TAG  = "v1"
        APP_PORT = "8081"
        DOCKERFILE_PATH = "./Dockerfile"
    }

    stages {

        stage('Information Gathering') {
            steps {
                echo "🔍 System Information Gathering..."
                sh """
                    echo '===== MACHINE IP DETECTED ====='
                    echo ${DEPLOY_SERVER_IP}

                    echo '===== DOCKER VERSION ====='
                    docker --version

                    echo '===== DOCKER COMPOSE ====='
                    docker-compose --version || echo 'docker-compose not installed'
                """
            }
        }

        stage('Identify Docker Registry') {
            steps {
                echo "🔎 Checking Docker Registry..."
                sh """
                    curl -f http://${REGISTRY_URL}/v2/ \
                        || (echo '❌ Registry unreachable!' && exit 1)
                    echo '✔ Private Registry is reachable!'
                """
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo "📦 Building Docker Image & Pushing to Registry..."
                sh """
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy Application') {
            steps {
                echo "🚀 Deploying locally on Jenkins server..."

                sh """
                    echo "Pulling latest image..."
                    docker pull ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}

                    echo "Stopping old container..."
                    docker rm -f react_app_container || true

                    echo "Starting new container..."
                    docker run -d --name react_app_container \
                        -p ${APP_PORT}:80 \
                        ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "🎉 SUCCESS: App is LIVE at → http://${DEPLOY_SERVER_IP}:${APP_PORT}"
        }
        failure {
            echo "❌ FAILED: Check Jenkins logs."
        }
    }
}
