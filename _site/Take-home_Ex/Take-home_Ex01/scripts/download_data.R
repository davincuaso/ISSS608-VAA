analysis_root <- if (file.exists(file.path("scripts", "download_data.R"))) {
  "."
} else {
  file.path("Take-home_Ex", "Take-home_Ex01")
}

raw_dir <- file.path(analysis_root, "data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

accident_zip <- file.path(raw_dir, "thailand-road-accident-2019-2022.zip")
accident_csv <- file.path(raw_dir, "thai_road_accident_2019_2022.csv")
boundary_file <- file.path(raw_dir, "geoBoundaries-THA-ADM1.geojson")

if (!file.exists(accident_csv)) {
  download.file(
    "https://www.kaggle.com/api/v1/datasets/download/thaweewatboy/thailand-road-accident-2019-2022",
    accident_zip,
    mode = "wb",
    quiet = FALSE
  )
  unzip(accident_zip, exdir = raw_dir)
}

if (!file.exists(boundary_file)) {
  download.file(
    paste0(
      "https://github.com/wmgeolab/geoBoundaries/raw/9469f09/",
      "releaseData/gbOpen/THA/ADM1/geoBoundaries-THA-ADM1.geojson"
    ),
    boundary_file,
    mode = "wb",
    quiet = FALSE
  )
}

required_files <- c(accident_csv, boundary_file)
if (!all(file.exists(required_files))) {
  stop("One or more core data files could not be downloaded.")
}
