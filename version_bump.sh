#!/usr/bin/env bash

# Define the VERSION file and README.md
VERSION_FILE="VERSION"
README_FILE="README.md"

# Check if the VERSION file exists
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Error: VERSION file not found!"
    exit 1
fi

# Read the current version
CURRENT_VERSION=$(cat "$VERSION_FILE")

# Extract the major, minor, and patch parts of the version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Check for bump type argument
BUMP_TYPE=$1

if [[ -z "$BUMP_TYPE" ]]; then
    echo "Usage: $0 <major|minor|patch>"
    exit 1
fi

# Increment the version based on the bump type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Error: Unknown bump type '$BUMP_TYPE'. Use 'major', 'minor', or 'patch'."
        exit 1
        ;;
esac

# Generate the new version
NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update the VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "Version bumped from $CURRENT_VERSION to $NEW_VERSION."

# Check if the README file exists
if [[ ! -f "$README_FILE" ]]; then
    echo "Error: README.md file not found!"
    exit 1
fi

# Perform a search and replace for the first occurrence of the version line
sed -i -E "0,/^### Version: [0-9]+\.[0-9]+\.[0-9]+$/s/^### Version: [0-9]+\.[0-9]+\.[0-9]+$/### Version: $NEW_VERSION/" "$README_FILE"

echo "README.md updated with new version: $NEW_VERSION"
