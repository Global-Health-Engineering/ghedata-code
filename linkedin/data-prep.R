library(tidyverse)
library(readxl)
library(lubridate)
library(ggthemes)


# Content: Metrics -------------------------------------------------------

content_paths <- c(
  "raw-data/2024-08/ghe_content.xls",
  "raw-data/2025-03/ghe_content.xls",
  "raw-data/2025-05/ghe_content.xls",
  "raw-data/2025-07/ghe_content.xls",
  "raw-data/2025-11/ghe_content.xls",
  "raw-data/2026-05/global-health-engineering_content_1779873554864.xls"
)

content_list <- map(content_paths, ~ read_xls(.x, skip = 1))

# Final LinkedIn Content df
content_df <- bind_rows(content_list) |>
  distinct(Date, .keep_all = TRUE) |>
  janitor::clean_names() |>
  mutate(date_updated = mdy(date)) |>
  select(date = date_updated, contains("total"))

names(content_df) <- gsub(
  x = names(content_df),
  pattern = "_total",
  replacement = ""
)

write_excel_csv(x = content_df, file = "clean-data/content-overview.csv")

# visualization example
content_df %>%
  group_by(month = floor_date(date, "week")) %>%
  summarise(
    sum_value = sum(impressions, na.rm = TRUE),
    mean_value = mean(impressions, na.rm = TRUE),
    .groups = "drop"
  ) |>
  ggplot(aes(x = month, y = sum_value)) +
  geom_col() +
  geom_smooth() +
  labs(
    title = "Fewer and fewer impressions...",
    subtitle = "One bar represents one week",
    x = "",
    y = "Impressions\n"
  ) +
  theme_few()

# Content: All posts -------------------------------------------------------

content_post_paths <- c(
  "raw-data/2026-05/global-health-engineering_content_1779873554864.xls",
  "raw-data/2025-11/ghe_content.xls",
  "raw-data/2025-07/ghe_content.xls",
  "raw-data/2025-05/ghe_content.xls",
  "raw-data/2025-03/ghe_content.xls",
  "raw-data/2024-08/ghe_content.xls"
)

content_post_list <- map(
  content_post_paths,
  ~ read_xls(.x, skip = 1, sheet = "All posts")
)

content_post_df <- bind_rows(content_post_list) |>
  janitor::clean_names() |>
  distinct(post_title, .keep_all = TRUE) |>
  select(
    -c(
      post_type,
      contains("campaign"),
      posted_by,
      audience,
      offsite_views,
      follows,
      content_type
    )
  ) |>
  mutate(date = mdy(created_date)) |>
  select(-created_date) |>
  relocate(date) |>
  arrange(date)

write_excel_csv(
  x = content_post_df,
  file = "clean-data/content_posts-overview.csv"
)


# Followers: New followers --------------------------------------------------------------

current_n_followers_ghe <- 3003

new_followers_file_paths <- c(
  "raw-data/2024-08/ghe_followers.xls",
  "raw-data/2025-03/ghe_followers.xls",
  "raw-data/2025-05/ghe_followers.xls",
  "raw-data/2025-07/ghe_followers.xls",
  "raw-data/2025-11/ghe_followers.xls",
  "raw-data/2026-05/global-health-engineering_followers_1779873631711.xls"
)

new_followers_data_list <- map(
  new_followers_file_paths,
  ~ read_xls(.x, skip = 0)
)

# Final LinkedIn Content df
new_followers_df <- bind_rows(new_followers_data_list) |>
  distinct(Date, .keep_all = TRUE) |>
  janitor::clean_names() |>
  mutate(date_updated = mdy(date)) |>
  mutate(new_followers = cumsum(total_followers)) |>
  mutate(
    cumulative_followers = new_followers +
      (current_n_followers_ghe - max(new_followers))
  ) |>
  select(
    date = date_updated,
    followers = total_followers,
    new_followers,
    cumulative_followers
  )

write_excel_csv(
  x = new_followers_df,
  file = "clean-data/new-followers.csv"
)
