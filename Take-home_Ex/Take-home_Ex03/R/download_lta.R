# Download one month of authentic LTA train passenger-volume data.
# Run from the Take-home_Ex03 directory after setting LTA_ACCOUNT_KEY.
# Example: Rscript R/download_lta.R 202609
suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
})

month <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(month) || !grepl("^20[0-9]{4}$", month)) {
  stop("Pass one month as YYYYMM, for example 202609.")
}
key <- Sys.getenv("LTA_ACCOUNT_KEY", "")
if (!nzchar(key)) stop("Set LTA_ACCOUNT_KEY in your environment; do not save it in this project.")
dir.create("data/private", recursive = TRUE, showWarnings = FALSE)

download_lta <- function(endpoint, filename) {
  api <- paste0("https://datamall2.mytransport.sg/ltaodataservice/PV/",
                endpoint, "?Date=", month)
  response <- httr::GET(api, httr::add_headers(AccountKey = key), httr::timeout(45))
  httr::stop_for_status(response)
  body <- httr::content(response, as = "parsed", type = "application/json")
  if (length(body$value) != 1L || !nzchar(body$value[[1]]$Link)) {
    stop("LTA did not return one download link for ", endpoint, ".")
  }
  path <- file.path("data/private", filename)
  file_response <- httr::GET(body$value[[1]]$Link,
                             httr::write_disk(path, overwrite = TRUE),
                             httr::timeout(180))
  httr::stop_for_status(file_response)
  if (!length(unzip(path, list = TRUE)$Name)) stop("Downloaded file is not a ZIP: ", filename)
  cat("Saved", filename, "in ignored data/private/.\n")
  invisible(path)
}

download_lta("ODTrain", paste0("origin_destination_train_", month, ".zip"))
download_lta("Train", paste0("transport_node_train_", month, ".zip"))
