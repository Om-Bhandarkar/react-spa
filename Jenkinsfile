pipeline {
    agent any

    /* -------------------------------------------------------------
     * ENVIRONMENT VARIABLES
     * ------------------------------------------------------------- */
    environment {
        REGISTRY_URL    = "localhost:5000"
        IMAGE_NAME      = "react-app"
        IMAGE_TAG       = "v1"
        DOCKERFILE_PATH = "./Dockerfile"
        COMPOSE_PATH = "./docker-compose.yaml"
        EXPOSE_PORT     = "8081"

        REMOTE_IP       = "192.168.1.8"
        REMOTE_USER     = "jtsm"
        REMOTE_PASSWORD = "espl@2017"   // value will be injected from Jenkins credentials
    }

    stages {

        /* -------------------------------------------------------
         * LOAD PASSWORD FROM JENKINS CREDENTIALS
         * ------------------------------------------------------- */
        stage("Load Credentials") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'REMOTE_SSH_PASSWORD', variable: 'SSH_PASS')]) {
                        env.REMOTE_PASSWORD = SSH_PASS
                    }
                }
                echo "🔐 Credentials Loaded Successfully!"
            }
        }

        /* -------------------------------------------------------
         * DETECT LOCAL SERVER IP
         * ------------------------------------------------------- */
        stage('Detect Server IP') {
            steps {
                script {
                    env.SERVER_IP = sh(
                        script: """hostname -I | awk '{print $1}'""",
                        returnStdout: true
                    ).trim()
                }
                echo "🌐 Jenkins Server IP: ${env.SERVER_IP}"
            }
        }

        /* -------------------------------------------------------
         * PRINT LOCAL MACHINE INFO
         * ------------------------------------------------------- */
        stage('Information Gathering') {
            steps {
                sh """
                    echo '===== LOCAL MACHINE INFO ====='
                    echo "Server IP: ${SERVER_IP}"
                    hostname -I
                    echo '===== DOCKER VERSION ====='
                    docker --version
                """

                echo "📡 Remote Server Info:"
                echo "IP       → ${env.REMOTE_IP}"
                echo "User     → ${env.REMOTE_USER}"
                echo "Password → Loaded Securely"
            }
        }

        /* -------------------------------------------------------
         * CHECK LOCAL DOCKER REGISTRY
         * ------------------------------------------------------- */
        stage('Identify Docker Registry') {
            steps {
                sh """
                    echo '🔍 Checking registry: http://${REGISTRY_URL}/v2/'
                    curl -f http://${REGISTRY_URL}/v2/ || echo '❌ Registry not responding!'
                """
            }
        }

        /* -------------------------------------------------------
         * BUILD & PUSH DOCKER IMAGE
         * ------------------------------------------------------- */
        stage('Docker Build & Push') {
            steps {
                echo "🐳 Building & Pushing Docker Image..."
                sh """
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        /* -------------------------------------------------------
         * CHECK: POSTGRES & REDIS — START USING COMPOSE IF MISSING
         * ------------------------------------------------------- */
        stage('Check & Start PostgreSQL + Redis from docker-compose') {
            steps {
                script {
                    echo "🧪 Checking PostgreSQL & Redis on Remote Server..."

                    sh """
                        sshpass -p '${REMOTE_PASSWORD}' ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_IP} '

                            echo "📌 Checking PostgreSQL..."
                            if docker ps | grep -w postgres_db; then
                                echo "✔ PostgreSQL is running."
                            else
                                echo "❌ PostgreSQL not running — preparing services..."

                                DEPLOY_DIR="/home/${REMOTE_USER}/deploy"
                                COMPOSE_PATH="\$DEPLOY_DIR/docker-compose.yaml"

                                echo "🗂 Creating deploy directory..."
                                mkdir -p \$DEPLOY_DIR
                                cd \$DEPLOY_DIR

                                echo "🗑 Removing old compose file..."
                                rm -f \$COMPOSE_PATH

                                echo "📄 Creating docker-compose.yaml..."
                                cat <<EOF > \$COMPOSE_PATH
version: "3.9"

services:

  app:
    image: localhost:5000/react-app:v1
    container_name: react_app
    ports:
      - "8081:80"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: always

  postgres:
    image: postgres:latest
    container_name: postgres_db
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: root
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin"]
      interval: 5s
      timeout: 3s
      retries: 5
    restart: always

  redis:
    image: redis:latest
    container_name: redis_server
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 4s
      timeout: 3s
      retries: 5
    restart: always

volumes:
  pgdata:
EOF

                                echo "🚀 Starting PostgreSQL & Redis..."
                                docker-compose -f \$COMPOSE_PATH up -d postgres redis
                            fi

                            echo "📌 Checking Redis..."
                            if docker ps | grep -w redis_server; then
                                echo "✔ Redis is running."
                            else
                                echo "❌ Redis not running — starting via compose..."
                                cd /home/${REMOTE_USER}/deploy
                                docker-compose up -d redis
                            fi
                        '
                    """
                }
            }
        }

        /* -------------------------------------------------------
         * DEPLOY REACT APPLICATION CONTAINER
         * ------------------------------------------------------- */
        stage('Deploy Application') {
            steps {
                echo "🚀 Deploying React App on Remote Server..."

                sh """
                    sshpass -p '${REMOTE_PASSWORD}' ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_IP} '

                        echo "📥 Pulling latest image..."
                        docker pull ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}

                        echo "🗑 Removing old container..."
                        docker rm -f react_app_container || true

                        echo "🚀 Starting new React App container..."
                        docker run -d --name react_app_container \
                            -p ${EXPOSE_PORT}:80 \
                            ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}

                        echo "🎉 Deployment Completed!"
                    '
                """
            }
        }
    }

    /* -------------------------------------------------------
     * POST ACTIONS
     * ------------------------------------------------------- */
    post {
        success {
            echo "🎉 SUCCESS: App is LIVE → http://${REMOTE_IP}:${EXPOSE_PORT}"
        }
        failure {
            echo "❌ Deployment FAILED — Check logs!"
        }
    }
}
