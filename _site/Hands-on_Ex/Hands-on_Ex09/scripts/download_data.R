# Run from the exercise folder: Rscript scripts/download_data.R
# Retrieve the professor's original teaching files at an immutable commit.
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The digest package is required to verify the downloaded Git blobs.")
}
revision <- "acaa1f9995d3d778a02a09c6bbdd5ef4f4eae773"
base_url <- paste0("https://raw.githubusercontent.com/tskam/IS415/", revision,
                   "/Hands-on_Ex/Hands-on_Ex09/data/")
files <- c(
  "aspatial/Condo_resale_2015.csv" = "97be7d012906f1691bbba476533a6f14c36d8ef4",
  "geospatial/MP14_SUBZONE_WEB_PL.shp" = "93b82c5d54935bb00abb81c25327c443e348b4ff",
  "geospatial/MP14_SUBZONE_WEB_PL.shx" = "a87ae19fcb35006e4a69e1ba4486966fad4871da",
  "geospatial/MP14_SUBZONE_WEB_PL.dbf" = "ebaed6594a501171aca80dce88415ebf4e578437",
  "geospatial/MP14_SUBZONE_WEB_PL.prj" = "b848068d2e9a4320ae8a549c31a43cc2672d2eb1"
)
git_blob_hash <- function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  prefix <- c(charToRaw(paste0("blob ", length(bytes))), as.raw(0))
  digest::digest(c(prefix, bytes), algo = "sha1", serialize = FALSE)
}
for (name in names(files)) {
  destination <- file.path("data", name)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(destination)) {
    if (git_blob_hash(destination) != files[[name]]) {
      stop("Existing input differs from the pinned course file: ", destination)
    }
    next
  }
  temporary <- tempfile()
  download.file(paste0(base_url, name), temporary, mode = "wb", quiet = TRUE)
  if (git_blob_hash(temporary) != files[[name]]) {
    stop("Downloaded file failed its source fingerprint check: ", name)
  }
  if (!file.copy(temporary, destination)) stop("Could not save ", destination)
  unlink(temporary)
}
cat("Verified", length(files), "original course files at", revision, "\n")
