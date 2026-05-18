# Contributing

Thank you for helping improve this ACS cleaning tool.

## Before You Start

- Open an issue before making large changes.
- Use synthetic or anonymized example data only.
- Do not upload real ACS participant data to GitHub issues, pull requests, commits, screenshots, or logs.

## Reporting Problems

When opening a bug report, include:

- The command you ran.
- Your operating system and R version.
- The error message or log file.
- A small synthetic raw CSV and header CSV that reproduce the issue.

Do not include real participant tokens, dates, answers, or other sensitive data.

## Changing Code

If you want to modify the code:

1. Fork the repository or create a branch if you have write access.
2. Make the smallest change that solves the issue.
3. Test with synthetic data or the example files in `examples/`.
4. Open a pull request and explain what changed.

## Pull Request Checklist

- The code runs with `Rscript process_acs.R --token-prefix all --raw examples/raw/acs-nmcb-1.csv --header examples/header/nmcb-acs-header-1.csv --out examples/expected/acs-nmcb-1.csv`.
- The README is updated if user behavior changes.
- No real participant data is included.
