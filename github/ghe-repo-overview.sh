#!/bin/bash
# see https://cli.github.com/manual/gh_repo_list for all available JSON fields

# Set the name of the organization
org_name="Global-Health-Engineering"

# Generate a timestamp to include in the filename
timestamp=$(date "+%Y%m%d_%H%M%S")

# Define the output filename with the timestamp included
output_filename="repo_list.csv"

# Use the GitHub CLI to list all repositories within the organization and output the desired fields to the specified file
gh repo list -L 1000 $org_name --json name,description,owner,isPrivate,url,updatedAt,createdAt,licenseInfo,primaryLanguage,homepageUrl,isFork --jq '(["name", "description", "owner", "isPrivate", "url", "updatedAt", "createdAt", "license", "primaryLanguage", "homepageUrl", "isFork"] | join(";")), (.[] | [ .name, .description, .owner.login, .isPrivate, .url, (.updatedAt | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d")), (.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d")), .licenseInfo.name, .primaryLanguage.name, .homepageUrl, .isFork ] | join(";")) ' > $output_filename

echo "Output saved to $output_filename"