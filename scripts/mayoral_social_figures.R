# Social-media figures for the mayoral release: coverage by year, website page types by period,
# finalists by text status and year, a map of coverage by city, coverage by city size,
# and elections by the number of finalists with text.
# Inputs come from the release (computed in quality_reports/social_figure_candidates/mayoral/data/).
set.seed(20261023)
library(ggplot2)
library(dplyr)
library(readr)
library(maps)
library(sf)

CLARA_BLUE <- "#2f6f9f"
CLARA_DARK <- "#1d4f77"
CLARA_GREY <- "grey55"

theme_clara <- function(base_size = 13) {
  theme_bw(base_size = base_size) +
    theme(
      panel.grid = element_blank(),
      panel.border = element_rect(color = "grey70"),
      axis.ticks = element_blank(),
      legend.position = "none",
      plot.margin = margin(8, 14, 8, 8)
    )
}

save_clara <- function(plot, path_stem, width, height) {
  ggsave(paste0(path_stem, ".pdf"), plot, width = width, height = height, device = cairo_pdf)
  ggsave(paste0(path_stem, ".png"), plot, width = width, height = height, dpi = 450, bg = "white")
}

dir <- "quality_reports/social_figure_candidates/mayoral"

# Figure 1: share of finalists with usable website text, winners and runners-up, by election year (dodged bars).
cov <- read_csv(file.path(dir, "data/coverage_by_year_role.csv"), show_col_types = FALSE) |>
  mutate(role = factor(if_else(official_result_role == "winner", "Winners", "Runners-up"), levels = c("Winners", "Runners-up")))
ends <- cov |> filter(year == max(year)) |> mutate(x = year + 0.55)
p1 <- ggplot(cov, aes(year, share, fill = role)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_text(data = ends, aes(x, share, label = role, color = role), hjust = 0, size = 3.6, inherit.aes = FALSE) +
  scale_fill_manual(values = c(Winners = CLARA_DARK, `Runners-up` = CLARA_GREY)) +
  scale_color_manual(values = c(Winners = CLARA_DARK, `Runners-up` = CLARA_GREY)) +
  scale_x_continuous(breaks = seq(2010, 2026, 2), expand = expansion(mult = c(0.02, 0.16))) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0.03))) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Finalists with website text (%)") +
  theme_clara()
save_clara(p1, file.path(dir, "figures/mayoral_coverage_by_year"), 7.5, 4.2)

# Figure 2: share of finalists with text whose website has a page of each type, by four-year period.
pt <- read_csv(file.path(dir, "data/page_types_by_period.csv"), show_col_types = FALSE) |>
  mutate(x = as.integer(factor(period)))
# Spread endpoint labels that would overlap: at least 4 points apart, in plotted order.
lab <- pt |> filter(x == max(x)) |> arrange(share) |> mutate(label_y = share)
for (i in seq_len(nrow(lab))[-1]) lab$label_y[i] <- max(lab$share[i], lab$label_y[i - 1] + 4)
p2 <- ggplot(pt, aes(x, share, group = label)) +
  geom_line(color = CLARA_DARK, linewidth = 0.7) +
  geom_point(color = CLARA_DARK, size = 1.9) +
  geom_text(data = lab, aes(y = label_y, label = label), hjust = -0.12, size = 3.6, color = "grey20") +
  scale_x_continuous(breaks = 1:4, labels = levels(factor(pt$period)), expand = expansion(mult = c(0.04, 0.42))) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25)) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Finalists whose website has this page (%)") +
  theme_clara()
save_clara(p2, file.path(dir, "figures/mayoral_page_types"), 7.5, 4.6)

# Figure 3: eligible finalists by election year and text status, as shares of each year (stacked to 100%).
st <- read_csv(file.path(dir, "data/status_by_year.csv"), show_col_types = FALSE) |>
  group_by(year) |> mutate(share = 100 * n / sum(n)) |> ungroup() |>
  mutate(status = factor(status, levels = rev(c("Website text", "Website found, no usable text",
                                                "Search incomplete", "No website found"))))
totals <- st |> count(year, wt = n, name = "n")
p3 <- ggplot(st, aes(year, share, fill = status)) +
  geom_col(width = 0.78) +
  geom_text(data = totals, aes(year, 103, label = n), inherit.aes = FALSE, size = 3, color = "grey45") +
  annotate("text", x = 2009.2, y = 103, label = "n =", size = 3, color = "grey45", hjust = 1) +
  scale_fill_manual(values = c(`Website text` = CLARA_DARK, `Website found, no usable text` = "grey72",
                               `Search incomplete` = "grey88", `No website found` = CLARA_GREY),
                    breaks = rev(levels(st$status))) +
  scale_x_continuous(breaks = seq(2010, 2026, 2)) +
  scale_y_continuous(breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0.02))) +
  coord_cartesian(xlim = c(2009.4, 2026.5), clip = "off") +
  labs(x = NULL, y = "Finalists in each group (%)", fill = NULL) +
  theme_clara() +
  theme(legend.position = "top", legend.justification = "left",
        legend.key.size = unit(0.32, "cm"), legend.text = element_text(size = 10.5),
        legend.margin = margin(0, 0, 6, 0))
save_clara(p3, file.path(dir, "figures/mayoral_status_by_year"), 7.5, 4.2)

# Figure 4: map of the cities with a directly elected mayor in the 48 contiguous states, colored by the share
# of eligible finalists with usable website text; point size shows the number of finalists.
# Coordinates come from maps::us.cities. Anchorage and Honolulu are not shown; Santa Clarita has no finalists.
data(us.cities)
city <- read_csv(file.path(dir, "data/coverage_by_city.csv"), show_col_types = FALSE) |>
  filter(!is.na(n), !state_abb %in% c("AK", "HI")) |>
  mutate(key = city_name |>
           sub(" (city|town|municipality|CDP|urban county|metropolitan government|metro government).*$", "", x = _) |>
           sub("^Nashville-Davidson", "Nashville", x = _) |> sub("^Louisville/Jefferson County", "Louisville", x = _) |>
           sub("^Lexington-Fayette", "Lexington", x = _) |> sub("^Boise City", "Boise", x = _) |>
           sub("^St\\. ", "Saint ", x = _),
         label = sub(" city.*$", "", city_name),
         key = paste(key, state_abb))
coords <- us.cities |> transmute(key = sub("^St\\. ", "Saint ", sub("WASHINGTON", "Washington", name)), lat, long)
city <- city |> left_join(coords, by = "key")
missing <- city |> filter(is.na(lat))
if (nrow(missing) > 0) stop("No coordinates for: ", paste(missing$key, collapse = ", "))
city <- city |>
  mutate(bin = cut(share, c(-Inf, 50, 75, 99.9, Inf), labels = c("Below 50%", "50–74%", "75–99%", "100%"))) |>
  arrange(desc(n)) |>
  st_as_sf(coords = c("long", "lat"), crs = 4326, remove = FALSE)
big <- c("New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "Dallas", "Seattle",
         "Denver", "Boston", "Atlanta", "Miami", "Detroit", "Minneapolis")
states <- st_as_sf(maps::map("state", plot = FALSE, fill = TRUE))
p4 <- ggplot() +
  geom_sf(data = states, fill = "grey94", color = "white", linewidth = 0.3) +
  geom_sf(data = city, aes(fill = bin, size = n), shape = 21, color = "white", stroke = 0.3) +
  # All cities enter the repel step with empty labels, so the labels avoid every point.
  ggrepel::geom_text_repel(data = mutate(city, label = if_else(label %in% big, label, "")),
                           aes(geometry = geometry, label = label, point.size = n),
                           stat = "sf_coordinates", size = 2.8, color = "grey25", min.segment.length = 0.2,
                           segment.color = "grey60", segment.size = 0.25, box.padding = 0.4, point.padding = 0.1,
                           max.overlaps = Inf, seed = 20261023) +
  scale_fill_manual(values = c(`Below 50%` = "#c9dbe9", `50–74%` = "#8fb3d0", `75–99%` = CLARA_BLUE,
                               `100%` = "#0f2f4a"), drop = FALSE) +
  scale_size_area(max_size = 5.5, guide = "none") +
  guides(fill = guide_legend(override.aes = list(size = 3.5))) +
  coord_sf(crs = 5070, datum = NA) +
  labs(fill = "Finalists with\nwebsite text", x = NULL, y = NULL) +
  theme_void(base_size = 12) +
  theme(legend.position = "right", plot.margin = margin(0, 4, 0, 0))
save_clara(p4, file.path(dir, "figures/mayoral_coverage_map"), 7.5, 4.2)

# Figure 5: share of eligible finalists with usable website text, by 2020 population rank group of the city.
sz <- read_csv(file.path(dir, "data/coverage_by_size.csv"), show_col_types = FALSE) |>
  mutate(rank_group = factor(rank_group, levels = rank_group),
         axis_label = paste0(rank_group, "\n", n, " finalists"))
p5 <- ggplot(sz, aes(rank_group, share)) +
  geom_col(fill = CLARA_DARK, width = 0.62) +
  geom_text(aes(label = paste0(round(share), "%")), vjust = -0.6, size = 3.8, color = "grey20") +
  scale_x_discrete(labels = sz$axis_label) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "City population rank, 2020", y = "Finalists with website text (%)") +
  theme_clara() +
  theme(axis.title.x = element_text(margin = margin(t = 8)))
save_clara(p5, file.path(dir, "figures/mayoral_coverage_by_city_size"), 6.5, 4.2)

# Figure 6: elections by the number of finalists with usable website text, by four-year period (dodged bars).
ep <- read_csv(file.path(dir, "data/elections_by_period.csv"), show_col_types = FALSE) |>
  mutate(group = factor(group, levels = c("Both finalists", "One finalist", "Neither finalist")),
         period = factor(period, levels = unique(period)))
ep_totals <- ep |> count(period, wt = n, name = "n")
dodge <- position_dodge(width = 0.8)
p6 <- ggplot(ep, aes(period, share, fill = group)) +
  geom_col(position = dodge, width = 0.75) +
  geom_text(aes(label = paste0(round(share), "%")), position = dodge, vjust = -0.5, size = 3.3, color = "grey20") +
  geom_text(data = ep_totals, aes(period, 100, label = paste(n, "elections")), inherit.aes = FALSE,
            size = 3.2, color = "grey45") +
  scale_fill_manual(values = c(`Both finalists` = CLARA_DARK, `One finalist` = "grey65", `Neither finalist` = "grey35")) +
  scale_y_continuous(limits = c(0, 103), breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0))) +
  labs(x = NULL, y = "Elections (%)", fill = "Website text for") +
  theme_clara() +
  theme(legend.position = "top", legend.justification = "left", legend.key.size = unit(0.32, "cm"),
        legend.text = element_text(size = 10.5), legend.title = element_text(size = 10.5),
        legend.margin = margin(0, 0, 4, 0))
save_clara(p6, file.path(dir, "figures/mayoral_elections_by_period"), 6.5, 4.2)
