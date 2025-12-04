pipeline {
    agent any

    environment {
        
        DEPLOY_SERVER_IP = "192.168.100.45"   

        // 🗃️ Private Docker Registry
        REGISTRY_URL = "localhost:5000"

        // 🐳 Docker Image Details
        IMAGE_NAME = "react-app"
        IMAGE_TAG  = "v1"

        // 🌐 Application Port
        APP_PORT = "8081"

        DOCKERFILE_PATH = "./Dockerfile"

    }

    stages {

        // ---------------------------------------------------------
        // 1️⃣ SYSTEM INFORMATION GATHERING
        // ---------------------------------------------------------
        stage('Information Gathering') {
            steps {
                echo "🔍 System Information Gathering..."

                sh """
                    echo '===== DOCKER VERSION ====='
                    docker --version || exit 1

                    echo '===== DOCKER COMPOSE ====='
                    docker-compose --version || echo 'docker-compose not installed ❌'

                    echo '===== MACHINE IP ====='
                    hostname -I

                    echo '===== DISK SPACE ====='
                    df -h

                    echo '===== daemon.json ====='
                    if [ -f /etc/docker/daemon.json ]; then 
                        cat /etc/docker/daemon.json
                    else 
                        echo 'daemon.json not found (not required but recommended)'
                    fi
                """
            }
        }

        // ---------------------------------------------------------
        // 2️⃣ CHECK DOCKER REGISTRY
        // ---------------------------------------------------------
        stage('Identify Docker Registry') {
            steps {
                echo "🔎 Checking Docker Registry..."

                sh """
                    echo Checking registry at: http://${REGISTRY_URL}/v2/
                    curl -f http://${REGISTRY_URL}/v2/ \
                        || (echo '❌ Registry unreachable!' && exit 1)

                    echo '✔ Private Registry is reachable!'
                """
            }
        }

        // ---------------------------------------------------------
        // 3️⃣ DOCKER BUILD + PUSH
        // ---------------------------------------------------------
        stage('Docker Build & Push') {
            steps {
                echo "📦 Building Docker Image & Pushing to Registry..."

                sh """
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        // ---------------------------------------------------------
        // 4️⃣ DEPLOY TO TARGET SERVER
        // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // 5️⃣ PIPELINE RESULT STATUS
    // ---------------------------------------------------------
    post {
        success {
            echo "🎉 SUCCESS: App is LIVE at → http://${DEPLOY_SERVER_IP}:${APP_PORT}"
        }
        failure {
            echo "❌ FAILED: Check Jenkins logs."
        }
    }
}
