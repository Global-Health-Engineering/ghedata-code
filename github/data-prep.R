library(tidyverse)
library(lubridate)
library(ggthemes)

github_repos <- read_delim("github/raw-data/repo_list.csv", delim = ";") |>
     janitor::clean_names() |>
     mutate(
          created_year = year(created_at),
          license_dummy = ifelse(is.na(license), TRUE, FALSE),
          primary_language_ext = case_when(
               is.na(primary_language) ~ "No primary language",
               primary_language == "Jupyter Notebook" ~ "Python",
               TRUE ~ primary_language
          ),
          primary_language_ext2 = ifelse(
               !primary_language_ext %in%
                    c("Python", "R", "No primary language"),
               "Other language",
               primary_language_ext
          ),
          homepage_url_dummy = ifelse(
               is.na(homepage_url),
               "No homepage",
               "Homepage"
          ),
          publication_type = case_when(
               str_detect(string = name, pattern = "msc|bsc") ~ "Student paper",
               str_detect(string = name, pattern = "template") ~ "Template",
               TRUE ~ "Code"
          ),
          is_private = ifelse(is_private == TRUE, "Private", "Public")
     )

# Export data without private repos
github_repos_public <- github_repos |>
     filter(is_private == "Public")

# Public file
write_excel_csv(
     x = github_repos_public,
     file = "github/clean-data/github_repos_public.csv"
)

# Private file (added to .gitignore)
write_excel_csv(x = github_repos, file = "github/clean-data/github_repos.csv")
