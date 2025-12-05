pipeline {
    agent any
    stages {
        stage('Connect to Windows') {
            steps {
                sh '''
                    ssh om@192.168.1.8 "hostname"
                '''
            }
        }
    }
}
