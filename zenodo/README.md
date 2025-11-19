# Zenodo Data Analysis

Publications from research group members (by ORCID and community).

## Project Structure

```
zenodo/
├── data/
│   ├── orcids.csv           # Input: ORCID IDs of group members
│   ├── zenodo_raw.rda       # Raw data from Zenodo API
│   └── zenodo_ghe_data.rda  # Processed Zenodo data
├── scripts/
│   ├── 01_extract_zenodo_data.R    # Zenodo API data extraction
│   └── 02_transform_zenodo_data.R  # Zenodo data transformation
└── docs/
    └── zenodo_analysis.qmd  # Zenodo analysis
```

## 1. Data Extraction

`scripts/01_extract_zenodo_data.R` queries Zenodo API for:
- Publications by ORCID (from `data/orcids.csv`)
- Publications from community (ID: 14a82a1c-740d-4ad0-a0fe-ca3808a1bd0e corresponds to openwashdata community)
- Removes duplicated records
- Saves raw data to `data/zenodo_raw.rda`

## 2. Data Transformation

`scripts/02_transform_zenodo_data.R` processes raw data:
- Filters records from January 2021 onwards
- Extracts metadata into tidy dataframes:
  - `zenodo_data`: Main publication metadata
  - `authors_data`: Author information
  - `keywords_data`: Keywords
  - `subjects_data`: Subject classifications
  - `related_identifiers_data`: Related identifiers
  - `funding_data`: Funding information
  - `communities_data`: Community affiliations
  - `github_data`: GitHub repository links
- Saves to `data/zenodo_ghe_data.rda`

## 3. Analysis

`docs/zenodo_analysis.qmd` generates visualizations and analysis. Optionally skip steps 1 and 2 by setting `eval: true` in the first chunk.

## Requirements

### R Packages

```r
install.packages(c("zen4R", "tidyverse", "lubridate", "scales", "here", "ggthemes"))
```

## Configuration

To update ORCID IDs, edit `data/orcids.csv`:

## Complete Workflow

```r
# Extract
Rscript scripts/01_extract_zenodo_data.R

# Transform
Rscript scripts/02_transform_zenodo_data.R

# Analyze
quarto render docs/zenodo_analysis.qmd
```
