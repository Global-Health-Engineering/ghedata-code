# Description ------------------------------------------------------------------
# R script to process uploaded raw data into a tidy, analysis-ready data frame

library(googlesheets4)
library(dplyr)
library(purrr)

# Helper function to anonymize names ------------------------------------------

#' Anonymize names by creating anonymous IDs
#'
#' @param names Character vector of names to anonymize
#' @param prefix Character string to use as prefix (default: "participant")
#' @param seed Optional seed for reproducibility
#' @return Character vector of anonymized names
anonymize_names <- function(names, prefix = "participant", seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  chars <- c(0:9, letters)

  # Create mapping tibble for unique names
  name_mapping <- tibble(original = unique(names)) |>
    mutate(
      code = map_chr(seq_len(n()), ~paste0(sample(chars, 4, replace = TRUE), collapse = "")),
      anonymized = paste0(prefix, "-", code)
    )

  # Apply mapping to all names
  tibble(original = names) |>
    left_join(name_mapping, by = "original") |>
    pull(anonymized)
}

# Configure authentication to use the correct email

gs4_auth(email = "lschoebitz@ethz.ch")

# Read data --------------------------------------------------------------------

gs_link <- "https://docs.google.com/spreadsheets/d/1jwPueKOIVlMrHNc2f4-QaLYvO3vpD7e-b9JOOa33xzk/edit?gid=0#gid=0"

data_in <- googlesheets4::read_sheet(ss = gs_link) |> 
  janitor::clean_names()

# clean data --------------------------------------------------------------

linkedin_posts <- data_in |> 
  select(due, name, text) |> 
  filter(!stringr::str_detect(name, "break")) |> 
  mutate(
    id = seq(1:n()),
    name = anonymize_names(name, prefix = "member", seed = 2021)  # Use seed for reproducibility
  ) |>
  relocate(id) |> 
  filter(!is.na(text))

# Export Data ------------------------------------------------------------------
# Export as CSV
readr::write_csv(
  linkedin_posts,
  here::here("linkedin-posts", "linkedin-posts.csv")
)
