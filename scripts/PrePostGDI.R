# Boxplot pre e post GDI

library(ggplot2)
setwd("/path/to/LQV")
# Carica il file dei dati
data <- read.table("Sample_LQV.ALL_preGDI_postGDI.txt", header = TRUE)
p <- ggplot(data, aes(x = factor(1), y = LQV_preGDI, group = factor(1))) +
geom_boxplot(fill = "gold", color = "black", outlier.shape = NA, position = position_dodge(width = 0.75)) +
 geom_point(aes(color = "Pre-GDI"), position = position_jitter(width = 0.2), alpha = 0.5, size = 2, show.legend = FALSE) +
 geom_boxplot(data = data, aes(x = factor(2), y = LQV_postGDI, group = factor(2)), fill = "gold", color = "black", outlier.shape = NA, position = position_dodge(width = 0.75)) +
 geom_point(data = data, aes(x = factor(2), y = LQV_postGDI, color = "Post-GDI"), position = position_jitter(width = 0.2), alpha = 0.5, size = 2, show.legend = FALSE) +
 labs(x = "", y = "Proportion of low-quality variants (LQV)") +
 scale_color_manual(values = c("Pre-GDI" = "deepskyblue2", "Post-GDI" = "deepskyblue2")) +
 scale_x_discrete(breaks = c("1", "2"), labels = c("Pre-GDI", "Post-GDI")) +
 theme_bw() +
theme(axis.text.x = element_text(angle = 0, vjust = 0.5), axis.ticks.x = element_blank())
print(p)
