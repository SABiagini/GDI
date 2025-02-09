# Load required library
library(ggplot2)

# Load the data from the file "count.remove.group"
dati <- read.table("count.remove.group")

# Count the number of samples (the second column represents the samples)
n_samples <- max(dati$V2)

# Define the percentage threshold for cutoff (20% in this case)
perc <- 20

# Calculate the cutoff value based on the percentage of samples
cutoff <- (perc * n_samples) / 100

# Calculate the sum of variants that exceed the cutoff threshold
somma_sopra_soglia <- sum(dati$V1[dati$V2 > cutoff])

# Create the scatter plot using ggplot2
plot <- ggplot(data = dati, aes(x = V2, y = V1)) +
  # Add points to the plot with color based on whether the sample count exceeds the cutoff
  geom_point(aes(colour = V2 > cutoff), size = 1.5, alpha = 0.6) +
  
  # Set custom colors for points based on the threshold
  scale_colour_manual(values = c("#FDE725FF", "maroon")) +
  
  # Apply a clean white background theme
  theme_bw() +
  
  # Remove grid lines for a cleaner look
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  
  # Add labels to the axes and title to the plot
  xlab("Samples") +
  ylab("Number of variants") +
  ggtitle(paste("Variants to remove: ", somma_sopra_soglia)) +
  
  # Add a label showing the cutoff percentage on the plot
  annotate("text", x = cutoff, y = 600, label = paste0("cutoff=", perc, "%"), vjust = -1, hjust = -0.5, color = "black") +
  
  # Add a vertical line at the cutoff value
  annotate("segment", x = cutoff, xend = cutoff, y = 0, yend = max(dati$V1), colour = "black", size = 1) +
  
  # Add a label at the top indicating the cutoff line
  annotate("text", x = cutoff, y = 1.1 * max(dati$V1), label = "Cutoff", hjust = -0.1, colour = "black", size = 4) +
  
  # Set the limits for the x and y axes for a cleaner plot
  scale_x_continuous(limits = c(0, max(dati$V2)), expand = c(0,0)) +
  scale_y_continuous(limits = c(0, max(dati$V1)), expand = c(0,0)) +
  
  # Set grid lines for the y-axis and remove the legend
  theme(panel.grid.major = element_line(color = "gray", linetype = "dashed"), legend.position = "none")

# Print the plot
plot
