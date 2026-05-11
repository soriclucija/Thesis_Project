library(dplyr)
library(readr)

input_path  <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/combined_dataset_updated.csv"
output_path <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/combined_dataset_elapsed.csv"

cat("Reading dataset...\n")
df <- read_csv(input_path, show_col_types = FALSE)
cat(sprintf("  Rows: %d | Cols: %d\n\n", nrow(df), ncol(df)))

required_cols <- c("subject", "trial_number", "fix.started", "feedback.stopped")
missing <- setdiff(required_cols, names(df))
if (length(missing) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")))
}

df <- df %>%
  group_by(subject) %>%
  arrange(trial_number, .by_group = TRUE) %>%
  mutate(
    anchor        = first(fix.started),   # first fix.started for this subject
    trial_started = fix.started      - anchor,
    trial_ended   = feedback.stopped - anchor
  ) %>%
  select(-anchor) %>%
  ungroup()

cat("Elapsed time summary per subject (first 3 trials shown):\n")
preview <- df %>%
  group_by(subject) %>%
  slice_min(trial_number, n = 3) %>%
  select(subject, trial_number, fix.started, feedback.stopped, trial_started, trial_ended)
print(preview, n = Inf)

write_csv(df, output_path)
cat(sprintf("\nSaved to:\n  %s\n", output_path))