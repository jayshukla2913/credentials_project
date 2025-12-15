#!/bin/bash
# create_credentials.sh

# --- Configuration ---
USER_FILE="credentials.txt"
JENKINS_URL="${JENKINS_URL}"
JENKINS_USER="${JENKINS_USER}"
JENKINS_TOKEN="${JENKINS_TOKEN}"
# ---------------------

# 1. Download the Jenkins CLI client (if it doesn't exist)
if [ ! -f "jenkins-cli.jar" ]; then
    echo "Downloading Jenkins CLI..."
    # Using -k (insecure) might be needed if your Jenkins uses a self-signed certificate.
    curl -s -k -o jenkins-cli.jar "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" 
    if [ $? -ne 0 ]; then
        echo "Error downloading jenkins-cli.jar. Check JENKINS_URL and connectivity."
        exit 1
    fi
fi

echo "--- Starting Credential Synchronization ---"

# Read the user file line by line
while IFS=, read -r USER PASSWORD; do
    # Trim leading/trailing whitespace
    USER=$(echo "$USER" | xargs)
    PASSWORD=$(echo "$PASSWORD" | xargs)

    # Skip empty lines or malformed lines
    if [ -z "$USER" ] || [ -z "$PASSWORD" ]; then
        echo "Skipping malformed or empty line."
        continue
    fi

    echo "Processing user: ${USER} using CLI 'create-credential'"

    # 2. Define a temporary XML file for the credential
    TEMP_XML_FILE="${USER}_credential.xml"

    # 3. Generate the XML structure for a Username with Password credential
    cat > "$TEMP_XML_FILE" <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
    <scope>GLOBAL</scope>
    <id>${USER}</id>
    <description>${USER}</description>
    <username>${USER}</username>
    <password>${PASSWORD}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
    
    # 4. Execute the Jenkins CLI command
    java -jar jenkins-cli.jar -s "${JENKINS_URL}" \
         -auth "${JENKINS_USER}:${JENKINS_TOKEN}" \
         create-credential system::system::${USER} < "$TEMP_XML_FILE"

    # Check the exit code of the Java command
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Credential ID ${USER} created."
    else
        echo "ERROR: Failed to create credential ${USER} via Jenkins CLI. Check User permissions."
        # If failure occurs, remove the temporary file and exit the script
        rm -f "$TEMP_XML_FILE"
        exit 1
    fi

    # 5. Clean up the temporary XML file (critical for security)
    rm -f "$TEMP_XML_FILE"

done < "$USER_FILE"

echo "--- Credential Synchronization Complete ---"

# Exit successfully