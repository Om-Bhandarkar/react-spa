pipeline {
    agent any

    environment {
        REMOTE_DIR = "/home/${USERNAME}/react-app"
    }

    stages {

        /* 0) Ask for remote machine details */
        stage('Input Remote Machine Info') {
            steps {
                script {
                    def data = input(
                        message: "Enter Remote Machine Details:",
                        parameters: [
                            string(name: 'TARGET_IP', description: 'Server IP'),
                            string(name: 'USERNAME', description: 'SSH Username'),
                            password(name: 'PASSWORD', description: 'SSH Password')
                        ]
                    )
                    
                    env.TARGET_IP = data.TARGET_IP
                    env.USERNAME  = data.USERNAME
                    env.PASSWORD  = data.PASSWORD

                    echo "➡️ Deploying to remote server: ${env.TARGET_IP}"
                }
            }
        }

        /* 1) Check + Install Docker */
        stage('Check & Install Docker') {
            steps {
                sh """
                sshpass -p '${PASSWORD}' ssh -o StrictHostKeyChecking=no ${USERNAME}@${TARGET_IP} '
                    echo "🔥 Checking Docker..."
                    if command -v docker >/dev/null 2>&1; then
                        echo "✔ Docker already installed"
                        docker --version
                    else
                        echo "❌ Docker not found → Installing..."
                        sudo apt-get update -y
                        curl -fsSL https://get.docker.com | sudo sh
                    fi
                '
                """
            }
        }

        /* 2) Check + Install Docker Compose */
        stage('Check & Install Docker Compose') {
            steps {
                sh """
                sshpass -p '${PASSWORD}' ssh -o StrictHostKeyChecking=no ${USERNAME}@${TARGET_IP} '
                    echo "⚙ Checking Docker Compose..."
                    if command -v docker-compose >/dev/null 2>&1; then
                        echo "✔ Docker Compose already installed"
                        docker-compose --version
                    else
                        echo "❌ Docker Compose not found → Installing..."
                        sudo curl -L "https://github.com/docker/compose/releases/download/2.24.6/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
                        sudo chmod +x /usr/local/bin/docker-compose
                    fi
                '
                """
            }
        }

        /* 3) Setup Postgres + Redis via Docker Containers */
        stage('Setup Postgres + Redis') {
            steps {
                sh """
                sshpass -p '${PASSWORD}' ssh -o StrictHostKeyChecking=no ${USERNAME}@${TARGET_IP} '

                    echo "=============================="
                    echo "🐘 Checking PostgreSQL Container"
                    echo "=============================="

                    if sudo docker ps -a --format "{{.Names}}" | grep -w "postgres_db" >/dev/null 2>&1; then
                        echo "✔ Postgres container exists → Starting..."
                        sudo docker start postgres_db || true
                    else
                        echo "❌ Postgres container not found → Creating..."
                        sudo docker run -d --name postgres_db \\
                            -e POSTGRES_USER=admin \\
                            -e POSTGRES_PASSWORD=root \\
                            -e POSTGRES_DB=mydb \\
                            -p 5432:5432 \\
                            --restart always \\
                            postgres:latest
                    fi


                    echo "=============================="
                    echo "🧠 Checking Redis Container"
                    echo "=============================="

                    if sudo docker ps -a --format "{{.Names}}" | grep -w "redis_server" >/dev/null 2>&1; then
                        echo "✔ Redis container exists → Starting..."
                        sudo docker start redis_server || true
                    else
                        echo "❌ Redis container not found → Creating..."
                        sudo docker run -d --name redis_server \\
                            -p 6379:6379 \\
                            --restart always \\
                            redis:latest
                    fi


                    echo "=============================="
                    echo "💚 Health Check Summary"
                    echo "=============================="

                    sudo docker ps

                    echo ""
                    echo "Postgres Logs (tail):"
                    sudo docker logs postgres_db | tail -n 5

                    echo ""
                    echo "Redis Logs (tail):"
                    sudo docker logs redis_server | tail -n 5
                '
                """
            }
        }

        /* 4) Copy docker-compose.yaml to Remote Machine */
        stage('Copy docker-compose.yaml to Remote Server') {
    steps {
        sh """
            sshpass -p '${PASSWORD}' ssh -o StrictHostKeyChecking=no ${USERNAME}@${TARGET_IP} "
                mkdir -p C:/Users/${USERNAME}/react-app
            "

            sshpass -p '${PASSWORD}' scp -o StrictHostKeyChecking=no docker-compose.yaml ${USERNAME}@${TARGET_IP}:"C:/Users/${USERNAME}/react-app/docker-compose.yaml"
        """
    }
}


        /* 5) Deploy the App on Remote Server */
        stage('Deploy Application on Remote Server') {
            steps {
                sh """
                    sshpass -p '${PASSWORD}' ssh -o StrictHostKeyChecking=no ${USERNAME}@${TARGET_IP} '
                        echo "🚀 Starting Deployment..."
                        cd ~/react-app
                        sudo docker-compose down || true
                        sudo docker-compose up -d --build --force-recreate
                    '
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment Successful on Remote Server: ${TARGET_IP}"
        }
        failure {
            echo "❌ Deployment Failed — Check Logs"
        }
    }
}
