# GitHub Upload Checklist

Before making the repository public, please check the following items.

## File names

- [ ] `NIST_FinalRD_Hayashi_alpha50.bin` has been renamed to `NIST_FinalRD_ModifiedToeplitz_alpha50.bin`.
- [ ] `NIST_FinalRD_Hayashi_alpha80.bin` has been renamed to `NIST_FinalRD_ModifiedToeplitz_alpha80.bin`.
- [ ] The corresponding NIST reports use `ModifiedToeplitz` in the public file names.

## Required folders

- [ ] `scripts/`
- [ ] `runtime_data/`
- [ ] `nist_inputs/`
- [ ] `nist_reports/`
- [ ] `figures/`

## Root-level documentation

- [ ] `README.md`
- [ ] `data_manifest.csv`
- [ ] `NIST_STS_notes.md`
- [ ] `DATA_AVAILABILITY_STATEMENT.md`
- [ ] `.gitignore`
- [ ] `LICENSE_TO_BE_CONFIRMED.txt` or an author-approved license file

## Data and code policy

- [ ] Confirm whether the authors want to use MIT, BSD, GPL, or no explicit open-source license.
- [ ] Do not upload large third-party raw files unless the authors confirm redistribution is allowed.
- [ ] Confirm that the repository does not include private paths, usernames, or local system-specific files.

## Zenodo DOI

- [ ] If a Zenodo DOI is generated, update the DOI in `README.md`.
- [ ] If a Zenodo DOI is generated, update the manuscript Data Availability Statement.
