library(zen4R)
library(tidyverse)
library(here)

# Read ORCID IDs
orcids <- read_csv(here("zenodo", "data", "orcids.csv"), show_col_types = FALSE)

# Initialize Zenodo client
zenodo <- ZenodoManager$new(logger = NULL)

# Helper function to query with retry
query_with_retry <- function(query, max_attempts = 3) {
  for (attempt in 1:max_attempts) {
    result <- tryCatch({
      Sys.sleep(1)
      zenodo$getRecords(q = query, size = 1000)
    }, error = function(e) {
      if (attempt < max_attempts) {
        Sys.sleep(2 ^ attempt)
        NULL
      } else {
        warning("Failed after ", max_attempts, " attempts: ", query)
        list()
      }
    })
    if (!is.null(result)) return(result)
  }
  return(list())
}

# Query by ORCID
orcid_records <- orcids |>
  pull(orcid) |>
  map(\(orcid_id) {
    query_with_retry(paste0('creators.orcid:"', orcid_id, '"'))
  }) |>
  flatten()

# Query by community
community_id <- "14a82a1c-740d-4ad0-a0fe-ca3808a1bd0e"
community_records <- query_with_retry(paste0('parent.communities.ids:', community_id))

# Combine and remove duplicates by DOI
all_records <- c(orcid_records, community_records) |>
  unique()

# Extract DOIs to identify unique records
record_ids <- all_records |>
  map_chr(\(rec) rec$metadata$doi %||% rec$id) |>
  unique()

# Keep only unique records
unique_records <- all_records[!duplicated(map_chr(all_records,
                                                   \(rec) rec$metadata$doi %||% rec$id))]

# Save raw data
save(unique_records, file = here("zenodo", "data", "zenodo_raw.rda"))

cat("Extracted", length(unique_records), "unique records from Zenodo\n")
