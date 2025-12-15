pipeline {
    agent any

    environment {
        JENKINS_USER = credentials('jayshukla29_13') // Jenkins admin username
        JENKINS_TOKEN = credentials('jenkins_api_token') // Jenkins API token
        JENKINS_URL = 'http://107.23.4.27:8080' // Jenkins server URL
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'checking out source code...'
            }
        }
        stage('Read and upload Credentials') {
            steps {
                script {
                    // 1. Get the Jenkins URL (important for the script's API call)
                    def jenkinsUrl = sh(returnStdout: true, script: 'echo ${JENKINS_URL}').trim()
                    
                    // 2. Use withCredentials to safely retrieve the Admin Token
                    withCredentials([usernamePassword(
                        credentialsId: '${JENKINS_TOKEN}', // ID of the Admin User/Token
                        usernameVariable: 'JENKINS_USER',
                        passwordVariable: 'JENKINS_TOKEN'
                    )]) {
                        
                        // 3. Execute the shell script, passing the environment variables
                        // The script needs to be executable.
                        sh """
                        chmod +x create_credentials.sh
                        ./create_credentials.sh
                        """
                        // Pass the Jenkins URL as an environment variable to the script
                        // sh(script: "./create_credentials.sh", env: ["JENKINS_URL": "${jenkinsUrl}"])
                        // Note: JENKINS_URL is typically available by default, but defining it 
                        // explicitly ensures robustness.
                        
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}