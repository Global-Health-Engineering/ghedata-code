#!/bin/bash

# Script to extract website analytics data from Plausible API
# Usage: ./03_extract_plausible_data.sh <API_KEY> <SITE_ID> <OUTPUT_FILE>
#
# Arguments:
#   API_KEY: Your Plausible API key
#   SITE_ID: Your site identifier (e.g., example.com)
#   OUTPUT_FILE: Path to save the JSON output

set -e  # Exit on error

# Check if required arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <API_KEY> <SITE_ID> <OUTPUT_FILE>"
    echo "Example: $0 'your-api-key' 'example.com' 'data/plausible_raw.json'"
    exit 1
fi

API_KEY="$1"
SITE_ID="$2"
OUTPUT_FILE="$3"

# Plausible API endpoint
API_URL="https://plausible.io/api/v2/query"

# Temporary directory for individual API responses
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Fetching Plausible analytics data for: $SITE_ID"
echo "Output will be saved to: $OUTPUT_FILE"
echo ""

# Function to make API request
make_request() {
    local query=$1
    local output_file=$2
    local description=$3

    echo "Fetching: $description..."

    curl -s -X POST "$API_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" \
        -o "$output_file"

    # Check if the request was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch $description"
        exit 1
    fi

    # Check if response contains an error
    if grep -q '"error"' "$output_file"; then
        echo "API Error in $description:"
        cat "$output_file"
        exit 1
    fi

    # Small delay to respect rate limits
    sleep 0.5
}

# 1. Fetch daily timeseries data with all main metrics
TIMESERIES_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["time:day"],
  "metrics": ["visitors", "visits", "pageviews", "bounce_rate", "visit_duration"]
}
EOF
)
make_request "$TIMESERIES_QUERY" "$TEMP_DIR/timeseries.json" "Daily timeseries data"

# 2. Fetch traffic source breakdown
SOURCE_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["visit:source"],
  "metrics": ["visitors", "visits", "pageviews", "bounce_rate", "visit_duration"],
  "order_by": [["visitors", "desc"]]
}
EOF
)
make_request "$SOURCE_QUERY" "$TEMP_DIR/sources.json" "Traffic source breakdown"

# 3. Fetch device breakdown
DEVICE_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["visit:device"],
  "metrics": ["visitors", "visits", "pageviews", "bounce_rate", "visit_duration"],
  "order_by": [["visitors", "desc"]]
}
EOF
)
make_request "$DEVICE_QUERY" "$TEMP_DIR/devices.json" "Device breakdown"

# 4. Fetch browser breakdown
BROWSER_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["visit:browser"],
  "metrics": ["visitors", "visits"],
  "order_by": [["visitors", "desc"]]
}
EOF
)
make_request "$BROWSER_QUERY" "$TEMP_DIR/browsers.json" "Browser breakdown"

# 5. Fetch operating system breakdown
OS_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["visit:os"],
  "metrics": ["visitors", "visits"],
  "order_by": [["visitors", "desc"]]
}
EOF
)
make_request "$OS_QUERY" "$TEMP_DIR/os.json" "Operating system breakdown"

# 6. Fetch location (country) breakdown
COUNTRY_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["visit:country"],
  "metrics": ["visitors", "visits", "pageviews"],
  "order_by": [["visitors", "desc"]]
}
EOF
)
make_request "$COUNTRY_QUERY" "$TEMP_DIR/countries.json" "Country breakdown"

# 7. Fetch top pages
PAGES_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "dimensions": ["event:page"],
  "metrics": ["visitors", "visits", "pageviews", "bounce_rate", "visit_duration"],
  "order_by": [["visitors", "desc"]]
}
EOF
)
make_request "$PAGES_QUERY" "$TEMP_DIR/pages.json" "Top pages"

# 8. Fetch overall aggregate metrics
AGGREGATE_QUERY=$(cat <<EOF
{
  "site_id": "$SITE_ID",
  "date_range": "all",
  "metrics": ["visitors", "visits", "pageviews", "views_per_visit", "bounce_rate", "visit_duration"]
}
EOF
)
make_request "$AGGREGATE_QUERY" "$TEMP_DIR/aggregate.json" "Aggregate metrics"

# Combine all responses into a single JSON file
echo "Combining data..."
cat > "$OUTPUT_FILE" <<EOF
{
  "site_id": "$SITE_ID",
  "extracted_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "timeseries": $(cat "$TEMP_DIR/timeseries.json"),
  "sources": $(cat "$TEMP_DIR/sources.json"),
  "devices": $(cat "$TEMP_DIR/devices.json"),
  "browsers": $(cat "$TEMP_DIR/browsers.json"),
  "os": $(cat "$TEMP_DIR/os.json"),
  "countries": $(cat "$TEMP_DIR/countries.json"),
  "pages": $(cat "$TEMP_DIR/pages.json"),
  "aggregate": $(cat "$TEMP_DIR/aggregate.json")
}
EOF

echo ""
echo "Success! Data extracted and saved to: $OUTPUT_FILE"
echo "Temporary files cleaned up."
