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
                echo 'gathering credentials...'
                script {
                    def filePath = 'new_users.txt'
                    def fileContent = readFile(filePath)
                    def lines = fileContent.trim().split('\n')
                    lines.each { line ->
                            // Parse each line: ID, Description
                            def parts = line.split(',', 2).collect { it.trim() }
                            
                            if (parts.size() == 2) {
                                def user = parts[0]
                                def password = parts[1]
                                
                            echo "Attempting to create credential ID: ${user}"
                            // 2. Construct the XML for a Secret Text credential
                                // This is the standard way to create any Jenkins credential via CLI.
                                // NOTE: We use SecretText to store the Description as the secret value.
                                def credentialXml = """
                                <com.cloudbees.plugins.credentials.impl.SecretStringCredentialsImpl>
                                <scope>GLOBAL</scope>
                                <id>${user}</id>
                                <description>${user}</description>
                                <secret>${password}</secret> 
                                </com.cloudbees.plugins.credentials.impl.SecretStringCredentialsImpl>
                                """
                                // 3. Execute the Jenkins CLI command using curl/API
                                // We pipe the XML into the create-credential-by-xml endpoint.
                                sh """
                                    echo "${credentialXml}" | curl -X POST -s -u \
                                    \${JENKINS_USER}:\${JENKINS_TOKEN} \
                                    \${JENKINS_URL}/credentials/store/system/domain/_/createCredentialsByXml \
                                    --data-binary @-
                                """
                                echo "Credential ${user} created/updated."
                                
                            } else {
                                echo "Skipping malformed line: ${line}"
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