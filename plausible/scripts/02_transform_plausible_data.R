# ============================================================================
# Transform Plausible data
# ============================================================================
# This script processes existing raw Plausible data that has already been
# extracted using 01_extract_plausible_data.sh
# ============================================================================

library(here)
library(tidyverse)
library(lubridate)
library(jsonlite)
library(countrycode)

# Define path to raw data
raw_json_path <- here("data", "plausible_raw.json")

# Check if raw data file exists
if (!file.exists(raw_json_path)) {
  stop("Error: Raw Plausible data file not found: ", raw_json_path, "\n",
       "Please extract data first using:\n",
       "  ./scripts/01_extract_plausible_data.sh 'your-api-key' 'site-id' data/plausible_raw.json")
}

cat("Processing Plausible data from:", raw_json_path, "\n\n")

# Load raw JSON data
raw_data <- read_json(raw_json_path)

cat("Processing Plausible data for site:", raw_data$site_id, "\n")
cat("Data extracted at:", raw_data$extracted_at, "\n\n")

# Helper function to safely extract from list
safe_extract <- function(x, index, default = NA) {
  if (is.null(x) || length(x) < index) {
    return(default)
  }
  val <- x[[index]]
  if (is.null(val)) default else val
}

# Helper function for weighted mean with NA handling
weighted_mean_na <- function(x, w) {
  valid <- !is.na(x) & !is.na(w)
  if (sum(valid) == 0) return(NA_real_)
  weighted.mean(x[valid], w[valid])
}

# 1. Extract aggregate metrics ----
metric_names <- unlist(raw_data$aggregate$query$metrics)
metric_values <- unlist(raw_data$aggregate$results[[1]]$metrics)

aggregate_metrics <- tibble(
  site_id = raw_data$site_id
)

for (i in seq_along(metric_names)) {
  aggregate_metrics[[metric_names[i]]] <- metric_values[i]
}

cat("Aggregate metrics extracted\n")

# 2. Extract timeseries (daily data) ----
timeseries_data <- raw_data$timeseries$results |>
  map(\(row) {
    tibble(
      date = as.Date(safe_extract(row$dimensions, 1)),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0)),
      pageviews = as.integer(safe_extract(row$metrics, 3, 0)),
      bounce_rate = as.numeric(safe_extract(row$metrics, 4, 0)),
      visit_duration = as.integer(safe_extract(row$metrics, 5, 0))
    )
  }) |>
  bind_rows() |>
  arrange(date)

cat("Timeseries data extracted:", nrow(timeseries_data), "days\n")

# 3. Extract traffic sources ----
sources_data <- raw_data$sources$results |>
  map(\(row) {
    tibble(
      source = safe_extract(row$dimensions, 1, "Direct / None"),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0)),
      pageviews = as.integer(safe_extract(row$metrics, 3, 0)),
      bounce_rate = as.numeric(safe_extract(row$metrics, 4, 0)),
      visit_duration = as.integer(safe_extract(row$metrics, 5, 0))
    )
  }) |>
  bind_rows() |>
  arrange(desc(visitors))

cat("Traffic sources extracted:", nrow(sources_data), "sources\n")

# 4. Extract devices ----
devices_data <- raw_data$devices$results |>
  map(\(row) {
    tibble(
      device = safe_extract(row$dimensions, 1, "Unknown"),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0)),
      pageviews = as.integer(safe_extract(row$metrics, 3, 0)),
      bounce_rate = as.numeric(safe_extract(row$metrics, 4, 0)),
      visit_duration = as.integer(safe_extract(row$metrics, 5, 0))
    )
  }) |>
  bind_rows() |>
  arrange(desc(visitors))

cat("Devices extracted:", nrow(devices_data), "device types\n")

# 5. Extract browsers ----
browsers_data <- raw_data$browsers$results |>
  map(\(row) {
    tibble(
      browser = safe_extract(row$dimensions, 1, "Unknown"),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0))
    )
  }) |>
  bind_rows() |>
  arrange(desc(visitors))

cat("Browsers extracted:", nrow(browsers_data), "browsers\n")

# 6. Extract operating systems ----
os_data <- raw_data$os$results |>
  map(\(row) {
    tibble(
      os = safe_extract(row$dimensions, 1, "Unknown"),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0))
    )
  }) |>
  bind_rows() |>
  arrange(desc(visitors))

cat("Operating systems extracted:", nrow(os_data), "OS types\n")

# 7. Extract countries ----
countries_data <- raw_data$countries$results |>
  map(\(row) {
    tibble(
      country_code = safe_extract(row$dimensions, 1, "Unknown"),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0)),
      pageviews = as.integer(safe_extract(row$metrics, 3, 0))
    )
  }) |>
  bind_rows() |>
  mutate(
    country = countrycode(country_code, "iso2c", "country.name",
                          custom_match = c("A1" = "Anonymous Proxy")),
    country = if_else(is.na(country), country_code, country)
  ) |>
  select(country_code, country, everything()) |>
  arrange(desc(visitors))

cat("Countries extracted:", nrow(countries_data), "countries\n")

# 8. Extract top pages ----
pages_data <- raw_data$pages$results |>
  map(\(row) {
    tibble(
      page = safe_extract(row$dimensions, 1, "Unknown"),
      visitors = as.integer(safe_extract(row$metrics, 1, 0)),
      visits = as.integer(safe_extract(row$metrics, 2, 0)),
      pageviews = as.integer(safe_extract(row$metrics, 3, 0)),
      bounce_rate = as.numeric(safe_extract(row$metrics, 4, 0)),
      visit_duration = as.integer(safe_extract(row$metrics, 5, 0))
    )
  }) |>
  bind_rows() |>
  # Normalize URLs: remove /content/, /course/, and fix double slashes
  mutate(
    page = str_remove(page, "/content"),
    page = str_remove(page, "/course"),
    page = str_replace_all(page, "//+", "/")
  ) |>
  # Aggregate metrics for duplicate URLs after normalization
  summarise(
    bounce_rate = weighted_mean_na(bounce_rate, visits),
    visit_duration = weighted_mean_na(visit_duration, visits),
    visitors = sum(visitors),
    visits = sum(visits),
    pageviews = sum(pageviews),
    .by = page
  ) |>
  select(page, visitors, visits, pageviews, bounce_rate, visit_duration) |>
  arrange(desc(visitors))

cat("Top pages extracted:", nrow(pages_data), "pages\n")

# Calculate additional summary statistics
summary_stats <- timeseries_data |>
  summarise(
    total_days = n(),
    date_range_start = min(date, na.rm = TRUE),
    date_range_end = max(date, na.rm = TRUE),
    total_visitors = sum(visitors, na.rm = TRUE),
    total_visits = sum(visits, na.rm = TRUE),
    total_pageviews = sum(pageviews, na.rm = TRUE),
    avg_daily_visitors = mean(visitors, na.rm = TRUE),
    avg_daily_visits = mean(visits, na.rm = TRUE),
    avg_daily_pageviews = mean(pageviews, na.rm = TRUE),
    avg_bounce_rate = mean(bounce_rate, na.rm = TRUE),
    avg_visit_duration = mean(visit_duration, na.rm = TRUE)
  )

# Add metadata
plausible_metadata <- tibble(
  site_id = raw_data$site_id,
  extracted_at = ymd_hms(raw_data$extracted_at),
  processed_at = now(tzone = "UTC"),
  date_range_start = summary_stats$date_range_start,
  date_range_end = summary_stats$date_range_end,
  total_days = summary_stats$total_days
)

# Save all processed data
save(
  plausible_metadata,
  aggregate_metrics,
  timeseries_data,
  sources_data,
  devices_data,
  browsers_data,
  os_data,
  countries_data,
  pages_data,
  summary_stats,
  file = here("data", "plausible_data.rda")
)

cat("\n=== Processing Complete ===\n")
cat("Data saved to: plausible/data/plausible_data.rda\n")
