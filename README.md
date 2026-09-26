# cowordkano

使用者附件
those metrics should be separated from each other avoiding overlapping

下午2:16
Updated app.R (line 5328) so the six metric cards use a reserved wide header strip instead of the narrow edge-count range.

They are now spaced separately, and the plot’s x/y limits are expanded to keep the cards visible without clipping. I also corrected a formatting artifact in the edit so the card layer executes properly.

下午2:16
使用者附件
to make 6 metrics separated from each other avoding overlapping in cowordkano.R

下午2:38
Updated cowordkano.R (line 551).

The six metric cards now use a wide, dedicated header band based on the overall plot span—not the narrow edge-count range. The plot window is also expanded so the cards and Top-1 callout remain visible and separated.

下午2:39
使用者附件
add a defaulted radio to remove names with ( ) parantheses , such as replacing Xue, Qikun(Hong Kong) with Xue, Qikun

下午2:43
Added the default-on name-cleanup radio control to cowordkano.R (line 206).

By default it changes names like Xue, Qikun(Hong Kong) to Xue, Qikun in both PT and LA columns before metrics and the Kano plot are calculated. Users can select Keep parenthetical text to preserve affiliations.

下午2:43
write ReadMe.MD for cowordkano.,R in github based on CowordKano: Evaluating Whether Middle-Author Participation Dilutes Leadership Concentration Among Five 2026 Physics Citation Laureates and  Citation counts alone overlook authorship position, leadership, and collaboration structure. We evaluated mentoring-potential profiles of five physics scientists recognized as Clarivate Citation Laureates using career publications indexed in the Web of Science Core Collection. Kano plots assessed the Absolute Advantage Coefficient (AAC), structural-hole capacity (SHC), collaboration leadership index (CLI), middle-author rate (MAR), total unique articles (n), and unique first- or corresponding-author articles (n*). Chihaya Adachi (MAR=53.4%; AAC=0.897), Stephen R. Forrest (46.7%; 0.861), and Mark E. Thompson (55.3%; 0.718) demonstrated relatively high leadership concentration. Nicola A. Spaldin’s substantially higher MAR (90.5%) corresponded to lower AAC (0.561). In Qikun Xue’s document profile, extensive middle authorship allowed Jinling Yu, who had more first- or corresponding-author articles, to replace Xue as the Top 1 Kano author; the resulting profile similarly showed high MAR (87.0%) and low AAC (0.400). These comparisons suggest a descriptive inverse relationship between MAR and AAC: greater middle-author participation may dilute the focal scientist’s relative leadership concentration. However, the sample included only five selected scientists, authorship conventions may differ across physics subfields, and corresponding-authorship metadata may be incomplete. Therefore, this observed pattern is exploratory and cannot establish causality or confirm actual mentoring relationships.

…
下午5:16
Created the GitHub-ready README.md (line 1) for cowordkano.R.

It includes your study summary, input specification, plot mappings, metric definitions, local run instructions, and appropriate exploratory-study limitations.


已編輯 README.md
+73
-0
下午5:17



README.md
# CowordKano

`cowordkano.R` is a Shiny application for examining authorship-position patterns with a Kano-style author plot. It combines publication-role counts and PT–LA collaboration structure to summarize leadership concentration, collaboration position, and structural-hole capacity.

## Study summary

### Evaluating Whether Middle-Author Participation Dilutes Leadership Concentration Among Five 2026 Physics Citation Laureates

Citation counts alone overlook authorship position, leadership, and collaboration structure. We evaluated mentoring-potential profiles of five physics scientists recognized as Clarivate Citation Laureates using career publications indexed in the Web of Science Core Collection. Kano plots assessed the Absolute Advantage Coefficient (AAC), structural-hole capacity (SHC), collaboration leadership index (CLI), middle-author rate (MAR), total unique articles (`n`), and unique first- or corresponding-author articles (`n*`).

Chihaya Adachi (MAR = 53.4%; AAC = 0.897), Stephen R. Forrest (46.7%; 0.861), and Mark E. Thompson (55.3%; 0.718) demonstrated relatively high leadership concentration. Nicola A. Spaldin’s substantially higher MAR (90.5%) corresponded to lower AAC (0.561). In Qikun Xue’s document profile, extensive middle authorship allowed Jinling Yu, who had more first- or corresponding-author articles, to replace Xue as the Top-1 Kano author; the resulting profile similarly showed high MAR (87.0%) and low AAC (0.400).

These comparisons suggest a descriptive inverse relationship between MAR and AAC: greater middle-author participation may dilute the focal scientist’s relative leadership concentration. However, the sample included only five selected scientists, authorship conventions may differ across physics subfields, and corresponding-authorship metadata may be incomplete. Therefore, this observed pattern is exploratory and cannot establish causality or confirm actual mentoring relationships.

## Input data

Upload a CSV file containing these two required columns:

| Column | Meaning |
| --- | --- |
| `PT` | First author |
| `LA` | Corresponding author |

Each valid row represents one publication. Rows with an empty `PT` or `LA` value are excluded.

By default, the app removes parenthetical text from names. For example, `Xue, Qikun(Hong Kong)` becomes `Xue, Qikun`. The sidebar option can retain parenthetical text when that distinction is needed.

## Kano plot

The plot displays the 20 authors with the highest author-role count. It uses:

- X-axis: first/last-author edge count.
- Y-axis: document/author-role count.
- Bubble area: SHC (%).
- Bubble colour: CLI category.
- Header cards: AAC, SHC, CLI, MAR/MAT, `n`, and `n*` for the Top-1 author.

The highlighted red bubble and callout identify the Top-1 Kano author.

## Metrics

| Metric | Interpretation |
| --- | --- |
| AAC | Absolute Advantage Coefficient calculated from the three highest author-role counts. |
| SHC | Structural-hole capacity, defined as `1 − Burt constraint` in the undirected PT–LA author-link network. |
| CLI | Collaboration Leadership Index: corresponding-author roles divided by first- plus corresponding-author roles, excluding self-pairs. |
| MAR/MAT | Middle-author rate/proportion: the share of retained publications in which an author appears in neither the first- nor corresponding-author role. |
| `n` | Number of retained valid publication rows. |
| `n*` | `first_n + corresponding_n + simple_n`, where `simple_n` counts rows for which PT and LA are the same author. |

## Run locally

Install the required packages in R:

```r
install.packages(c("shiny", "dplyr", "readr", "tidyr", "ggplot2", "ggrepel"))
```

Then run:

```r
shiny::runApp("cowordkano.R")
```

Or open `cowordkano.R` in RStudio and click **Run App**.

## Interpretation and limitations

CowordKano is a descriptive visualization and should not be used to infer causality, mentorship, contribution quality, or researcher value. Interpretation should account for incomplete corresponding-author metadata, field-specific authorship conventions, name disambiguation, publication coverage, and the selected population.

## License

Add a license appropriate for your repository before public release.

