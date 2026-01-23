library(dplyr)
library(readr)
library(purrr)

input_folder <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/raw_behavioral_data/"
output_folder <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_behavioral_data/"

if (!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)

files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)

clean_file <- function(file_path) {
  
  data <- read_csv(file_path, trim_ws = TRUE)
  
  first_value <- function(x) x[which(!is.na(x) & x != "")][1]
  
  header_rows <- data %>%
    filter(is.na(trials.thisTrialN))
  
  repeat_values <- header_rows %>%
    summarise(
      instructions = first_value(instructions),
      age_slider.response = first_value(age_slider.response),
      mouse_5.clicked_name = first_value(mouse_5.clicked_name),
      mouse_6.clicked_name = first_value(mouse_6.clicked_name),
      session_start = first_value(session_start),
      session_end = first_value(session_end)
    )
  
  trial_data <- data %>%
    filter(!is.na(trials.thisTrialN)) %>%
    mutate(
      instructions = repeat_values$instructions,
      age_slider.response = repeat_values$age_slider.response,
      mouse_5.clicked_name = repeat_values$mouse_5.clicked_name,
      mouse_6.clicked_name = repeat_values$mouse_6.clicked_name,
      session_start = repeat_values$session_start,
      session_end = repeat_values$session_end
    )
  
  final_cols <- c(
    "participant",
    "session_start", "session_end",
    "og_eccentricity", "og_contrast", "og_quiescence",
    "og_stim_phase1", "og_stim_phase2", "eccentricity",
    "baseContrast", "contrastDelta", "q", "bias",
    "trials.thisRepN", "trials.thisTrialN", "trials.thisN",
    "trials.thisIndex", "thisRow.t", "signed_contrast",
    "leftCont", "rightCont", "reaction_time", "response_time",
    "correct", "timeout",
    "instructions", "age_slider.response",
    "mouse_5.clicked_name", "mouse_6.clicked_name"
  )
  
  cleaned <- trial_data %>%
    select(all_of(final_cols)) %>%
    slice_head(n = 600) %>%
    mutate(
      participant = as.double(participant),
      trial_number = row_number()
    ) %>%
    relocate(trial_number, .after = participant)
  
# adapted into R from human_ibl_snapshots code (Anne Urai, 2024, GitHub)
  cleaned <- cleaned %>%
    mutate(
      response = case_when(
        eccentricity ==  15 & correct == 1 ~ 1,
        eccentricity ==  15 & correct == 0 ~ 0,
        eccentricity == -15 & correct == 1 ~ 0,
        eccentricity == -15 & correct == 0 ~ 1,
        TRUE ~ NA_real_
      )
    )
  
  cleaned <- cleaned %>%
    rename(
      firstMovement_time = reaction_time,
      stimContrast       = contrastDelta,
      contrastLeft       = leftCont,
      contrastRight      = rightCont,
      choice             = response,
      feedbackType       = correct,
      subject            = participant
    )
  

  cleaned <- cleaned %>%
    mutate(
      stimSide = as.integer(eccentricity > 1)
    )
  

  cleaned <- cleaned %>%
    mutate(
      feedbackType = if_else(feedbackType == 0, -1, 1)
    )
  

  cleaned <- cleaned %>%
    mutate(
      response_time = response_time / 1000,
      firstMovement_time = firstMovement_time / 1000
    )
  

  max_rt <- max(cleaned$response_time, na.rm = TRUE)
  
  cleaned <- cleaned %>%
    mutate(
      response_times_max = if_else(
        is.na(response_time),
        max_rt,
        response_time
      )
    )
  

  file_name <- basename(file_path)
  output_file <- file.path(
    output_folder,
    gsub("\\.csv$", "_cleaned.csv", file_name)
  )
  
  write_csv(cleaned, output_file)
  
  return(output_file)
}

cleaned_files <- map(files, clean_file)
cleaned_files


