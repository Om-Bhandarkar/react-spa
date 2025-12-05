pipeline {
    agent any
    
    environment {
        TARGET_IP = credentials('192.168.1.8')
        SSH_USER = 'jtsm'
        SSH_PASSWORD = credentials('espl@2017')
    }
    
    stages {

        stage('Validate IP Address') {
            steps {
                script {
                    if (!env.TARGET_IP) error "TARGET_IP not set"
                    echo "Target IP: ${env.TARGET_IP}"
                }
            }
        }

        stage('SSH Test') {
            steps {
                script {
                    def status = sh(script: """
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${TARGET_IP} 'echo ok'
                    """, returnStatus: true)

                    if (status != 0) error "SSH failed!"
                    echo "SSH OK"
                }
            }
        }

        stage('Install Docker & Compose') {
            steps {
                script {

                    // Install Docker
                    sh """
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${TARGET_IP} 'which docker || curl -fsSL https://get.docker.com | sh'
                    """

                    // Install Docker Compose
                    sh """
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${TARGET_IP} '
                        docker compose version || (
                        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" \
                        -o /usr/local/bin/docker-compose &&
                        chmod +x /usr/local/bin/docker-compose
                        )'
                    """
                }
            }
        }

        stage('Upload Frontend & Compose File') {
            steps {
                script {

                    // Upload docker-compose file
                    writeFile file: 'docker-compose.yml', text: '''
version: '3.8'

services:

  frontend:
    build: /opt/frontend
    ports:
      - "80:80"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: apppass123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
                    '''

                    sh """
                        scp -o StrictHostKeyChecking=no docker-compose.yml \
                        ${SSH_USER}@${TARGET_IP}:/opt/docker-compose.yml
                    """

                    // Upload frontend source
                    sh """
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no ${SSH_USER}@${TARGET_IP} 'rm -rf /opt/frontend'
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no ${SSH_USER}@${TARGET_IP} 'mkdir -p /opt/frontend'
                        scp -o StrictHostKeyChecking=no -r ./frontend/* ${SSH_USER}@${TARGET_IP}:/opt/frontend/
                    """
                }
            }
        }

        stage('Deploy Containers') {
            steps {
                script {

                    sh """
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${TARGET_IP} 'cd /opt && docker compose -f docker-compose.yml down || true'
                    """

                    sh """
                        sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${TARGET_IP} 'cd /opt && docker compose -f docker-compose.yml up -d --build'
                    """

                    echo "Deployment Completed!"
                }
            }
        }
    }

    post {
        always {
            script {
                def output = sh(script: """
                    sshpass -p '${SSH_PASSWORD}' ssh -o StrictHostKeyChecking=no \
                    ${SSH_USER}@${TARGET_IP} 'docker ps --format "table {{.Names}}\\t{{.Status}}"'
                """, returnStdout: true)

                echo "Containers Running:"
                echo output
            }
        }
    }
}
