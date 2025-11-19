#!/bin/bash

input_file="raw-data/repo_list.csv"
output_file="raw-data/contributors.csv"

# Write CSV header
echo "repository,login,contributions" > "$output_file"

# Skip header and loop over repo names (semicolon delimited, take first column)
tail -n +2 "$input_file" | while IFS=';' read -r name rest; do
  echo "Processing $name..."
  
  # Query GitHub API for contributors
  gh api /repos/Global-Health-Engineering/$name/contributors --paginate --jq ".[] | [\"$name\", .login, .contributions] | @csv" >> "$output_file"

done

echo "CSV export completed: $output_file"
