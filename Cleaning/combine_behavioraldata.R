library(dplyr)
library(readr)
library(purrr)

folder <- "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_behavioral_data"


files <- list.files(folder, pattern = "_cleaned\\.csv$", full.names = TRUE)


all_data_list <- map(files, ~ read_csv(.x, show_col_types = FALSE))


all_data_list <- map2(all_data_list, files, ~ mutate(.x, filename = basename(.y)))


all_data <- bind_rows(all_data_list)


dim(all_data)
head(all_data)


write_csv(all_data, "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_long_data_all.csv")

data_all <- read_csv("C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/cleaned_long_data_all.csv")
View(data_all)
