
library(tidyverse)

data <- read.csv("C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/combined_dataset_elapsed.csv")

window_width <- 50
step_size    <- 15
n_trials     <- 600

# creating these columns for the output CSV:
# subject	window	instructions	fa_rate	timeout_rate	slowest_quintile	RT_avg	rtcv	baseline	derivative	fa_rate_z	timeout_rate_z	slowest_quintile_z	RT_avg_z	rtcv_z	baseline_z	derivative_z


compute_fa_windows <- function(subject_data) {
  
  subject_data <- subject_data[order(subject_data$trial_number), ]
  
  trials   <- subject_data$trial_number
  feedback <- subject_data$feedbackType
  rt       <- subject_data$response_time
  pupil    <- subject_data$baseline_pupil
  timeout  <- subject_data$timeout
  t_ended  <- subject_data$trial_ended
  
  quintile_threshold  <- quantile(rt, 0.80, na.rm = TRUE)
  is_slowest          <- rt > quintile_threshold
  subject_rt_mean     <- mean(rt, na.rm = TRUE)
  
  window_starts <- seq(1, n_trials - window_width + 1, by = step_size)
  
  results <- lapply(window_starts, function(s) {
    
    idx <- which(trials >= s & trials < s + window_width)

    if (length(idx) != window_width) return(NULL)
    
    wl <- t_ended[idx[which.max(trials[idx])]]
    
    data.frame(
      window_start     = s,
      
      window_time      = wl,
      
      fa_rate = mean(feedback[idx] == -1, na.rm = TRUE),             
      
      timeout_rate = mean(timeout[idx] == 1, na.rm = TRUE),          
      
      slowest_quintile = mean(is_slowest[idx], na.rm = TRUE),        
      
      RT_avg = mean(rt[idx], na.rm = TRUE),                          
      
      rtcv = if (length(idx) < 2) NA                                 
             else sd(rt[idx], na.rm = TRUE) / subject_rt_mean,
      
      baseline = mean(pupil[idx], na.rm = TRUE),                    
      
      derivative = if (length(idx) < 2) NA                           
                   else mean(diff(pupil[idx]), na.rm = TRUE)
    )
  })
  
  results <- bind_rows(results)
  results$window <- seq_len(nrow(results))
  results$instructions <- unique(subject_data$instructions)
  
  results %>% select(window, instructions, window_start, window_time,
                     fa_rate, timeout_rate, slowest_quintile,
                     RT_avg, rtcv, baseline, derivative)
}


fa_windows_df <- data %>%
  group_by(subject) %>%
  group_modify(~ compute_fa_windows(.x)) %>%
  ungroup()

cat(sprintf("Windows per subject: %s\n",
            paste(unique(table(fa_windows_df$subject)), collapse = ", ")))

cols_to_zscore <- c("fa_rate", "timeout_rate", "slowest_quintile",
                    "RT_avg", "rtcv",
                    "baseline", "derivative")

fa_windows_df <- fa_windows_df %>%
  group_by(subject) %>%
  mutate(across(all_of(cols_to_zscore), ~ scale(.x)[,1], .names = "{.col}_z")) %>%
  ungroup()

write.csv(fa_windows_df,
          "C:/Users/lucij/Desktop/Leiden/Year 2/Thesis Project/2024_data/timed_replication_processed.csv",
          row.names = FALSE)

cat("Saved to timed_replication_processed.csv\n")