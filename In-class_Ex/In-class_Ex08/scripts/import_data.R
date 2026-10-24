# Run from the exercise folder: Rscript scripts/import_data.R /path/to/course/data
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply the course data folder as the only argument.")
source_dir <- normalizePath(args[1], mustWork = TRUE)
layers <- c("STORES_TC", "TOWN_TC", "VILLAGE_TC")
required <- c(unlist(lapply(layers, function(layer) {
  file.path("geospatial", paste0(layer, c(".shp", ".shx", ".dbf", ".prj")))
})), file.path("aspatial", c("pop2019.csv", "Store_sales_data.csv", "storeCD.csv")))
optional <- file.path("geospatial", paste0(layers, ".cpg"))
missing <- required[!file.exists(file.path(source_dir, required))]
if (length(missing)) stop(paste("Missing required inputs:", paste(missing, collapse = ", ")))
files <- c(required, optional[file.exists(file.path(source_dir, optional))])
for (name in files) {
  from <- file.path(source_dir, name)
  to <- file.path("data", name)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(to)) {
    if (unname(tools::md5sum(from)) != unname(tools::md5sum(to))) {
      stop(paste("Existing input differs; review it before replacing:", to))
    }
  } else if (!file.copy(from, to)) stop(paste("Could not copy", name))
}
source_hashes <- unname(tools::md5sum(file.path(source_dir, files)))
copied_hashes <- unname(tools::md5sum(file.path("data", files)))
stopifnot(identical(source_hashes, copied_hashes))
cat("Copied and verified", length(files), "course-file components. Source files unchanged.\n")
