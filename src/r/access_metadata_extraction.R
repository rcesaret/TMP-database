
# -------------------------------------------------------------------
# File Name: access_metadata_extraction.R
# -------------------------------------------------------------------
# Description:
#   This file demonstrates how to connect to a Microsoft Access .accdb
#   database using DBI + odbc, retrieve tables, then for each table
#   retrieve metadata (column names + data type info), and finally
#   write the metadata to CSV.
#
# Dependencies:
#   - DBI
#   - odbc
#   - dplyr
#   - readr
#
# Author: Your Name
# -------------------------------------------------------------------

# ---------------------- #
#      Load Packages     #
# ---------------------- #
library(DBI)
library(odbc)
library(dplyr)
library(readr)

# -------------------------------------------------------------------
# Function: connect_to_access
#   Creates and returns a DBI connection to an Access .accdb file 
#   using the CData ODBC driver.
#
# Args:
#   access_file: Full file path to the .accdb file
#
# Returns:
#   A DBI connection object
# -------------------------------------------------------------------
connect_to_access <- function(access_file) {
  con <- dbConnect(
    odbc::odbc(),
    .connection_string = paste0(
      "DRIVER={CData ODBC Driver for Microsoft Access};",
      "DataSource=", access_file, ";"
    )
  )
  
  return(con)
}

# -------------------------------------------------------------------
# Function: get_tables
#   Retrieves the list of tables from the Access DB connection.
#
# Args:
#   con: A DBI connection object
#
# Returns:
#   A character vector of table names
# -------------------------------------------------------------------
get_tables <- function(con) {
  tables <- dbListTables(con)
  return(tables)
}

# -------------------------------------------------------------------
# Function: get_columns_info
#   Retrieves metadata (column names, data types) for all columns
#   of a single table from the Access DB.
#
# Args:
#   con: A DBI connection object
#   table_name: Name of the table whose columns are retrieved
#
# Returns:
#   A data frame containing the table name, column names, and data types
# -------------------------------------------------------------------
get_columns_info <- function(con, table_name) {
  # Send a "no rows" query just to get the column info
  query_string <- paste0("SELECT * FROM [", table_name, "] WHERE 1=0")
  res <- dbSendQuery(con, query_string)
  
  # dbColumnInfo() gives us name and type
  columns_info <- dbColumnInfo(res)
  dbClearResult(res)
  
  # Format the metadata in a tidy data frame
  df_columns <- data.frame(
    TABLE_NAME  = table_name,
    COLUMN_NAME = columns_info$name,
    DATA_TYPE   = columns_info$type,
    stringsAsFactors = FALSE
  )
  
  return(df_columns)
}

# -------------------------------------------------------------------
# Function: collect_access_metadata
#   Combines get_tables() and get_columns_info() to gather schema
#   info for all tables in the Access DB, then bind them into one
#   consolidated data frame.
#
# Args:
#   con: A DBI connection object
#
# Returns:
#   A data frame with table name, column name, and data type info
# -------------------------------------------------------------------
collect_access_metadata <- function(con) {
  all_tables <- get_tables(con)
  
  # Loop over each table, get its columns, and store results
  table_info_list <- lapply(all_tables, function(tbl) {
    get_columns_info(con, tbl)
  })
  
  # Combine all data frames
  df_metadata <- bind_rows(table_info_list)
  return(df_metadata)
}

# -------------------------------------------------------------------
# Main execution block:
#   1. Connect to Access DB
#   2. Collect table/column metadata
#   3. Write to CSV
#   4. Disconnect
# -------------------------------------------------------------------
ACCESS_FILE <- file.path(
  "C:", "Projects", "crewai_access_to_postgresql",
  "access_files", "DF10_MES.accdb"
)

# 1. Connect to Access
con <- connect_to_access(ACCESS_FILE)

# 2. Collect metadata for all tables
df9_glc_tabs_vars <- collect_access_metadata(con)

# 3. Export to CSV
output_csv <- "C:/Projects/DF10_GLC_columns.csv"
write_csv(df9_glc_tabs_vars, output_csv)

# 4. Disconnect
dbDisconnect(con)
