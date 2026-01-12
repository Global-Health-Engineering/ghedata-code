# Description ------------------------------------------------------------------
# R script to process uploaded raw data into a tidy, analysis-ready data frame

library(googlesheets4)
library(dplyr)

# Configure authentication to use the correct email

gs4_auth(email = "lschoebitz@ethz.ch")

# Read data --------------------------------------------------------------------

## Computational Competencies - group survey from June 2025
## This survey was shared with all team members in preparation of the
## openwashdata conference. Two survey respondents are not part of the team
## and were removed before removing personal details

sheet_pre_course <- "https://docs.google.com/spreadsheets/d/19AbV2P0yybzMbrFiq8_3nPiE-Hj_OUZJLHiWqkCydEk/edit?gid=398618297#gid=398618297"

pre_course_survey <- googlesheets4::read_sheet(ss = sheet_pre_course)

# Process survey data and handle multi-answer columns
computational <- pre_course_survey |>
  mutate(id = seq(1:n())) |>
  relocate(id) |>
  filter(!id %in% c(3, 8, 17)) |>
  select(
    id,
    # gh_username = `Please provide your GitHub username. Please get an account if you do not have one: https://github.com/`,
    experience_programming_general = `Which of these best describes your experience with programming in general?`,
    experience_programming_r = `Which of these best describes your experience with programming in R?`,
    experience_programming_python = `Which of these best describes your experience with programming in Python?`,
    other_languages = `Which other programming languages / software do you have experience in?`,
    programming_confidence = `Which of these best describes how easily you could write a program in any language to find the largest number in a list?`,
    experience_git = `Which of these best describes your experience with using Git?`,
    experience_github = `Which of these best describes your experience with using GitHub?`,
    data_storage_format = `In which format do you store the majority of your data?`,
    document_writing_approach = `Which of these best describes how you write narrative documents that include text and analysis?`,
    experience_ides = `Which of these best describes your experience with using Integrated Development Environments (IDEs)?`,
    ides_used = `Which of the following Integrated Development Environments (IDEs) have you used? (Select all that apply)`,
    cli_usage = `Which of these best describes your current usage of the default command-line interface (CLI) on your operating system?\nOn Mac: The default CLI app is Terminal, and the default shell is Zsh (you may also use Bash or other shells)\nOn Windows: The default CLI app is Windows Terminal, which can run Command Prompt, PowerShell, and Bash (via Windows Subsystem for Linux)\nHow would you describe your experience?`,
    llm_usage = `Which best describes your current usage of Language Learning Models (LLMs), for example ChatGPT, for completing tasks (ideation, writing, coding)?`,
    llm_tools_used = `Which of the following Large Language Model (LLM) tools or platforms have you used for research, ideation, writing, coding, or related tasks? (Select all that apply)`,
  )



# Export Data ------------------------------------------------------------------
# Export as CSV
readr::write_csv(
  computational,
  here::here("competencies", "computational.csv")
)
