#!/usr/bin/env Rscript

source(file.path("R", "acs_cleaning.R"))

usage <- function() {
  cat(
    "ACS data cleaning\n",
    "\n",
    "Run the standard folder workflow:\n",
    "  Rscript process_acs.R\n",
    "\n",
    "Run one raw file with one header template:\n",
    "  Rscript process_acs.R --raw raw/acs-nmcb-2.csv --header header/nmcb-acs-header-2.csv --out export/acs-nmcb-2.csv\n",
    "\n",
    "Optional folder settings for the standard workflow:\n",
    "  Rscript process_acs.R --raw-dir raw --header-dir header --export-dir export\n",
    "\n",
    "Options:\n",
    "  --raw          Raw ACS CSV file without headers\n",
    "  --header       Header/template CSV file with one header row\n",
    "  --out          Cleaned output CSV file\n",
    "  --raw-dir      Folder containing raw files; default: raw\n",
    "  --header-dir   Folder containing header templates; default: header\n",
    "  --export-dir   Folder for cleaned outputs; default: export\n",
    "  --help         Show this help message\n",
    sep = ""
  )
}

parse_args <- function(args) {
  opts <- list()
  i <- 1

  while (i <= length(args)) {
    key <- args[[i]]

    if (key == "--help") {
      opts$help <- TRUE
      i <- i + 1
      next
    }

    if (!startsWith(key, "--")) {
      stop("Unexpected argument: ", key)
    }

    if (i == length(args) || startsWith(args[[i + 1]], "--")) {
      stop("Missing value for option: ", key)
    }

    opts[[substring(key, 3)]] <- args[[i + 1]]
    i <- i + 2
  }

  opts
}

args <- commandArgs(trailingOnly = TRUE)
opts <- parse_args(args)

if (isTRUE(opts$help)) {
  usage()
  quit(status = 0)
}

has_single_file_args <- all(c("raw", "header", "out") %in% names(opts))
has_some_single_file_args <- any(c("raw", "header", "out") %in% names(opts))

if (has_some_single_file_args && !has_single_file_args) {
  stop("For one-file processing, please provide all three options: --raw, --header, and --out")
}

if (has_single_file_args) {
  result <- process_acs_file(
    raw_file = opts$raw,
    header_file = opts$header,
    output_file = opts$out
  )

  output_dir <- dirname(opts$out)
  deleted_log_path <- file.path(output_dir, paste0(tools::file_path_sans_ext(basename(opts$out)), "_deleted_cells_log.csv"))
  misalignment_log_path <- file.path(output_dir, paste0(tools::file_path_sans_ext(basename(opts$out)), "_generalized_rule_misalignment_log.csv"))

  fwrite(result$delete_log, deleted_log_path, quote = TRUE, na = "")
  fwrite(result$generalized_misalignment_log, misalignment_log_path, quote = TRUE, na = "")

  cat("Cleaned file written to:", opts$out, "\n")
  cat("Deleted-cell log written to:", deleted_log_path, "\n")
  cat("Misalignment log written to:", misalignment_log_path, "\n")
  print(result$summary)
} else {
  raw_dir <- if (!is.null(opts[["raw-dir"]])) opts[["raw-dir"]] else "raw"
  header_dir <- if (!is.null(opts[["header-dir"]])) opts[["header-dir"]] else "header"
  export_dir <- if (!is.null(opts[["export-dir"]])) opts[["export-dir"]] else "export"

  result <- process_acs_batch(
    raw_dir = raw_dir,
    header_dir = header_dir,
    export_dir = export_dir
  )

  cat("Cleaned files written to:", export_dir, "\n")
  cat("Deleted-cell log written to:", result$deleted_log_path, "\n")
  cat("Misalignment log written to:", result$generalized_misalignment_log_path, "\n")
  print(result$summary)
}
