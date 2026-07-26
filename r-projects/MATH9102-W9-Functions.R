# ---- Load (and install if needed) required packages ----

packages <- c(
  "grid",
  "gridExtra",
  "semTools",
  "ggplot2",
  "pastecs",
  "FSA",
  "car",
  "psych",
  "effectsize"
)

# Install any that are missing
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  message("Installing missing packages: ", paste(packages[!installed], collapse = ", "))
  install.packages(packages[!installed], dependencies = TRUE)
}

# Load all quietly
invisible(lapply(packages, function(pkg) {
  suppressMessages(library(pkg, character.only = TRUE))
}))


# Install any that are missing
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed], dependencies = TRUE)
}

# Load all
invisible(lapply(packages, library, character.only = TRUE))


# Install any that are missing
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed], dependencies = TRUE)
}

# Load them all
invisible(lapply(packages, library, character.only = TRUE))


# Function to generate plots for  ratio variable
# Example usage:
# plot_ratio_variable(survey, "tpstress", "Total Perceived Stress", 1)
plot_ratio_variable <- function(data, variable_name, descriptive_name, figure_number) {
    # Ensure the variable exists in the dataset
  if (!variable_name %in% colnames(data)) {
    stop(paste("Variable", variable_name, "not found in the dataset."))
  }
  
  # Create histogram using tidy evaluation
  gs <- ggplot(data, aes(x = .data[[variable_name]])) +
    geom_histogram(
      binwidth = 2,
      colour = "black",
      aes(y = after_stat(density), fill = after_stat(count))
    ) +
    scale_fill_gradient("Count", low = "#DCDCDC", high = "#7C7C7C") +
    stat_function(
      fun = dnorm,
      color = "red",
      args = list(
        mean = mean(data[[variable_name]], na.rm = TRUE),
        sd = sd(data[[variable_name]], na.rm = TRUE)
      )
    ) +
    labs(
      x = descriptive_name,
      y = "Density",
      title = "Histogram"
    ) +
    theme_minimal() +
    theme(panel.border = element_rect(color = "black", fill = NA, linewidth = 1))
  
  # Create QQ plot
  qq_plot <- ggplot(data.frame(variable = data[[variable_name]]), aes(sample = variable)) +
    stat_qq() +
    stat_qq_line(color = "red") +
    labs(
      title = "QQ Plot",
      x = "Theoretical Quantiles",
      y = "Sample Quantiles"
    ) +
    theme_minimal() +
    theme(panel.border = element_rect(color = "black", fill = NA, linewidth = 1))
  
  # Combine the plots in a grid with additional space at the bottom
  grid.arrange(
    gs,
    qq_plot,
    ncol = 2,
    bottom = textGrob(
      paste("Figure", figure_number, ":", descriptive_name, "Plots"),
      gp = gpar(fontsize = 12)
    ),
    heights = unit(c(5, 1), "null")  # Adjust spacing after the plots
  )
}


# Function to generate statistics needed to assess normality of a ratio variable
# Example usage:
# analyze_ratio_variable(survey, "tpstress")
analyze_ratio_variable <- function(data, variable_name) {
  # Ensure the variable exists in the dataset
  if (!variable_name %in% colnames(data)) {
    stop(paste("Variable", variable_name, "not found in the dataset."))
  }
  
  # Extract the variable
  variable <- data[[variable_name]]
  
  # Generate summary statistics
  stats <- pastecs::stat.desc(variable, basic = FALSE)
  
  
  # Calculate standardized skewness and kurtosis
  skew <- semTools::skew(variable)
  kurt <- semTools::kurtosis(variable)
  skewness_standardized <- skew[1] / skew[2]
  kurtosis_standardized <- kurt[1] / kurt[2]
  
  # Round skewness and kurtosis
  skewness_rounded <- round(abs(skewness_standardized), 2)
  kurtosis_rounded <- round(abs(kurtosis_standardized), 2)
  
  # Determine skewness and kurtosis judgment
  skew_judgment <- ifelse(skewness_rounded < 2, "acceptable", "unacceptable")
  kurtosis_judgment <- ifelse(kurtosis_rounded < 2, "acceptable", "unacceptable")
  
  # Calculate percentage of standardized scores outside acceptable limits
  z_scores <- abs(scale(variable))
  perc_gt_3_29 <- FSA::perc(as.numeric(z_scores), 3.29, "gt")
  
  # Judgment on normality (99.8% within bounds)
  normality_judgment <- ifelse(perc_gt_3_29 < 0.3, "can be considered normal", "not normal")
  
  # Central tendency and dispersion
  if (normality_judgment == "not normal") {
    central_tendency <- paste("Mdn:", round(median(variable, na.rm = TRUE), 2), 
                              "IQR:", round(IQR(variable, na.rm = TRUE), 2))
  } else {
    central_tendency <- paste("M:", round(mean(variable, na.rm = TRUE), 2), 
                              "SD:", round(sd(variable, na.rm = TRUE), 2))
  }
  
  # Return a list with the relevant values
  return(list(
    skewness_rounded = skewness_rounded,
    skew_judgment = skew_judgment,
    kurtosis_rounded = kurtosis_rounded,
    kurtosis_judgment = kurtosis_judgment,
    perc_outside_3_29 = round(perc_gt_3_29,2),
    normality_judgment = normality_judgment,
    central_tendency = central_tendency
  ))
}

# Function to execute t-tests
conduct_t_test <- function(ratiovar, nomvar, data) {
  # Extract the ratio and group variables
  rvar <- data[[ratiovar]]
  grpvar <- data[[nomvar]]
  
  # Get descriptive statistics by group - output as a matrix
  descriptives <- psych::describeBy(rvar, grpvar, mat = TRUE)  # Fixed variable reference
  print(descriptives)
  
  # Conduct Levene's test for homogeneity of variance
  levene <- car::leveneTest(rvar ~ as.factor(grpvar), data = data)
  p_value <- levene[["Pr(>F)"]][1]  # Access p-value from Levene's test result
  
  # Run the t-test based on the homogeneity of variance assumption
  if (p_value > 0.05) {  # Use 0.05 for the common significance level
    res <- stats::t.test(rvar ~ as.factor(grpvar), var.equal = TRUE, data = data)
  } else {
    res <- stats::t.test(rvar ~ as.factor(grpvar), var.equal = FALSE, data = data)
  }
  
  # Cohen's d using effectsize package
  effectcohen <- effectsize::t_to_d(t = res$statistic, df_error = res$parameter)
  
  # Calculate eta squared
  effecteta <- round((res$statistic^2) / ((res$statistic^2) + res$parameter), 3)
  
  # Return a list of results
  return(list(
    descriptives = descriptives,
    t = res$statistic,
    tdf = res$parameter,
    tpvalue = res$p.value,
    cohen_d = effectcohen,
    eta_squared = effecteta
  ))
}

