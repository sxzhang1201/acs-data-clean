# Zenodo DOI Setup

Use Zenodo if the project needs a citable DOI for a released version.

Recommended steps:

1. Log in to Zenodo with a GitHub account that has access to `nmcb-fair/acs-data-clean`.
2. In Zenodo, enable GitHub integration for this repository.
3. Create a GitHub release, for example `v0.1.0`.
4. Zenodo will archive the release and mint a DOI.
5. Add the DOI badge or DOI link to `README.md` and update `CITATION.cff` if needed.

Do not archive real participant data. Releases should include code, documentation, templates, and synthetic examples only.
