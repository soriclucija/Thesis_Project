library(dplyr)
library(readr)


data_all <- read_csv(
  "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_long_data_all.csv",
  show_col_types = FALSE
)

data_instructions <- data_all %>% filter(instructions == 1)
data_no_instructions <- data_all %>% filter(instructions == 0)

cat("With instructions:", n_distinct(data_instructions$participant), "participants\n")
cat("Without instructions:", n_distinct(data_no_instructions$participant), "participants\n")


write_csv(data_instructions, "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/data_with_instructions.csv")
write_csv(data_no_instructions, "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/data_without_instructions.csv")
