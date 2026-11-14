# Archived campaign websites of U.S. mayoral candidates

This repository contains the code used to build the dataset "Archived Campaign Websites of U.S. Mayoral Candidates" (Hanno Hilbig). The dataset covers the winners and runners-up of mayoral elections in the 100 largest U.S. cities from January 2010 to September 2026, plus the top two candidates of decisive partisan primaries. All pages come from the Internet Archive's Wayback Machine.

The data are on Harvard Dataverse: https://doi.org/10.7910/DVN/IN9WCA

Download the data from Dataverse. This repository does not include the data, the archived pages, or the intermediate files from collection, so most scripts will not run on their own. The code is published so that readers can see how candidates, websites and pages were selected.

## Contents

- `docs/mayoral_release/README.md` and `docs/mayoral_release/CODEBOOK.md`: the documentation published with the data (population, text rules, coverage, variables, limitations).
- `scripts/`: the collection and build pipeline. In rough order, it finds election results and candidates, finds campaign website addresses, downloads archived pages from the Wayback Machine, checks pages with language models, and builds the release. `build_mayoral_release.py` and `validate_mayoral_release.py` build and check the released files.
- `scripts/workflows_*.js`: the instructions given to AI agents that searched for campaign website addresses. Paths and machine names in these files refer to the original setup.
- `scripts/hive/`: the language-model classification jobs (open-weight model run on a university GPU cluster).
- `src/`: shared functions.
- `config/`: build inputs and source lists.
- `tests/`: unit tests. Tests that read the collected data are not included.

## Setup

```
python3 -m venv .venv
.venv/bin/pip install -r requirements-lock.txt
.venv/bin/python -m pytest -q
```

## Terms of use

The code in this repository is MIT licensed (see `LICENSE`). The dataset and its documentation are released under CC BY 4.0. Copyright in the campaign material remains with its authors. To request removal of material you hold rights to, email hhilbig@ucdavis.edu.

Please cite the dataset as shown on its Dataverse page.
