# Dos estudios monográficos: possessions i llogarets

Cruce del **NGIB** (topónimos) con **IBESTAT** (población municipal 2025) y
límites GISCO. Reproducible: `make all && make possessions llogarets crossibestat`.

---

## 1. Les possessions de Mallorca (i Balears)

`TIPUS_LOCAL 3014` — *"Finca, possessió, lloc, casa pagesa, caseta"*.
**16.031 possessions** en el NGIB (16.011 caen dentro de un municipio al hacer
el join espacial). Población de referencia (IBESTAT 2025): 1.237.480 hab.

Mapas:
- `out/possessions_mallorca.png` — retrato nocturno de las ~12.000 possessions de
  Mallorca sobre el relieve. Se lee la estructura agraria histórica: el **Pla**
  denso, la **Serra de Tramuntana** más dispersa, el litoral turístico casi vacío.
- `out/possessions_por_municipio.png` — coropleta possessions/100 km².
- `out/possessions_vs_poblacion.png` — nº de possessions vs. población (log).

### Hallazgos

**Densidad (possessions/100 km²)** — dominan los municipios agrícolas del Pla:

| municipi | poss/100km² | possessions | hab |
|----------|------------:|------------:|----:|
| Costitx | 905 | 139 | 1.591 |
| Montuïri | 841 | 348 | 3.289 |
| Sant Joan de Labritja | 790 | 960 | 7.046 |
| Algaida | 754 | 681 | 6.357 |
| Sineu | 719 | 344 | 4.537 |

**Número absoluto** — municipios grandes y de término extenso:

| municipi | possessions | hab |
|----------|------------:|----:|
| Manacor | 1.546 | 49.153 |
| Sant Joan de Labritja | 960 | 7.046 |
| Palma | 821 | 434.786 |
| Felanitx | 796 | 19.146 |
| Llucmajor | 746 | 40.502 |

**Possessions por 1.000 habitantes** (huella rural relativa) — Sant Joan de
Labritja (136), Algaida (107), Montuïri (106): territorios donde la toponimia de
finca pesa mucho más que la población actual. En el otro extremo, Eivissa,
Calvià o Palma: mucha población, pocas possessions por habitante.

> Nota: Sant Joan de Labritja (Eivissa) destaca en las tres métricas — la
> toponimia de finca pitiüsa está muy representada en el NGIB.

---

## 2. Els llogarets

`TIPUS_LOCAL 3011` — *"Altre nucli de població, llogaret"* (núcleo de población
menor, por debajo del municipio). **160 llogarets** en todas las islas.

Mapa: `out/llogarets.png` — los 160 llogarets etiquetados sobre las islas
(Randa, Biniaraix, Caimari, Moscari, Portocolom, s'Horta, Biniagual…).

Posibles ampliaciones del estudio:
- Cruzar con **población por entidad singular** de IBESTAT (buscar en
  `data/raw/ibestat/catalogo_datasets.csv`) para dimensionar cada llogaret.
- Relacionar llogarets ↔ possessions cercanas (muchos llogarets nacen de la
  parcelación de una possessió): buffer/vecindad espacial en `sf`.

---

## Reproducir

```bash
nix develop            # datos
make all               # NGIB (topónimos, subsets, lookups) + IBESTAT
nix develop .#r        # cartografía
make possessions llogarets crossibestat
```
Indicadores por municipio: `data/processed/municipis_indicadors.csv`.
