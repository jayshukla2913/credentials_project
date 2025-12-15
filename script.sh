#!/bin/bash
# create_credentials.sh

# --- Configuration ---
USER_FILE="credentials.txt"
JENKINS_URL="${JENKINS_URL}"
JENKINS_USER="${JENKINS_USER}"
JENKINS_TOKEN="${JENKINS_TOKEN}"
# ---------------------

echo "--- Starting Credential Synchronization ---"

# Read the user file line by line
while IFS=, read -r USER PASSWORD; do
    # Trim leading/trailing whitespace
    USER=$(echo "$USER" | xargs)
    PASSWORD=$(echo "$PASSWORD" | xargs)

    if [ -z "$USER" ] || [ -z "$PASSWORD" ]; then
        echo "Skipping malformed or empty line."
        continue
    fi

    echo "Processing user: ${USER} using direct REST API"

    # Generate the XML structure for a Username with Password credential
    CREDENTIAL_XML=$(cat <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
    <scope>GLOBAL</scope>
    <id>${USER}</id>
    <description>${USER}</description>
    <username>${USER}</username>
    <password>${PASSWORD}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
)
    
    # 1. Execute the curl command with added security headers and error handling
    RESPONSE_DATA=$(
        echo "${CREDENTIAL_XML}" | 
        curl -X POST -s -w "\nHTTP_CODE:%{http_code}" -k \
        -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        -H "Content-Type: application/xml" \
        -H "Accept: application/json" \
        "${JENKINS_URL}/credentials/store/system/domain/_/createCredentialsByXml" \
        --data-binary @-
    )

    # 2. Extract the HTTP code and body for debugging
    RESPONSE_CODE=$(echo "$RESPONSE_DATA" | tail -n 1 | cut -d ':' -f 2)
    RESPONSE_BODY=$(echo "$RESPONSE_DATA" | head -n -1)

    if [ "$RESPONSE_CODE" -eq 200 ] || [ "$RESPONSE_CODE" -eq 204 ]; then
        echo "SUCCESS: Credential ID ${USER} created."
    else
        echo "ERROR: Failed to create credential ${USER}."
        echo "HTTP Code: ${RESPONSE_CODE}"
        echo "Server Response: ${RESPONSE_BODY}"
        # We must exit if the API call fails
        exit 1
    fi

done < "$USER_FILE"

echo "--- Credential Synchronization Complete ---"

# Exit successfully