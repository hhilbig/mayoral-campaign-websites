"""Data for the mayoral social-media figures (scripts/mayoral_social_figures.R), from the release folder.

coverage_by_year_role.csv     share of eligible finalists with usable text, by election year and result role
page_types_by_period.csv      share of finalists with text that have at least one usable page of each page type
                              (page_type in the corpus), by four-year period of the election
status_by_year.csv            eligible finalists by election year and text status (four groups; site_not_archived,
                              no_usable_pages and excluded_site_check form 'Website found, no usable text')
coverage_by_city.csv          eligible finalists and share with usable text, by city
coverage_by_size.csv          share of eligible finalists with usable text, by 2020 population rank group of the city
elections_by_period.csv       share of elections with usable text for both, one or neither finalist, by period

Usage: python scripts/mayoral_social_figure_data.py [release_dir]
"""
from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

RELEASE = Path(sys.argv[1] if len(sys.argv) > 1 else "build/mayoral_release_v6_candidate")
OUT = Path("quality_reports/social_figure_candidates/mayoral/data")
PAGE_TYPES = {"issues": "Issues", "biography": "Biography", "endorsements": "Endorsements", "action": "Donate or volunteer", "news": "News"}
STATUS = {"text": "Website text", "no_url_lead": "No website found", "site_rejected": "No website found",
          "check_incomplete": "Search incomplete"}
SIZES = ([0, 10, 25, 50, 75, 100], ["1–10", "11–25", "26–50", "51–75", "76–100"])
ELECTION_PERIODS = ([2009, 2013, 2017, 2021, 2026], ["2010–13", "2014–17", "2018–21", "2022–26"])
PERIODS = ([2009, 2013, 2017, 2021, 2025], ["2010–13", "2014–17", "2018–21", "2022–25"])


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    finalists = pd.read_csv(RELEASE / "mayoral_finalists.csv", dtype=str)
    finalists = finalists[finalists["eligible"] == "True"].assign(text=lambda d: d["text_status"] == "text")
    coverage = finalists.groupby(["year", "official_result_role"])["text"].mean().mul(100).reset_index(name="share")
    coverage.to_csv(OUT / "coverage_by_year_role.csv", index=False)
    status = finalists["text_status"].map(STATUS).fillna("Website found, no usable text")
    finalists.assign(status=status).groupby(["year", "status"]).size().rename("n").reset_index() \
        .to_csv(OUT / "status_by_year.csv", index=False)
    cities = pd.read_csv(RELEASE / "mayoral_cities.csv", dtype=str)[["city_id", "city_name", "state_abb", "population_rank_2020"]]
    by_city = finalists.groupby("city_id")["text"].agg(n="size", share="mean").reset_index()
    by_city["share"] *= 100
    cities.merge(by_city, on="city_id", how="left").to_csv(OUT / "coverage_by_city.csv", index=False)
    rank = finalists["city_id"].map(cities.set_index("city_id")["population_rank_2020"].astype(int))
    size = pd.cut(rank, SIZES[0], labels=SIZES[1])
    finalists.groupby(size, observed=True)["text"].agg(share="mean", n="size").mul([100, 1]).reset_index(names="rank_group") \
        .to_csv(OUT / "coverage_by_size.csv", index=False)
    elections = finalists.groupby("election_id").agg(year=("year", "first"), with_text=("text", "sum"), n=("text", "size"))
    assert (elections["n"] == 2).all(), "every election must have two eligible finalists"
    elections["group"] = elections["with_text"].map({2: "Both finalists", 1: "One finalist", 0: "Neither finalist"})
    elections["period"] = pd.cut(elections["year"].astype(int), ELECTION_PERIODS[0], labels=ELECTION_PERIODS[1])
    by_period = elections.groupby(["period", "group"], observed=True).size().rename("n").reset_index()
    by_period["share"] = 100 * by_period["n"] / by_period.groupby("period", observed=True)["n"].transform("sum")
    by_period.to_csv(OUT / "elections_by_period.csv", index=False)

    panel = pd.read_csv(RELEASE / "mayoral_finalist_panel.csv", usecols=["candidate_election_id", "year"])
    pages = pd.read_parquet(RELEASE / "mayoral_page_corpus.parquet",
                            columns=["candidate_election_id", "page_type", "release_usable"])
    has = (pages[pages["release_usable"]].groupby(["candidate_election_id", "page_type"]).size().unstack(fill_value=0) > 0)
    panel = panel.merge(has[list(PAGE_TYPES)], left_on="candidate_election_id", right_index=True, how="left").fillna(False)
    panel["period"] = pd.cut(panel["year"], PERIODS[0], labels=PERIODS[1])
    panel = panel.dropna(subset=["period"])
    shares = panel.groupby("period", observed=True)[list(PAGE_TYPES)].mean().mul(100).reset_index()
    shares = shares.melt(id_vars="period", var_name="page_type", value_name="share")
    shares["label"] = shares["page_type"].map(PAGE_TYPES)
    sizes = panel.groupby("period", observed=True).size().rename("n").reset_index()
    shares.merge(sizes, on="period").to_csv(OUT / "page_types_by_period.csv", index=False)

if __name__ == "__main__":
    main()
