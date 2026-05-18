# Release Notes

## v0.1.0 - First Reusable ACS Cleaning Release

This is the first reusable release of the ACS data cleaning tool developed for the NMCB-FAIR project.

### Included

- Reusable R cleaning functions in `R/acs_cleaning.R`.
- User-facing command-line script `process_acs.R`.
- Batch processing for matched raw/header folders.
- One-file processing with `--raw`, `--header`, and optional `--out`.
- Dated export folders, for example `export/20260518/`.
- Optional `O_token` prefix filtering; default is `nmcb`.
- Deleted-cell and generalized misalignment logs.
- Synthetic example files.
- Documentation for citation, contributing, maintainers, and issue reporting.

### Privacy

Do not upload real ACS participant data to GitHub issues, pull requests, commits, screenshots, or logs. Use synthetic examples when reporting problems.
