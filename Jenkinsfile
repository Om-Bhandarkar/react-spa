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

        /* 1) Detect OS */
        stage('Detect OS') {
            steps {
                script {
                    def os = sh(
                        script: "uname -s 2>/dev/null || echo Windows_NT",
                        returnStdout: true
                    ).trim().toLowerCase()

                    if (os.contains("linux")) env.OS_TYPE = "LINUX"
                    else env.OS_TYPE = "WINDOWS"
                }
                echo "🖥 OS Detected: ${env.OS_TYPE}"
            }
        }

        /* 2) System Info */
        stage('System Check') {
            steps {
                sh """
                    docker --version || echo '❌ Docker not installed'
                    docker compose version || docker-compose --version || echo '❌ Compose not installed'
                """
            }
        }

        /* 3) Check Docker, Compose, Postgres, Redis */
        stage('Check Dependencies & Start DB Containers') {
            when { environment name: 'OS_TYPE', value: 'LINUX' }
            steps {
                echo "🔍 Checking Docker, Docker-Compose, Postgres, Redis..."

                sh """
                    echo '===== DOCKER CHECK ====='
                    if command -v docker >/dev/null; then
                        echo '✔ Docker Installed'
                    else
                        echo '❌ Docker NOT installed → Installing'
                        apt update && apt install -y docker.io
                    fi

                    echo '===== DOCKER COMPOSE CHECK ====='
                    if docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null; then
                        echo '✔ Docker Compose Installed'
                    else
                        echo '❌ Compose NOT installed → Installing'
                        apt install -y docker-compose || true
                    fi

                    echo '===== POSTGRES CHECK ====='
                    docker rm -f postgres_db || true
                    if command -v psql >/dev/null; then
                        echo '✔ PostgreSQL Installed → Healthcheck'
                        pg_isready || echo '⚠ Postgres may not be healthy'
                    else
                        echo '❌ PostgreSQL NOT installed → Creating Docker Container'

                        if ! docker ps -a --format '{{.Names}}' | grep -w postgres_db; then
                            docker run -d --name postgres_db \
                                -e POSTGRES_USER=admin \
                                -e POSTGRES_PASSWORD=root \
                                -e POSTGRES_DB=mydb \
                                -p 5432:5432 \
                                postgres
                        else
                            docker start postgres_db
                        fi

                        echo '⏳ Waiting for Postgres...'
                        sleep 10
                        docker exec postgres_db pg_isready || echo '⚠ Postgres container not ready'
                    fi

                    echo '===== REDIS CHECK ====='
                    if command -v redis-server >/dev/null; then
                        echo '✔ Redis Installed → Healthcheck'
                        redis-cli ping || echo '⚠ Redis may not be healthy'
                    else
                        echo '❌ Redis NOT installed → Creating Docker Container'

                        if ! docker ps -a --format '{{.Names}}' | grep -w redis_server; then
                            docker run -d --name redis_server -p 6379:6379 redis
                        else
                            docker start redis_server
                        fi

                        echo '⏳ Waiting for Redis...'
                        sleep 3
                        docker exec redis_server redis-cli ping || echo '⚠ Redis container not ready'
                    fi
                """
            }
        }

        /* 4) Build + Push Image */
        stage('Docker Build & Push') {
            steps {
                sh """
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        /* 5) Deploy via Compose */
        stage('Deploy Using Compose') {
            steps {
                sh """
                    docker compose -f ${COMPOSE_FILE} pull || true
                    docker compose -f ${COMPOSE_FILE} down
                    docker compose -f ${COMPOSE_FILE} up -d --force-recreate
                """
            }
        }

        /* 6) Post Deploy Status */
        stage('Status Check') {
            steps {
                sh """
                    docker compose -f ${COMPOSE_FILE} ps
                """
            }
        }
    }

    post {
        success {
            echo "🚀 SUCCESS: App Live at http://${DEPLOY_SERVER_IP}:${APP_PORT}"
        }
        failure {
            echo "❌ FAILED: Check logs."
        }
    }
}
