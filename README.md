# ACS Data Cleaning

This project turns raw ACS CSV files into cleaned CSV files with the correct header/template. It also fixes common row shifts and writes log files so you can see what was changed.

The raw ACS files do not have headers. You provide:

- a raw data file, for example `raw/acs-nmcb-2.csv`
- a matching header/template file, for example `header/nmcb-acs-header-2.csv`

The script writes a cleaned file to `export/`.

## Quick Start

Open Terminal in this project folder and run:

```bash
Rscript process_acs.R
```

This processes the standard folder setup:

- `raw/acs-nmcb-1.csv` uses `header/nmcb-acs-header-1.csv`
- `raw/acs-nmcb-2.csv` uses `header/nmcb-acs-header-2.csv`
- and so on through file 6

Cleaned files are written to `export/`.

## Process One File

Use this when you only want to clean one raw file with one template:

```bash
Rscript process_acs.R --raw raw/acs-nmcb-2.csv --header header/nmcb-acs-header-2.csv --out export/acs-nmcb-2.csv
```

Replace the three file paths after `--raw`, `--header`, and `--out` with your own files.

## Folder Layout

- `raw/` contains raw ACS CSV files without headers.
- `header/` contains one-row header/template CSV files.
- `export/` contains cleaned output files.
- `R/acs_cleaning.R` contains the reusable cleaning functions.
- `process_acs.R` is the simple script most users should run.

## Output Files

After running the script, check `export/`:

- `acs-nmcb-*.csv`: cleaned data files with headers.
- `deleted_cells_log.csv`: records values removed during checkpoint correction.
- `generalized_rule_misalignment_log.csv`: records remaining possible alignment warnings.

For one-file processing, the logs are named after the output file, for example:

- `acs-nmcb-2_deleted_cells_log.csv`
- `acs-nmcb-2_generalized_rule_misalignment_log.csv`

## What The Cleaning Does

The script:

1. Reads the header/template row.
2. Reads each raw data row.
3. Expands packed questionnaire values like `1|Question text|0` into separate columns.
4. Places values under the correct template columns.
5. Uses checkpoint words such as `message`, `video`, `questionnaire`, and `mousetype` to detect and correct shifts.
6. Writes a cleaned CSV and log files.

## Important Naming Rule For Batch Mode

Batch mode expects this naming pattern:

- raw file: `acs-nmcb-1.csv`
- matching header: `nmcb-acs-header-1.csv`

The number must match. For example, raw file `acs-nmcb-4.csv` will use `nmcb-acs-header-4.csv`.

Extra files such as `acs-nmcb-2 copy.csv` are ignored by the standard batch command.

## Requirements

You need R installed and the R package `data.table`.

If `data.table` is missing, run this once in R:

```r
install.packages("data.table")
```

## For Advanced Users

You can call the reusable functions directly from R:

```r
source("R/acs_cleaning.R")

process_acs_file(
  raw_file = "raw/acs-nmcb-2.csv",
  header_file = "header/nmcb-acs-header-2.csv",
  output_file = "export/acs-nmcb-2.csv"
)
```

Or process the standard folders:

```r
source("R/acs_cleaning.R")
process_acs_batch(raw_dir = "raw", header_dir = "header", export_dir = "export")
```
