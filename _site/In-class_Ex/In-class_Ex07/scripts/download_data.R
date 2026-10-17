# Run from In-class_Ex/In-class_Ex07 before the first render.
mirror_commit <- "316e52d2088516f6fae69eb983757e021d1a2a10"
base_url <- paste0(
  "https://raw.githubusercontent.com/credor/ISSS626-GAA/",
  mirror_commit, "/Hands-on_Ex/Hands-on_Ex01/data/"
)
files <- c(
  "aspatial/OD_Matrix.csv",
  paste0("geospatial/MP14_SUBZONE_NO_SEA_PL.", c("shp", "shx", "dbf", "prj")),
  paste0("geospatial/hexagons.", c("shp", "shx", "dbf", "prj", "cpg")),
  paste0("geospatial/ELDERCARE.", c("shp", "shx", "dbf", "prj", "cpg"))
)
for (file in files) {
  destination <- file.path("data", file)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(destination)) {
    download.file(paste0(base_url, file), destination, mode = "wb")
  }
}
cat("Teaching inputs ready. See data/README.md for provenance.\n")
