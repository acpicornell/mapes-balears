# NGIB API — reference (verified 2026-07-02)

IDEIB **ArcGIS REST 10.91** server. Services root:
`https://ideib.caib.es/geoserveis/rest/services`

## Main service

```
https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer
```
- `serviceDescription`: "Servei per consultar el Nomenclàtor de les Illes Balears"
- `copyrightText`: www.icgib.org · `capabilities`: Map, Query, Data
- `spatialReference.wkid`: **25831** (ETRS89 / UTM 31N)
- `fullExtent`: xmin 311546.7 ymin 4248990.7 xmax 643334.9 ymax 4480766.1

### Layers and tables

| id | name | geom | use |
|----|--------|------|-----|
| 0 | `Lloc_anomenat` | Point | **place names (55,696)** |
| 1 | `SDE.Arees_NGIB` | Polygon | areas |
| 2 | `Variant_nom_geografic` | Point | name variants |
| 3 | `Consulta_nom_geografic` | table | names |
| 4 | `Pronunciacio_del_nom` | table | pronunciations |
| 6 | `Font` | table | sources |
| 9 | `Valor_municipi` | table | INE code ↔ municipality |
| 14 | `Valor_tipus_INSPIRE` | table | INSPIRE type |
| 15 | `Valor_tipus_local` | table | local type (detailed) |
| 16 | `Valor_tipus_superlocal` | table | superlocal type |
| 18 | `Nom_geografic_preferent` | table | preferred name |

### Fields of layer 0 (`Lloc_anomenat`)

`OBJECTID`, `INSPIRE_ID`, `NOM_GEOGRAFIC`, `GRAFIA` (spelling of the name),
`TIPUS_INSPIRE`, `TIPUS_LOCAL`, `TIPUS_SUPERLOCAL`, `MUNICIPI`, `NUCLI`, `ILLA`,
`EXPLOTACIO_AGRARIA`, `ORGANITZACIO_COMPETENT`, `FONT`, `ESTAT_NG`,
`ESCALA_MINIMA/MAXIMA_DE_VISUALITZACIO`, `OBSERVACIONS`, `BIBLIOGRAFIA`.

### Breakdown by TIPUS_INSPIRE (55,696 total)

| code | type | no. |
|--------|------|----|
| 7 | Accident geogràfic | 28,155 |
| 2 | Construcció | 20,102 |
| 5 | Hidrografia | 3,737 |
| 4 | Xarxa de transport | 2,553 |
| 3 | Població | 832 |
| 9 | (others) | 228 |
| 1 | Unitat administrativa | 67 |

## Relevant query parameters

`/0/query` accepts (GET, form-urlencoded):
- `where=1=1` · `returnCountOnly=true` → count
- `outFields=*` · `returnGeometry=true|false`
- `outSR=25831` (or 4326)
- `resultOffset` + `resultRecordCount` → **pagination** (supported)
- `f=json | geojson | pjson | html`
- `maxRecordCount = 1000` per page

`advancedQueryCapabilities`: pagination, orderBy, statistics, distinct,
sqlExpression, standardizedQueries → all `true`.

## Access alternatives

- **ogr2ogr / GDAL** `ESRIJSON` driver directly against the `/0/query` endpoint.
- **QGIS**: "Add ArcGIS REST Server Layer" with the MapServer URL.
- **owslib/WMS/WFS**: IDEIB also exposes WMS/WFS through GeoServer for other
  layers; for the NGIB the direct path is this ArcGIS REST.
