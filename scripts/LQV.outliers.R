# Set the working directory
setwd("/path/to/LQV/files")

# Load the ggplot2 library for plotting
library(ggplot2)

# Read the LQV file into a dataframe
filename <- "Sample_LQV.ALL.4.0.99.txt" # Example for batch ALL (all LQV files merged into one)
data <- read.table(filename)

# Extract the batch number from the filename
num <- sub("Sample_badness\\.(\\d+)\\..*", "\\1", filename)

# Calculate the cutoff threshold for identifying outliers (1.5 * IQR above the 75th percentile)
cutoff <- quantile(data$V4, 0.75) + IQR(data$V4) * 1.5

# Save the plot as an SVG file
svg(paste("LQVariants.batch", num, ".svg", sep=""))

# Create a boxplot with jittered points to visualize the distribution of low-quality variants
p <- ggplot(data, aes(x = "", y = V4, fill = factor(V4 > cutoff))) +
  geom_boxplot(fill = "gold", color = "black", outlier.shape = NA) +  # Boxplot without outliers
  geom_point(position = position_jitterdodge(dodge.width = 0.75, jitter.width = 0.2), alpha = 0.5, size = 2, aes(color = factor(V4 > cutoff))) +  # Add jittered points
  scale_color_manual(values = c("#1F77B4", "deeppink")) +  # Color points based on cutoff threshold
  labs(x = "", y = "Proportion of low-quality sites") +  # Labeling axes
  ggtitle(paste("Sample distribution for batch", num)) +  # Add title with batch number
  theme_bw() +  # Apply a clean theme
  theme(legend.position = "none")  # Remove the legend

# Calculate the number of samples to discard based on the cutoff (outliers)
n_campioni_da_scartare <- sum(data$V4 > cutoff)

# Add text to the plot showing the number of outliers
p + geom_text(aes(x = 1.4, y = 0.47, label = paste("outliers=", n_campioni_da_scartare, sep="")))

# Close the plot device (saves the plot to file)
dev.off()

# Extract the indices of the outlier samples
who <- which(data$V4 > cutoff)

# Extract the names of the outlier samples
names <- data$V1[who]

# Calculate the mean of the distribution of V4
mean <- mean(data$V4)

# Extract the indices of the samples with V4 > cutoff
t <- which(data$V4 > cutoff)

# Extract the names of the samples that meet the custom threshold
names2 <- data$V1[t]

# Write the names of the samples to be removed to a file
write.table(names2, paste("remove_batch", num, sep=""), quote = F, row.names = F, col.names = F)

