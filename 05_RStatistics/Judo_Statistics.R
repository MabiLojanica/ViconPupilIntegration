##########################################################################
# Judo Head Orientation statistics
##########################################################################

# Load packages and setup workspace ---------------------------------------
rm(list=ls()) # Clears environment variables
cat("\014")  # Clears console commands

# Getting the path of your current open file
current_path = rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
setwd('..') # Moves up one folder to the repository folder 
getwd() # getwd() should be the repository folder '.\ViconPupilIntegration'

# Require the package to load Matlab files if not already installed
if(!require(R.matlab)){
  install.packages("R.matlab"); require(R.matlab)} #load / install+load 


# Import Data -------------------------------------------------------------
# Read the file
data <- readMat('05_RStatistics/AllTrials.mat')

# Access the variable in the file
AllTrials <- data$exportAllData

# The 'AllTrials' data has 100 rows. These represent the relative time from
# the start of the trial (AllTrials[1,]) to the end of the trial 
# (AllTrials[100,]). The row number is equal to the percentage of time that
# has passed between trial start and trial end - long trials got squeezed 
# more than short trials.
# Each Column represents one trial. The first 20 columns belong to 
# participant 1, etc...


# Calculations ------------------------------------------------------------
# I set na.rm=TRUE since there are missing values in the data. This is not wise though!


# Calculate the mean at trial onset 
mean(AllTrials[1,], na.rm = TRUE)

# Calculate the mean at trial end
mean(AllTrials[100,], na.rm = TRUE)

# Histogram of all values ever
hist(AllTrials)
