# Load necessary libraries
library(tidyverse)
library(stringi)







# Example usage:
# Define input file and output directory
input_path <- "C:/Users/TJ McMote/ASU Dropbox/Rudolf Cesaretti/GitHubRepos/TMP-database/data/raw/DF10_Sherfield_csv/archToSSN.csv"
output_dir <- "C:/Users/TJ McMote/ASU Dropbox/Rudolf Cesaretti/GitHubRepos/TMP-database/data/raw/DF10"



# Define a function to process the CSV
#process_csv <- function(input_path, output_dir) {
  # Extract the file name without path
  file_name <- basename(input_path)

  # Read the CSV file with Latin-1 encoding
  data <- read_csv(input_path, locale = locale(encoding = "ISO-8859-1"))
  
  ##  CUSTOM 1
  colnames(data) <- c("ArchPolyID", "SSN", "Area_SSN_Coverage")
  data <- data %>% 
    mutate(ArchPolyID = as.integer(ArchPolyID), SSN = as.integer(SSN), Area_SSN_Coverage = as.double(Area_SSN_Coverage))
  ##  CUSTOM 1
  data <- data %>% mutate(code = as.integer(code)) %>% rename(Code = code, Description = description)
  
  ##  CUSTOM 1
  data <- data %>% rename(SSN = ID, Site = site, Subsite = subsite, Unit = unit, Northing = northing, Easting = easting)%>% 
  mutate(SSN = as.integer(SSN))
  
  ##  CUSTOM 2
  data <- data %>% mutate(ID = as.integer(ID), Count = as.integer(Count), Where = ifelse(Where == "M", "Missing", Where)) %>% 
    rename(SSN = ID)
  
  ##  CUSTOM 3
  data <- data %>% mutate(ID = as.integer(ID), 
                          Count = as.integer(Count), 
                          ArtCode1 = as.integer(ArtCode1), 
                          ArtCode2 = as.integer(ArtCode2), 
                          ArtCode3 = as.integer(ArtCode3), 
                          Where = ifelse(Where == "M", "Missing", Where)) %>% 
    rename(SSN = ID)
  
  # Normalize special Latin characters to standard English equivalents
  data <- data %>%
    mutate(across(where(is.character), ~ stri_trans_general(., "Latin-ASCII")))
  
  # Define the output path
  output_path <- file.path(output_dir, file_name)
  
  # Save the modified data as a UTF-8 encoded CSV
  write_csv(data, output_path)
  
  # Return the output path for verification
  #return(output_path)
#}

# Example usage:
# Define input file and output directory
#input_file <- "path/to/your/input.csv"
#output_directory <- "path/to/output/directory"

# Call the function
#output_file <- process_csv(input_file, output_directory)
#cat("Processed file saved at:", output_file, "\n")
#artifactCodes <- artifactCodes %>% rename(Description = Meaning)
#write_csv(artifactCodes, output_path)
  
archToSSN_2 <- archToSSN %>% 
  rowwise() %>%
  mutate(
    NewID = paste0(ArchPolyID, "_", SSN)
  )

length(unique(archToSSN_2$NewID))
length(unique(archToSSN_2$ArchPolyID))

archToSSN_2 <- archToSSN_2 %>%
  group_by(NewID) %>%
  mutate(Unique = n() == 1) %>%
  ungroup()
