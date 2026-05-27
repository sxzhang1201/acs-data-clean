# ACS Data Cleaning

This project turns raw ACS CSV files into cleaned CSV files with the correct header/template. It also fixes common row shifts and writes log files so you can see what was changed.

This tool was originally developed by Shuxin Zhang for the NMCB-FAIR project. The canonical maintained repository is hosted at [https://github.com/nmcb-fair/acs-data-clean](https://github.com/nmcb-fair/acs-data-clean).

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

By default, this project keeps only rows where `O_token` starts with `nmcb`. Test rows such as `marysetest` and `testtoken3` are excluded.

Cleaned files are written to a dated folder inside `export/`, for example `export/20260513/`.

## Process One File

Use this when you only want to clean one raw file with one template:

```bash
Rscript process_acs.R --raw raw/acs-nmcb-2.csv --header header/nmcb-acs-header-2.csv
```

Replace the two file paths after `--raw` and `--header` with your own files. The cleaned file is written to a dated folder such as `export/20260513/`.

If you want to choose an exact output file yourself, add `--out`:

```bash
Rscript process_acs.R --raw raw/acs-nmcb-2.csv --header header/nmcb-acs-header-2.csv --out export/20260513/acs-nmcb-2.csv
```

## Try The Example

The `examples/` folder contains tiny synthetic files that do not include real participant data.

Run:

```bash
Rscript process_acs.R --raw examples/raw/acs-nmcb-1.csv --header examples/header/nmcb-acs-header-1.csv --out examples/expected/example-run.csv
```

The output should contain only the row where `O_token` starts with `nmcb`; the synthetic `testtoken1` row is filtered out by default.

## Token Filtering

For the NMCB data, only participant rows whose `O_token` starts with `nmcb` are kept. This removes test rows.

If you want to keep all rows, for example when using this code for another study, add:

```bash
Rscript process_acs.R --token-prefix all
```

You can also use another prefix:

```bash
Rscript process_acs.R --token-prefix studyabc
```

## Folder Layout

- `raw/` contains raw ACS CSV files without headers.
- `header/` contains one-row header/template CSV files.
- `export/` contains dated output folders, such as `export/20260513/`.
- `R/acs_cleaning.R` contains the reusable cleaning functions.
- `process_acs.R` is the simple script most users should run.

## Output Files

After running the script, check today's folder inside `export/`, for example `export/20260513/`:

- `acs-nmcb-*.csv`: cleaned data files with headers.
- `deleted_cells_log.csv`: records values removed during checkpoint correction.
- `generalized_rule_misalignment_log.csv`: records remaining possible alignment warnings. Missing later tasks are not included, because they usually mean the participant stopped before that part.

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
7. Excludes test rows unless token filtering is disabled.

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

## Releases

For stable reuse, use a GitHub release rather than an arbitrary branch snapshot:

[https://github.com/nmcb-fair/acs-data-clean/releases](https://github.com/nmcb-fair/acs-data-clean/releases)

Recommended version pattern:

- `v0.1.0`: first reusable release.
- `v0.1.1`: bug fix.
- `v0.2.0`: new ACS format or behavior.
- `v1.0.0`: stable interface for broader reuse.

## Citation

If you use this tool, please cite the released version. Citation metadata is provided in `CITATION.cff`.

For academic reuse, the project can also be archived with Zenodo to create a DOI. See `docs/ZENODO.md`.

## Getting Help

Use GitHub Issues for bugs, questions, and feature requests:

[https://github.com/nmcb-fair/acs-data-clean/issues](https://github.com/nmcb-fair/acs-data-clean/issues)

When opening an issue, include:

- the command you ran
- the error message or log file
- a small synthetic example, if possible

Do not upload real participant data.

## Privacy

Do not upload real ACS participant data to GitHub issues, pull requests, commits, screenshots, or logs.

Use synthetic examples instead. Replace participant tokens, dates, answers, and any other sensitive values before sharing.

## Forking And Contributions

You do not need to fork this repository just to clean your own ACS files. Download or clone the repository, put files in `raw/` and `header/`, and run `Rscript process_acs.R`.

Forking is useful if you want to change the code. See `docs/CONTRIBUTING.md` before opening a pull request.

## Authorship And Maintenance

- Original author: Shuxin Zhang.
- Long-term project home: NMCB-FAIR GitHub organization.
- Maintainer guidance is in `docs/MAINTAINERS.md`.
- Author and contributor information is in `docs/AUTHORS.md`.

## Acknowledgements

We thank [Maryse Luijendijk](https://www.nki.nl/research/find-a-researcher/researchers/maryse-luijendijk) ([m.luijendijk@nki.nl](mailto:m.luijendijk@nki.nl)) for reviewing this project.

## License

This project is released under the MIT License. See `LICENSE`.

## For Advanced Users

You can call the reusable functions directly from R:

```r
source("R/acs_cleaning.R")

process_acs_file(
  raw_file = "raw/acs-nmcb-2.csv",
  header_file = "header/nmcb-acs-header-2.csv",
  output_file = "export/20260513/acs-nmcb-2.csv",
  token_prefix = "nmcb"
)
```

Or process the standard folders:

```r
source("R/acs_cleaning.R")
process_acs_batch(raw_dir = "raw", header_dir = "header", export_dir = "export", token_prefix = "nmcb")
```

