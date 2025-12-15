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
    # Note: Use your full, correct JENKINS_URL here, including context root if needed
    curl -s -o jenkins-cli.jar "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
    if [ $? -ne 0 ]; then
        echo "Error downloading jenkins-cli.jar. Check JENKINS_URL and connectivity."
        exit 1
    fi
fi

# Check if the user file exists
if [ ! -f "$USER_FILE" ]; then
    echo "Error: User data file '$USER_FILE' not found."
    exit 1
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

echo "Processing user: ${USER} using Jenkins CLI (UsernamePassword Method)"

# 2. Construct the Groovy Script for 'Username and password'
GROOVY_SCRIPT=$(cat <<EOF
import com.cloudbees.plugins.credentials.domains.Domain;
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl; // <-- CHANGED CLASS
import com.cloudbees.plugins.credentials.CredentialsScope;

// Get the Credentials Provider (the management service)
def store = jenkins.model.Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.CredentialsProvider').get(0).getStore(jenkins.model.Jenkins.instance);

// Create the new UsernamePasswordCredentialsImpl instance
def credential = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "${USER}",          // ID (Required by the constructor)
    "${USER}",          // Description (Using User as description)
    "${USER}",          // Username
    "${PASSWORD}"       // Password (The secret value)
);

// Add the credential to the global store
store.addCredentials(Domain.global(), credential);
println "SUCCESS: Credential ${USER} added."
EOF
)
    
# 3. Execute the CLI command with the Groovy script
java -jar jenkins-cli.jar -s "${JENKINS_URL}" \
     -auth "${JENKINS_USER}:${JENKINS_TOKEN}" \
     groovy = <<< "$GROOVY_SCRIPT"

# Check the exit code of the Java command
if [ $? -eq 0 ]; then
    echo "Successfully created/updated credential ID: ${USER}"
else
    # The error message should now contain the Groovy script's output
    echo "Error: Failed to create credential ${USER} via Jenkins CLI. Check logs."
    exit 1
fi

    # Generate the XML structure for a Secret Text credential
    # NOTE: The DESCRIPTION is stored in the <id>, <description>, AND <secret> fields.
    
    # Send the XML to the Jenkins API to create/update the credential
    # -s: Silent mode
    # -u: User:Token authentication
    # --data-binary @-: Pipe the standard input (the XML) as the body
    
    # We use a subshell and 'echo' the XML to ensure it's handled correctly by 'curl'
    RESPONSE=$(echo "${CREDENTIAL_XML}" | curl -X POST -s -w "%{http_code}" -o /dev/null -u "${JENKINS_USER}:${JENKINS_TOKEN}" "${JENKINS_URL}/credentials/store/system/domain/_/createCredentialsByXml" --data-binary @-)

    echo "DEBUG: Attempting API call to: ${JENKINS_URL}/credentials/store/system/domain/_/createCredentialsByXml"

    if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 204 ]; then
        echo "Successfully created/updated credential ID: ${USER}"
    else
        echo "Error creating credential ${USER}. HTTP Code: ${RESPONSE}"
        # Exit with error if any credential fails to be created
        exit 1
    fi

done < "$USER_FILE"

echo "--- Credential Synchronization Complete ---"

# Exit successfully