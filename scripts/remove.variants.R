library(data.table)

# read in data with fread
# The input is a 2 column file (IDs\tINFO_SCOREs)
dt <- fread("IDs.InfoScores")

# Add column names
colnames(dt)<-c("identifiers","values")

# set threshold
threshold <- 0.4

# group by identifier and check for outliers
dt_outliers <- dt[, .(NumBelowThreshold = sum(values <= threshold)), by = identifiers][NumBelowThreshold > 0, .(identifiers, NumBelowThreshold)]

# write outliers to text file
fwrite(dt_outliers, "IDs2remove.txt", sep = "\t")
