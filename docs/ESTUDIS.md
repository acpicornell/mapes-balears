# Two monographic studies: possessions and llogarets

Cross-referencing the **NGIB** (place names) with **IBESTAT** (2025 municipal
population) and GISCO boundaries. Reproducible: `make all && make possessions llogarets crossibestat`.

---

## 1. Les possessions de Mallorca (i Balears)

⚠️ **Important nuance.** `TIPUS_LOCAL 3014` is not "16,031 possessions": it is a
code that **groups together** *"Finca, possessió, lloc, casa pagesa, caseta"*. The
NGIB does not separate them by field (`TIPUS_SUPERLOCAL` only breaks out ~1,264:
mostly 1,012 *"Llocs"*, the Menorcan term for a possessió). That is why we
subclassify by **place-name morphology** (`R/42_finques_classif.R`), which is how
Mallorcan possessions are studied:

| category | criterion (name) | count (Balears) |
|-----------|-------------------|-------------:|
| **Possessió** | Son, So n', Son na, Sa n', Rafal, Alqueria, Beni-, or "Llocs" (Menorca) | **3,068** |
| Casa (Can/Cas) | Can, Ca'n, Ca na, Ca s', Cas (cases pageses) | 9,423 |
| Caseta/Barraca | minor constructions | 799 |
| Other | es/sa/ses/s' + toponym, etc. | 2,741 |

In other words, **possessions *stricto sensu* ≈ 3,000** (2,011 in Mallorca), not
16,031. The map `out/possessions_classif_mallorca.png` (small multiples) makes it
obvious: the possessions concentrate in the **Pla** and the **Migjorn**; the
"Can…" cases are the majority and cluster closer to the villages.

The municipal analyses below use the full set (16,031 *edificacions rurals*) as a
proxy for the rural footprint; for a strict study of possessions, filter
`CATEGORIA = 'Possessió'` in `data/processed/ngib_finques.gpkg`.

Reference population (IBESTAT 2025): 1,237,480 inhabitants.

Maps:
- `out/possessions_mallorca.png` — nocturnal portrait of Mallorca's ~12,000
  possessions over the relief. The historical agrarian structure is legible: the
  dense **Pla**, the more scattered **Serra de Tramuntana**, the tourist coast
  almost empty.
- `out/possessions_por_municipio.png` — choropleth of possessions/100 km².
- `out/possessions_vs_poblacion.png` — number of possessions vs. population (log).

### Findings

**Density (possessions/100 km²)** — the agricultural municipalities of the Pla dominate:

| municipi | poss/100km² | possessions | inhab |
|----------|------------:|------------:|----:|
| Costitx | 905 | 139 | 1,591 |
| Montuïri | 841 | 348 | 3,289 |
| Sant Joan de Labritja | 790 | 960 | 7,046 |
| Algaida | 754 | 681 | 6,357 |
| Sineu | 719 | 344 | 4,537 |

**Absolute number** — large municipalities with extensive territory:

| municipi | possessions | inhab |
|----------|------------:|----:|
| Manacor | 1,546 | 49,153 |
| Sant Joan de Labritja | 960 | 7,046 |
| Palma | 821 | 434,786 |
| Felanitx | 796 | 19,146 |
| Llucmajor | 746 | 40,502 |

**Possessions per 1,000 inhabitants** (relative rural footprint) — Sant Joan de
Labritja (136), Algaida (107), Montuïri (106): territories where farm toponymy
weighs far more than the current population. At the other extreme, Eivissa,
Calvià or Palma: lots of population, few possessions per inhabitant.

> Note: Sant Joan de Labritja (Eivissa) stands out on all three metrics — Ibizan
> farm toponymy is very well represented in the NGIB.

---

## 2. Els llogarets

`TIPUS_LOCAL 3011` — *"Altre nucli de població, llogaret"* (a minor population
nucleus, below the municipality). **160 llogarets** across all the islands.

Map: `out/llogarets.png` — the 160 llogarets labelled over the islands (Randa,
Biniaraix, Caimari, Moscari, Portocolom, s'Horta, Biniagual…).

Possible extensions of the study:
- Cross-reference with **population by entitat singular** from IBESTAT (look in
  `data/raw/ibestat/catalogo_datasets.csv`) to size each llogaret.
- Relate llogarets ↔ nearby possessions (many llogarets arise from the
  parcelling of a possessió): spatial buffer/neighbourhood in `sf`.

---

## Reproduce

```bash
nix develop            # data
make all               # NGIB (place names, subsets, lookups) + IBESTAT
nix develop .#r        # cartography
make possessions llogarets crossibestat
```
Indicators by municipality: `data/processed/municipis_indicadors.csv`.
