pipeline {
    agent any

    environment {
        REGISTRY_URL    = "localhost:5000"
        IMAGE_NAME      = "react-app"
        IMAGE_TAG       = "v1"
        APP_PORT        = "8081"
        DOCKERFILE_PATH = "./Dockerfile"
        COMPOSE_FILE    = "./docker-compose.yaml"
    }

    stages {

        /* 1) Detect OS (basic info only) */
        stage('Detect OS') {
            steps {
                script {
                    def os = sh(
                        script: "uname -s 2>/dev/null || echo Windows_NT",
                        returnStdout: true
                    ).trim().toLowerCase()

                    env.OS_TYPE = os.contains("linux") ? "LINUX" : "WINDOWS"
                }
                echo "🖥 OS Detected: ${env.OS_TYPE}"
            }
        }

        /* 2) System Check (Docker + Compose only) */
        stage('System Check') {
            steps {
                sh """
                    echo '===== DOCKER VERSION ====='
                    docker --version || exit 1

                    echo '===== DOCKER COMPOSE VERSION ====='
                    docker compose version || docker-compose --version
                """
            }
        }

        /* 3) Build + Push Image to registry */
        stage('Docker Build & Push') {
            steps {
                sh """
                    echo '🛠 Building Docker Image...'
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} \
                        -f ${DOCKERFILE_PATH} .

                    echo '📤 Pushing Image to Registry...'
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        /* 4) Deploy using docker-compose */
        stage('Deploy Using Compose') {
            steps {
                sh """
                    echo '🧹 Stopping old containers...'
                    docker compose -f ${COMPOSE_FILE} down || true

                    echo '🔄 Pulling updated images...'
                    docker compose -f ${COMPOSE_FILE} pull || true

                    echo '🚀 Starting new deployment...'
                    docker compose -f ${COMPOSE_FILE} up -d --force-recreate
                """
            }
        }

        /* 5) Status check after compose deployment */
        stage('Status Check') {
            steps {
                sh """
                    echo '📌 Docker Containers Status:'
                    docker compose -f ${COMPOSE_FILE} ps

                    echo '📌 Running Containers:'
                    docker ps
                """
            }
        }
    }

    post {
        success {
            echo "🎉 SUCCESS: App Live at → http://localhost:${APP_PORT}"
        }
        failure {
            echo "❌ Deployment FAILED → Check Jenkins logs"
        }
    }
}
