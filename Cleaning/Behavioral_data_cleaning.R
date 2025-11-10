library(dplyr)
library(readr)
library(purrr)

input_folder <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/raw_behavioral_data/"
output_folder <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_behavioral_data/"


if(!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)

files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)

clean_file <- function(file_path) {
  data <- read_csv(file_path, trim_ws = TRUE)
  
  first_value <- function(x) x[which(!is.na(x) & x != "")][1]
  
  repeat_values <- data[1:20, ] %>%
    summarise(
      instructions = first_value(instructions),
      age_slider.response = first_value(age_slider.response),
      mouse_5.clicked_name = first_value(mouse_5.clicked_name),
      mouse_6.clicked_name = first_value(mouse_6.clicked_name),
      session_start = first_value(session_start)
    )
  
  trial_data <- data[-c(1:20), ] %>%
    mutate(
      instructions = repeat_values$instructions,
      age_slider.response = repeat_values$age_slider.response,
      mouse_5.clicked_name = repeat_values$mouse_5.clicked_name,
      mouse_6.clicked_name = repeat_values$mouse_6.clicked_name,
      session_start = repeat_values$session_start
    )
  
  final_cols <- c(
    "participant",
    "session_start",
    "og_eccentricity", "og_contrast", "og_quiescence",
    "og_stim_phase1", "og_stim_phase2", "eccentricity",
    "baseContrast", "contrastDelta", "q", "bias",
    "trials.thisRepN", "trials.thisTrialN", "trials.thisN",
    "trials.thisIndex", "thisRow.t", "signed_contrast",
    "leftCont", "rightCont", "reaction_time", "response_time",
    "correct", "timeout",
    "instructions", "age_slider.response", "mouse_5.clicked_name", "mouse_6.clicked_name"
  )
  
  cleaned <- trial_data %>% select(all_of(final_cols)) %>% slice(1:600)
  
  file_name <- basename(file_path)
  output_file <- file.path(output_folder, gsub("\\.csv$", "_cleaned.csv", file_name))
  
  write_csv(cleaned, output_file)
  
  return(output_file)
}


cleaned_files <- map(files, clean_file)
cleaned_files


