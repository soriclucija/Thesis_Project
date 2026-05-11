library(dplyr)
library(readr)

behavioral_folder <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_behavioral_data"
combined_path     <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/combined_dataset.csv"
output_path       <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/combined_dataset_updated.csv"

cat("Reading combined dataset...\n")
combined <- read_csv(combined_path, show_col_types = FALSE)
cat(sprintf("  Rows: %d | Cols: %d\n\n", nrow(combined), ncol(combined)))

csv_files <- list.files(
  path       = behavioral_folder,
  pattern    = "_cleaned\\.csv$",
  full.names = TRUE
)

cat(sprintf("Found %d cleaned behavioral file(s):\n", length(csv_files)))
cat(paste0("  ", basename(csv_files), "\n"), sep = "")
cat("\n")

if (length(csv_files) == 0) {
  stop("No *_cleaned.csv files found in the folder. Check the path.")
}

cols_needed <- c("subject", "trial_number", "fix.started", "feedback.stopped", "trial_length")

behavioral_data <- lapply(csv_files, function(f) {
  df <- read_csv(f, show_col_types = FALSE)

  # Check all required columns exist
  missing <- setdiff(cols_needed, names(df))
  if (length(missing) > 0) {
    warning(sprintf("File '%s' is missing columns: %s — skipping.",
                    basename(f), paste(missing, collapse = ", ")))
    return(NULL)
  }

  df %>% select(all_of(cols_needed))
}) %>%
  bind_rows()

cat(sprintf("Behavioral data stacked: %d rows across all subjects.\n\n", nrow(behavioral_data)))

combined <- combined %>%
  select(-any_of(c("fix.started", "feedback.stopped", "trial_length")))

combined_updated <- combined %>%
  left_join(behavioral_data, by = c("subject", "trial_number"))

n_matched   <- sum(!is.na(combined_updated$fix.started))
n_unmatched <- sum( is.na(combined_updated$fix.started))

cat(sprintf("Merge complete:\n"))
cat(sprintf("  Rows matched (fix.started filled):   %d\n", n_matched))
cat(sprintf("  Rows unmatched (fix.started is NA):  %d\n", n_unmatched))

if (n_unmatched > 0) {
  cat("\n  Unmatched rows (subject + trial_number not found in behavioral files):\n")
  unmatched_preview <- combined_updated %>%
    filter(is.na(fix.started)) %>%
    select(subject, trial_number) %>%
    distinct() %>%
    slice_head(n = 10)
  print(unmatched_preview)
  if (n_unmatched > 10) cat("  ... (showing first 10 only)\n")
}


write_csv(combined_updated, output_path)
cat(sprintf("\nSaved updated combined dataset to:\n  %s\n", output_path))