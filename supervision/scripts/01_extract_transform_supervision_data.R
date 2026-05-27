library(here)
library(tidyverse)
library(googlesheets4)

sheet <- "https://docs.google.com/spreadsheets/d/1LuXu3u-bmvYMjmc7L2YTUd5obTbBnR1qCrIJIwhUvFE/edit?gid=0#gid=0"

data_in <- read_sheet(sheet)

people <- data_in |>
  janitor::clean_names() |>
  mutate(start_date = ymd(start_date),
         end_date = ymd(end_date), 
         year = year(start_date)) |>
  mutate(across(where(is.character), ~ na_if(., "NA"))) |> 
  select(degree, 
         type, 
         b_m_student, 
         start_date, 
         end_date, 
         year, 
         status,
         eth_department,
         partner_organisation,
         thesis_title,
         data_publication_link,
         eth_collection_link)

write_csv(
  people,
  here::here("data", paste0("people", ".csv"))
)
