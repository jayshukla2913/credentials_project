#!/bin/bash
# create_credentials.sh

# --- Configuration ---
USER_FILE="credentials.txt"
# JENKINS_URL="${JENKINS_URL}"
# JENKINS_USER="${JENKINS_USER}"
# JENKINS_TOKEN="${JENKINS_TOKEN}"
# ---------------------

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

    echo "Processing user: ${USER}"

    # Generate the XML structure for a Secret Text credential
    # NOTE: The DESCRIPTION is stored in the <id>, <description>, AND <secret> fields.
    CREDENTIAL_XML=$(cat <<EOF
<com.cloudbees.plugins.credentials.impl.SecretStringCredentialsImpl>
    <scope>GLOBAL</scope>
    <id>${USER}</id>
    <description>${USER}</description>
    <secret>${PASSWORD}</secret>
</com.cloudbees.plugins.credentials.impl.SecretStringCredentialsImpl>
EOF
)
    
    # Send the XML to the Jenkins API to create/update the credential
    # -s: Silent mode
    # -u: User:Token authentication
    # --data-binary @-: Pipe the standard input (the XML) as the body
    
    # We use a subshell and 'echo' the XML to ensure it's handled correctly by 'curl'
    RESPONSE=$(echo "${CREDENTIAL_XML}" | curl -X POST -s -w "%{http_code}" -o /dev/null -u "${JENKINS_USER}:${JENKINS_TOKEN}" "${JENKINS_URL}/credentials/store/system/domain/_/createCredentialsByXml" --data-binary @-)

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