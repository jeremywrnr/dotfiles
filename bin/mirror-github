#!/bin/sh
# Usage: ./mirror.sh https://github.com/user/repo.git
# Mirrors a GitHub repo to your Gitea instance.
# Requires: gh (GitHub CLI, logged in), curl

set -e

GITEA_URL="https://git.jeremywrnr.com"
GITEA_USER="jeremy"
MIRROR_INTERVAL="10m"

if [ -z "$1" ]; then
    echo "Usage: $0 <github-repo-url>"
    echo "Example: $0 https://github.com/jeremywrnr/nas.git"
    exit 1
fi

CLONE_URL="$1"
REPO_NAME=$(basename "$CLONE_URL" .git)

# Get GitHub token from gh CLI
GH_TOKEN=$(gh auth token)
CLONE_URL="https://${GH_TOKEN}@${CLONE_URL#https://}"

# Prompt for Gitea password
printf "Gitea password for $GITEA_USER: "
stty -echo
read GITEA_PASS
stty echo
echo

# Delete existing repo if it exists (ignore errors)
curl -sS -X DELETE "$GITEA_URL/api/v1/repos/$GITEA_USER/$REPO_NAME" \
    -u "$GITEA_USER:$GITEA_PASS" >/dev/null 2>&1 || true

# Create as mirror
echo "Creating mirror of $REPO_NAME on Gitea..."
RESPONSE=$(curl -sS -X POST "$GITEA_URL/api/v1/repos/migrate" \
    -H "Content-Type: application/json" \
    -u "$GITEA_USER:$GITEA_PASS" \
    -d "{
        \"clone_addr\": \"$CLONE_URL\",
        \"repo_name\": \"$REPO_NAME\",
        \"repo_owner\": \"$GITEA_USER\",
        \"mirror\": true,
        \"mirror_interval\": \"$MIRROR_INTERVAL\",
        \"private\": true,
        \"service\": \"git\"
    }")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "Done: $GITEA_URL/$GITEA_USER/$REPO_NAME"
else
    echo "Error: $RESPONSE"
    exit 1
fi
