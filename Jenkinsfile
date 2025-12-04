pipeline {
    agent any

    environment {
        REGISTRY_URL = "localhost:5000"
        IMAGE_NAME = "react-app"
        IMAGE_TAG  = "v1"
        APP_PORT = "8081"
        DOCKERFILE_PATH = "./Dockerfile"
    }

    stages {

        stage('Detect Server IP') {
            steps {
                script {
                    env.DEPLOY_SERVER_IP = sh(
                        script: "hostname -I | awk '{print \$1}'",
                        returnStdout: true
                    ).trim()
                }
                echo "🌐 Detected Server IP: ${env.DEPLOY_SERVER_IP}"
            }
        }

        stage('Information Gathering') {
            steps {
                sh """
                    echo '===== MACHINE IP ====='
                    echo ${DEPLOY_SERVER_IP}
                    hostname -I
                    docker --version
                """
            }
        }

        stage('Identify Docker Registry') {
            steps {
                sh "curl -f http://${REGISTRY_URL}/v2/"
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh """
                    docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .
                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy Application') {
            steps {
                sh """
                    docker pull ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker rm -f react_app_container || true
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
