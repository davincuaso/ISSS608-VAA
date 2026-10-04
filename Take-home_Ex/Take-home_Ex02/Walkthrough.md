# How to read and explain this analysis

## 1. Start with what is being counted

The input is a record of reported events. I chose battles, explosions/remote violence,
and violence against civilians because they form a clear, consistent core violence
series. I kept fatalities separate because ten incidents and ten reported deaths
answer different questions. The report spells out the excluded event types so the
result cannot be mistaken for all political violence in Myanmar.

The first thing to check is the retention table. It links the 87,109 source rows to
the 53,899 events actually analysed. Every map uses the latter population.

## 2. Why the map join comes before aggregation

ACLED place names and boundary names may differ. The code places the coordinates
inside the official township polygons instead of relying on a text match. That
makes the geographic rule explicit, but does not make an approximate coordinate
precise. Precision-3 locations are excluded, and eight remaining events without a
unique polygon match are kept out of the totals. The private exclusion audit lets
you inspect them.

## 3. Why zero months must be inserted

Without the complete grid, a month with no recorded event would vanish. A trend
calculation could then treat irregular observations as though they were consecutive
months. The complete cube has 330 × 57 = 18,810 bins. A zero is a statement about
this filtered extract, not proof that nothing happened in that township.

## 4. Why use both Local Moran and Gi*

Local Moran compares a township with its neighbours and can identify an outlier:
a relatively low-count township beside a high-count neighbourhood, for example.
Gi* asks whether the local sum, including the township itself, is unusually high or
low. That is why the maps need not give identical classifications.

Queen adjacency is the baseline because the question concerns neighbouring
places. The three isolated townships receive documented nearest-centroid links.
The four-nearest-neighbour check asks whether the conclusions survive a different
spatial comparison group.

## 5. What a significant result means

The permutations keep the focal value fixed and reshuffle the other values used
in its neighbourhood. The p-value describes how unusual the observed statistic is
under that null model. It does not give the probability that a township is truly
dangerous, nor explain why violence occurs there.

The main maps follow p < .05. The report also shows multiple-testing adjustments.
Grey means insufficient evidence for that classification under the selected test.
It never means safe or unimportant.

## 6. How EHSA adds time

The space-time neighbourhood contains the township and its spatial neighbours in
the current and previous month. Gi* is computed for each bin against the complete
cube. The Mann–Kendall test then examines the ordered Gi* series. Tau gives the
trend direction; the Sen slope describes its median annual rate in Gi* units.
Neither is an annual percentage change in event counts.

A history label also uses when significant hot/cold months occur. For example,
52 significant months are needed to reach 90% of the 57-month period. Wetlet's
44 hot months are substantial, but do not automatically satisfy an endpoint rule.
Always read the trajectory alongside the label.

The main EHSA maps also filter for a significant trend. The appendix keeps all
recognised histories so a persistent pattern is not erased simply because it has
no trend. The report flags serial dependence: overlapping monthly windows make
the usual trend p-values exploratory.

## 7. What the added analyses contribute

The robustness map separates the 27 baseline hot spots that survive both checks
from the 11 sensitive ones. This supports a more qualified conclusion than simply
presenting all 38 as equally reliable.

The centre-shift extension asks a different question: has the overall spatial
balance of recorded events moved? January–September is compared across all five
years. The 2025 centre is about 116 km from the 2021 centre, mainly south. Whole
months are resampled to show sensitivity to their composition. This is not a path
of conflict movement or an estimate of where an incident will occur next.

## 8. What to say about practical use

The maps can help decide where further local investigation is warranted. They
cannot determine current travel safety, operational deployment or aid allocation
on their own. The data end in September 2025, and reporting coverage is not known.

Open the report first, then the slides. Expand the code sections when you want to
trace a decision to its implementation. The CSV outputs allow township-level
checking without reading raw event records into every chart.
