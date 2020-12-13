
#==========================================================
#                   THRESHOLD ANALYSIS
#==========================================================

# Find the coefficients with respect to the threshold in a whole stack
coefs_by_stack <- function(threshold_stack, threshold_vec){
  # get first stack 
  first_stack <- isolate_threshold(threshold_stack, as.numeric(threshold_vec[1,]))
  # add first coefficients to the coefficientstack
  coef_stack <- coefs_by_threshold(first_stack)
  for(i in 2:nrow(threshold_vec)){
    # get current threshold
    curr_threshold <- as.numeric(threshold_vec[i,])
    # current stack 
    curr_stack <- isolate_threshold(threshold_stack, curr_threshold)
    curr_coefs <- coefs_by_threshold(curr_stack)
    # recurisvely stack coef arrays in each threshold
    coef_stack <- rbind(coef_stack, curr_coefs)
  }
  coef_stack
}
# Extract the coefficients in the current threshold's stack
coefs_by_threshold <- function(curr_stack){
  # extract current threshold
  curr_threshold <- curr_stack[1,"threshold"]
  # fit the linear models for current threshold
  lm_pre <- linear_model(prerule(curr_stack))
  lm_post <- linear_model(postrule(curr_stack))
  # coefficients of the respective models
  coef_pre <- data.frame(coef_int = lm_pre$coefficients[1], 
                         coef_yr = lm_pre$coefficients[2], era = "pre",
                         threshold = curr_threshold)
  coef_post <- data.frame(coef_int = lm_post$coefficients[1], 
                          coef_yr = lm_post$coefficients[2],era = "post",
                          threshold = curr_threshold)
  # stack the coefficient array
  coefs_curr <- rbind(coef_pre, coef_post)
  # standardize rownames
  rownames(coefs_curr) <- 1:nrow(coefs_curr)
  coefs_curr
}

#==========================================================
#                   THRESHOLD ANALYSIS
#==========================================================

isolate_threshold <- function(threshold_stack, value){
  threshold_stack %>% filter(threshold == value)
}

# Creates a stack of arrays yielding couldabeens by varying threshold levels
create_threshold_stack <- function(ls_datasets, threshold_vec){
  # Begin stack by taking initial threshold
  curr_threshold <- as.numeric(threshold_vec[1,])
  threshold_stack <- couldabeens_by_threshold(ls_datasets, threshold = curr_threshold)
  # Recursively stack couldabeens with varying thresholds
  for(i in 2:nrow(threshold_vec)){
    # Obtain current threshold
    curr_threshold <- as.numeric(threshold_vec[i,])
    # Obtain couldabeens under current threshold
    curr <- couldabeens_by_threshold(ls_datasets, threshold = curr_threshold)
    # Recursively stack
    threshold_stack <- rbind(threshold_stack, curr)
  }
  # Standardize row names
  rownames(threshold_stack) <- 1:nrow(threshold_stack) 
  # Return stack
  data.frame(threshold_stack)
}

#==========================================================
#               COULDABEENS CLASSIFICATION
#==========================================================

# Aggregate function finds couldabeens for a given threshold in standard deviations from the mean rookie WAR
couldabeens_by_threshold <- function(ls_datasets, threshold = 0){
  # Obtain the sd value (esentially renaming variable)
  sd <- threshold
  # Unwind datasets from list
  df_pos_rkes <- as.data.frame(ls_datasets[1])
  df_pos_ret <- as.data.frame(ls_datasets[2])
  df_pit_rkes <- as.data.frame(ls_datasets[3])
  df_pit_ret <- as.data.frame(ls_datasets[4])
  num_retirees <- as.data.frame(ls_datasets[5])
  # Obtain wrangled datasets
  pit_rkes <- wrangle_init(df_pit_rkes)
  pit_ret <- wrangle_init(df_pit_ret)
  pos_rkes <- wrangle_init(df_pos_rkes)
  pos_ret <- wrangle_init(df_pos_ret)
  # Get thresholds in each year
  pit_thresholds <- find_thresholds(pit_rkes, sd)
  pos_thresholds <- find_thresholds(pos_rkes, sd)
  # See and record which players cross that year's adjusted threshold from rookie players
  pit_ret <- compare_thresholds(pit_ret, pit_thresholds)
  pos_ret <- compare_thresholds(pos_ret, pos_thresholds)
  # Get retired couldabeens
  retirees <- rbind(pit_ret,pos_ret)
  couldabeens <- count_cbns(retirees)
  # Append threshold for reference
  threshold_idx <- data.frame(threshold = rep(sd, nrow(couldabeens)))
  couldabeens <- cbind(couldabeens, threshold_idx)
  # Append number of retirees that year
  couldabeens <- cbind(couldabeens, num_retirees)
  # Find and append proportion of couldabeens : retirees
  couldabeens <- couldabeens %>% mutate(prop = cbns/retirees)
  # Return dataframe
  couldabeens
}

#==========================================================
#                       VISUALIZATION
#==========================================================

plot_stack <- function(stack_data, title = ""){
  # add stat_smooth by each threhsold to show trend is invariant to threshold?
  ggplot(stack_data) + 
    geom_point(mapping = aes(x = Year, y = prop, color = as.factor(threshold))) +
    theme(legend.position = "none") + 
    labs(title = title)
}