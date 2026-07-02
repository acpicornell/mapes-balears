# IBESTAT API (eDatos / METAMAC platform)

IBESTAT publishes its data on the **eDatos** platform (SIEMAC/METAMAC, the same
one used by the ISTAC of the Canary Islands). Well-structured REST API, XML
format by default and **JSON with `Accept: application/json`**.

Base: `https://ibestat.es/edatos/apis/statistical-resources/v1.0`

## Resources (verified 2026-07-02)

| Resource | Endpoint | Total |
|---------|----------|-------|
| datasets | `/datasets` · `/datasets/IBESTAT` | **4150** |
| collections | `/collections` | 85 |
| queries (predefined) | `/queries` | 349 |

Pagination: `?limit=N&offset=M` (limit max. 1000). Each item carries `id`, `urn`
and `name.text[]` (`ca`/`es` titles).

## Reading a dataset (data cube)

```
/datasets/IBESTAT/{ID}/~latest          # ~latest = latest version (or /1.0)
Accept: application/json
```

JSON structure:
- `data.dimensions.dimension[]` → each dimension with `dimensionId` and
  `representations.representation[]` (`code`, `index`).
- `data.observations` → **string** with the values in *row-major* order over
  the dimensions, **separated by `" | "`** (missing ones are left empty).

### Example used in this project — municipal population

Dataset **`000001A_000001`** "Població municipal empadronada segons el sexe.
Municipis de les Illes Balears per anys". Dimensions:

| dim | id | size | codes |
|-----|----|--------|---------|
| 0 | `TERRITORIO` | 67 | INE municipal (`07001`…) — **matches `MUNICIPI_INE_ID` in the NGIB** |
| 1 | `TIME_PERIOD` | 28 | 2025 … 1998 |
| 2 | `SEXO` | 3 | `_T`, `M`, `F` |
| 3 | `MEDIDAS` | 3 | `POBLACION_PADRON_TVA`, `POBLACION_PADRON`, `POBLACION_PADRON_VA` |

Filter by dimension: `?dim=TIME_PERIOD:2025` (chain with `|`; in practice only
the 1st dimension applied reliably, so **we download the year slice and select
`_T` + `POBLACION_PADRON` in R** — see `R/50_join_ibestat.R`).

For a municipality's observation: block of `nSEXO*nMEDIDAS = 9` values;
total population = position `(idx(_T))*nMED + idx(POBLACION_PADRON)`.

## Thematic catalog (to explore the 4150)

`scripts/04_ibestat_population.sh` dumps `data/raw/ibestat/catalogo_datasets.csv`
(id + title). Look there for possible cross-references: area, agrarian activity,
housing, tourism, singular population entities, etc.

> Key cross-reference with the NGIB: the **municipal INE code** (`MUNICIPI_INE_ID` in the
> `Valor_municipi` table of the NGIB = `TERRITORIO` in IBESTAT).
