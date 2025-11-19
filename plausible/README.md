# Plausible Website Analytics

Website analytics for tracking site traffic and engagement.

## Project Structure

```
plausible/
├── data/
│   ├── plausible_raw.json   # Raw data from Plausible API
│   └── plausible_data.rda   # Processed Plausible data
├── scripts/
│   ├── 01_extract_plausible_data.sh   # Plausible API data extraction
│   └── 02_transform_plausible_data.R  # Plausible data transformation
└── docs/
    └── plausible_analysis.qmd  # Website analytics analysis
```

## 1. Data Extraction

Usage:
```bash
./scripts/01_extract_plausible_data.sh 'your-api-key-here' 'example.com' data/plausible_raw.json
```

Fetches from Plausible API:
- Daily timeseries data (all available history)
- Traffic sources breakdown
- Device, browser, and OS statistics
- Geographic distribution (countries)
- Top 20 pages
- Overall aggregate metrics

**Note**: Plausible has a rate limit of 600 requests per hour by default. The script includes delays to respect this limit.

## 2. Data Transformation

`scripts/02_transform_plausible_data.R` processes the raw data file that was extracted in step 1:
- Extract and structure data into tidy dataframes:
  - `timeseries_data`: Daily metrics (visitors, visits, pageviews, bounce rate, visit duration)
  - `sources_data`: Traffic source breakdown
  - `devices_data`: Device type statistics
  - `browsers_data`: Browser usage
  - `os_data`: Operating system distribution
  - `countries_data`: Geographic breakdown
  - `pages_data`: Top 20 pages performance
  - `aggregate_metrics`: Overall totals
  - `summary_stats`: Calculated summary statistics
  - `plausible_metadata`: Extraction metadata
- Save to `data/plausible_data.rda`

**Note**: The script expects `data/plausible_raw.json` to already exist. If the file is not found, you'll need to run the extraction script first (step 1).

## 3. Analysis

`docs/plausible_analysis.qmd` generates website analytics visualizations and summaries. Optionally skip steps 1 and 2 by setting `eval: true` in the first chunk.

## Requirements

### R Packages

```r
install.packages(c("tidyverse", "lubridate", "scales", "jsonlite", "ggthemes", "here"))
```

### System Requirements

- **curl**: Required for Plausible API data extraction (usually pre-installed on macOS/Linux)
- **Plausible API Key**: Required for fetching website analytics data 

## Configuration

For the Plausible workflow, you need:

1. **API Key**: Generate at https://plausible.io/settings
   - Keep it secure and never commit it to version control

2. **Site ID**: Your website domain (e.g., `example.com`)

**Security Note**: It's recommended to store your API key in an environment variable:

## Complete Workflow

```bash
# 1. Extract data from Plausible API
./scripts/01_extract_plausible_data.sh 'your-api-key' 'example.com' data/plausible_raw.json

# 2. Transform data
Rscript scripts/02_transform_plausible_data.R

# 3. Generate analysis report
quarto render docs/plausible_analysis.qmd
```
