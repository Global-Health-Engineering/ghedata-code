library(tidyverse)
library(lubridate)
library(here)

# Load raw data
load(here("data", "zenodo_raw.rda"))

# Helper function to safely extract nested fields
safe_extract <- function(x, default = NA) {
  if (is.null(x) || length(x) == 0) {
    return(default)
  }
  if (is.list(x) && !is.data.frame(x)) {
    return(paste(unlist(x), collapse = "; "))
  }
  if (length(x) > 1) {
    return(paste(x, collapse = "; "))
  }
  x
}

# Extract main metadata
zenodo_data <- unique_records |>
  map(\(rec) {
    meta <- rec$metadata

    files <- rec$files
    if (is.null(files) || !is.list(files)) files <- list()

    rights <- meta$rights
    license_id <- if (is.null(rights) || length(rights) == 0) {
      NA_character_
    } else {
      safe_extract(rights[[1]]$id, NA_character_)
    }
    license_title <- if (is.null(rights) || length(rights) == 0) {
      NA_character_
    } else {
      safe_extract(rights[[1]]$title$en, NA_character_)
    }

    # Extract DOI from pids if not in metadata
    doi <- if (!is.null(meta$doi) && !is.na(meta$doi) && meta$doi != "") {
      meta$doi
    } else if (!is.null(rec$pids$doi$identifier)) {
      rec$pids$doi$identifier
    } else {
      NA_character_
    }

    # Extract stats
    stats <- rec$stats

    tibble(
      record_id = safe_extract(rec$id),
      doi = doi,
      title = safe_extract(meta$title),
      publication_date = safe_extract(meta$publication_date),
      description = safe_extract(meta$description),
      resource_type = safe_extract(meta$resource_type$id),
      resource_subtype = safe_extract(meta$resource_type$subtype),
      access_right = safe_extract(rec$access$status),
      license_id = license_id,
      license_title = license_title,
      n_versions = ifelse(is.null(rec$versions$index), 1, rec$versions$index),
      total_size_mb = sum(map_dbl(files, \(f) {
        if (is.null(f$filesize)) 0 else as.numeric(f$filesize)
      })) / 1e6,
      views = ifelse(is.null(stats$all_versions.views), 0, stats$all_versions.views),
      unique_views = ifelse(is.null(stats$all_versions.unique_views), 0, stats$all_versions.unique_views),
      downloads = ifelse(is.null(stats$all_versions.downloads), 0, stats$all_versions.downloads),
      unique_downloads = ifelse(is.null(stats$all_versions.unique_downloads), 0, stats$all_versions.unique_downloads)
    )
  }) |>
  bind_rows() |>
  mutate(publication_date = ymd(publication_date)) |>
  filter(publication_date >= ymd("2021-01-01"))

# Extract authors
authors_data <- unique_records |>
  map(\(rec) {
    creators <- rec$metadata$creators
    if (is.null(creators) || length(creators) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      author_name = map_chr(creators, \(c) {
        safe_extract(c$person_or_org$name, NA_character_)
      }),
      author_orcid = map_chr(creators, \(c) {
        ids <- c$person_or_org$identifiers
        if (is.null(ids) || length(ids) == 0) return(NA_character_)
        orcid_id <- ids[map_lgl(ids, \(id) !is.null(id$scheme) && id$scheme == "orcid")]
        if (length(orcid_id) > 0) orcid_id[[1]]$identifier else NA_character_
      }),
      author_affiliation = map_chr(creators, \(c) {
        affs <- c$affiliations
        if (is.null(affs) || length(affs) == 0) return(NA_character_)
        paste(map_chr(affs, \(a) safe_extract(a$name, "")), collapse = "; ")
      })
    )
  }) |>
  bind_rows()

if (nrow(authors_data) > 0) {
  authors_data <- authors_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Extract keywords
keywords_data <- unique_records |>
  map(\(rec) {
    keywords <- rec$metadata$keywords
    if (is.null(keywords) || length(keywords) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      keyword = unlist(keywords)
    )
  }) |>
  bind_rows()

if (nrow(keywords_data) > 0) {
  keywords_data <- keywords_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Extract subjects
subjects_data <- unique_records |>
  map(\(rec) {
    subjects <- rec$metadata$subjects
    if (is.null(subjects) || length(subjects) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      subject = map_chr(subjects, \(s) safe_extract(s$subject))
    )
  }) |>
  bind_rows()

if (nrow(subjects_data) > 0) {
  subjects_data <- subjects_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Extract related identifiers
related_identifiers_data <- unique_records |>
  map(\(rec) {
    related <- rec$metadata$related_identifiers
    if (is.null(related) || length(related) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      related_identifier = map_chr(related, \(r) safe_extract(r$identifier)),
      relation_type = map_chr(related, \(r) safe_extract(r$relation)),
      related_resource_type = map_chr(related, \(r) safe_extract(r$resource_type, NA_character_))
    )
  }) |>
  bind_rows()

if (nrow(related_identifiers_data) > 0) {
  related_identifiers_data <- related_identifiers_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Extract funding
funding_data <- unique_records |>
  map(\(rec) {
    grants <- rec$metadata$grants
    if (is.null(grants) || length(grants) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      funder = map_chr(grants, \(g) safe_extract(g$funder$name, NA_character_)),
      grant_title = map_chr(grants, \(g) safe_extract(g$title, NA_character_)),
      grant_code = map_chr(grants, \(g) safe_extract(g$code, NA_character_))
    )
  }) |>
  bind_rows()

if (nrow(funding_data) > 0) {
  funding_data <- funding_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Extract communities
communities_data <- unique_records |>
  map(\(rec) {
    # Communities are in parent$communities$entries
    if (is.null(rec$parent) || is.null(rec$parent$communities)) return(NULL)

    community_entries <- rec$parent$communities$entries
    if (is.null(community_entries) || length(community_entries) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      community_id = map_chr(community_entries, \(c) safe_extract(c$id)),
      community_slug = map_chr(community_entries, \(c) safe_extract(c$slug, NA_character_)),
      community_title = map_chr(community_entries, \(c) {
        if (is.null(c$metadata) || is.null(c$metadata$title)) {
          NA_character_
        } else {
          safe_extract(c$metadata$title)
        }
      })
    )
  }) |>
  bind_rows()

if (nrow(communities_data) > 0) {
  communities_data <- communities_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Extract GitHub repository links
github_data <- unique_records |>
  map(\(rec) {
    related <- rec$metadata$related_identifiers
    if (is.null(related) || length(related) == 0) return(NULL)

    github_ids <- related |>
      keep(\(r) grepl("github", r$identifier, ignore.case = TRUE))

    if (length(github_ids) == 0) return(NULL)

    tibble(
      record_id = rec$id,
      github_url = map_chr(github_ids, \(r) safe_extract(r$identifier)),
      github_relation = map_chr(github_ids, \(r) {
        rel <- r$relation_type
        if (is.list(rel)) safe_extract(rel$id, NA_character_) else safe_extract(rel, NA_character_)
      })
    )
  }) |>
  bind_rows()

if (nrow(github_data) > 0) {
  github_data <- github_data |>
    filter(record_id %in% zenodo_data$record_id)
}

# Save all processed data
save(zenodo_data, authors_data, keywords_data, subjects_data,
     related_identifiers_data, funding_data, communities_data, github_data,
     file = here("data", "zenodo_ghe_data.rda"))

cat("Transformed data with", nrow(zenodo_data), "records from 2021 onwards\n")
