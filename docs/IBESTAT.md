# API de IBESTAT (plataforma eDatos / METAMAC)

IBESTAT publica sus datos en la plataforma **eDatos** (SIEMAC/METAMAC, la misma
del ISTAC de Canarias). API REST bien estructurada, formato XML por defecto y
**JSON con `Accept: application/json`**.

Base: `https://ibestat.es/edatos/apis/statistical-resources/v1.0`

## Recursos (verificado 2026-07-02)

| Recurso | Endpoint | Total |
|---------|----------|-------|
| datasets | `/datasets` · `/datasets/IBESTAT` | **4150** |
| collections | `/collections` | 85 |
| queries (predefinidas) | `/queries` | 349 |

Paginación: `?limit=N&offset=M` (limit máx. 1000). Cada item trae `id`, `urn` y
`name.text[]` (títulos `ca`/`es`).

## Leer un dataset (cubo de datos)

```
/datasets/IBESTAT/{ID}/~latest          # ~latest = última versión (o /1.0)
Accept: application/json
```

Estructura del JSON:
- `data.dimensions.dimension[]` → cada dimensión con `dimensionId` y
  `representations.representation[]` (`code`, `index`).
- `data.observations` → **string** con los valores en orden *row-major* sobre
  las dimensiones, **separados por `" | "`** (los ausentes van vacíos).

### Ejemplo usado en este proyecto — población municipal

Dataset **`000001A_000001`** "Població municipal empadronada segons el sexe.
Municipis de les Illes Balears per anys". Dimensiones:

| dim | id | tamaño | códigos |
|-----|----|--------|---------|
| 0 | `TERRITORIO` | 67 | INE municipal (`07001`…) — **coincide con `MUNICIPI_INE_ID` del NGIB** |
| 1 | `TIME_PERIOD` | 28 | 2025 … 1998 |
| 2 | `SEXO` | 3 | `_T`, `M`, `F` |
| 3 | `MEDIDAS` | 3 | `POBLACION_PADRON_TVA`, `POBLACION_PADRON`, `POBLACION_PADRON_VA` |

Filtro por dimensión: `?dim=TIME_PERIOD:2025` (encadenar con `|`; en la práctica
solo aplicó fiable la 1ª dim, así que **descargamos el corte del año y
seleccionamos `_T` + `POBLACION_PADRON` en R** — ver `R/50_join_ibestat.R`).

Para la observación de un municipio: bloque de `nSEXO*nMEDIDAS = 9` valores;
población total = posición `(idx(_T))*nMED + idx(POBLACION_PADRON)`.

## Catálogo temático (para explorar los 4150)

`scripts/04_ibestat_population.sh` vuelca `data/raw/ibestat/catalogo_datasets.csv`
(id + título). Busca ahí posibles cruces: superficie, actividad agraria,
viviendas, turismo, entidades singulares de población, etc.

> Cruce clave con el NGIB: el **código INE municipal** (`MUNICIPI_INE_ID` en la
> tabla `Valor_municipi` del NGIB = `TERRITORIO` en IBESTAT).
