pipeline {
    agent any

    environment {
        REGISTRY_URL    = "localhost:5000"
        IMAGE_NAME      = "react-app"
        IMAGE_TAG       = "v1"
        DOCKERFILE_PATH = "./Dockerfile"
        EXPOSE_PORT     = "8081"
    }

    stages {

        /* -------------------------------------------------------
         * 1) Detect Server IP
         * ------------------------------------------------------- */
        stage('Detect Server IP') {
            steps {
                script {
                    env.SERVER_IP = sh(
                        script: "hostname -I | awk '{print $1}'",
                        returnStdout: true
                    ).trim()
                }
                echo "🌐 Detected Server IP: ${env.SERVER_IP}"
            }
        }

        /* -------------------------------------------------------
         * 2) System Information
         * ------------------------------------------------------- */
        stage('Information Gathering') {
            steps {
                sh """
                    echo '===== MACHINE IP ====='
                    echo ${SERVER_IP}
                    hostname -I

                    echo '===== DOCKER VERSION ====='
                    docker --version
                """
            }
        }

        /* -------------------------------------------------------
         * 3) Validate Docker Registry
         * ------------------------------------------------------- */
        stage('Identify Docker Registry') {
            steps {
                sh """
                    echo '🔍 Checking local registry at: http://${REGISTRY_URL}/v2/'
                    curl -f http://${REGISTRY_URL}/v2/ || echo '❌ Registry not responding!'
                """
            }
        }

        /* -------------------------------------------------------
         * 4) Build & Push Docker Image
         * ------------------------------------------------------- */
        stage('Docker Build & Push') {
            steps {
                echo "🐳 Building Docker Image..."
                sh """
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        /* -------------------------------------------------------
         * 5) Deploy Application
         * ------------------------------------------------------- */
        stage('Deploy Application') {
            steps {
                echo "🚀 Deploying React SPA..."

                sh """
                    echo 'Pulling latest image...'
                    docker pull ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}

                    echo 'Removing old container if exists...'
                    docker rm -f react_app_container || true

                    echo 'Starting new container...'
                    docker run -d --name react_app_container \
                        -p ${EXPOSE_PORT}:80 \
                        ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

    }

    /* -------------------------------------------------------
     * POST ACTIONS
     * ------------------------------------------------------- */
    post {
        success {
            echo "🎉 SUCCESS: App is LIVE at → http://${SERVER_IP}:${EXPOSE_PORT}"
        }
        failure {
            echo "❌ Deployment FAILED — Check logs above!"
        }
    }
}
