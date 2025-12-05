pipeline {
    agent any

    parameters {
        string(name: 'TARGET_IP', defaultValue: '', description: 'Enter remote machine IP')
        string(name: 'SSH_USER', defaultValue: 'ubuntu', description: 'SSH username')
        credentials(name: 'SSH_KEY', credentialType: 'SSH_USER_PRIVATE_KEY', description: 'SSH Private Key')
    }

    stages {

        stage('Stage 1: SSH Access Check') {
            steps {
                script {
                    echo "Connecting to ${params.TARGET_IP}"
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${params.SSH_USER}@${params.TARGET_IP} 'echo SSH Connected!'
                    """
                }
            }
        }

        stage('Stage 2: Identify OS') {
            steps {
                script {
                    OS = sh(
                        script: """
                            ssh -i ${SSH_KEY} ${params.SSH_USER}@${params.TARGET_IP} "uname -s 2>/dev/null || echo Windows"
                        """,
                        returnStdout: true
                    ).trim()

                    echo "Detected OS: ${OS}"
                }
            }
        }

        stage('Stage 3: Install or Health-check Tools') {
            steps {
                script {

                    if (OS == "Linux") {
                        echo "Linux Detected — Validating tools..."

                        sh """
                            ssh -i ${SSH_KEY} ${params.SSH_USER}@${params.TARGET_IP} '
                                
                                echo "-----------------------------"
                                echo "Checking Docker..."
                                echo "-----------------------------"

                                if command -v docker &>/dev/null; then
                                    echo "✔ Docker already installed"
                                    docker --version
                                else
                                    echo "✘ Docker not installed — Installing..."
                                    curl -fsSL https://get.docker.com | bash
                                fi

                                echo "-----------------------------"
                                echo "Checking Docker Compose..."
                                echo "-----------------------------"

                                if command -v docker-compose &>/dev/null; then
                                    echo "✔ Docker Compose already installed"
                                    docker-compose --version
                                else
                                    echo "✘ Docker Compose not installed — Installing..."
                                    sudo apt-get update && sudo apt-get install -y docker-compose
                                fi

                                echo "-----------------------------"
                                echo "Checking Redis Container..."
                                echo "-----------------------------"

                                if docker ps | grep -w redis; then
                                    echo "✔ Redis running"
                                    docker ps | grep redis
                                else
                                    echo "✘ Redis not running — Starting..."
                                    docker run -d --name redis -p 6379:6379 redis
                                fi

                                echo "-----------------------------"
                                echo "Checking PostgreSQL Container..."
                                echo "-----------------------------"

                                if docker ps | grep -w postgres; then
                                    echo "✔ PostgreSQL running"
                                    docker ps | grep postgres
                                else
                                    echo "✘ PostgreSQL not running — Starting..."
                                    docker run -d --name postgres -e POSTGRES_PASSWORD=root -p 5432:5432 postgres
                                fi

                                echo "-----------------------------"
                                echo "Healthcheck Completed Successfully!"
                                echo "-----------------------------"
                            '
                        """
                    } else {
                        echo "Windows Detected — Add Windows installation logic if required."
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline Execution Completed!"
        }
    }
}
