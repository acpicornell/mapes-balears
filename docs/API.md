# API del NGIB — referencia (verificada 2026-07-02)

Servidor **ArcGIS REST 10.91** de IDEIB. Raíz de servicios:
`https://ideib.caib.es/geoserveis/rest/services`

## Servicio principal

```
https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer
```
- `serviceDescription`: "Servei per consultar el Nomenclàtor de les Illes Balears"
- `copyrightText`: www.icgib.org · `capabilities`: Map, Query, Data
- `spatialReference.wkid`: **25831** (ETRS89 / UTM 31N)
- `fullExtent`: xmin 311546.7 ymin 4248990.7 xmax 643334.9 ymax 4480766.1

### Capas y tablas

| id | nombre | geom | uso |
|----|--------|------|-----|
| 0 | `Lloc_anomenat` | Point | **topónimos (55.696)** |
| 1 | `SDE.Arees_NGIB` | Polygon | áreas |
| 2 | `Variant_nom_geografic` | Point | variantes de nombre |
| 3 | `Consulta_nom_geografic` | tabla | nombres |
| 4 | `Pronunciacio_del_nom` | tabla | pronunciaciones |
| 6 | `Font` | tabla | fuentes |
| 9 | `Valor_municipi` | tabla | código INE ↔ municipio |
| 14 | `Valor_tipus_INSPIRE` | tabla | tipo INSPIRE |
| 15 | `Valor_tipus_local` | tabla | tipo local (detallado) |
| 16 | `Valor_tipus_superlocal` | tabla | tipo superlocal |
| 18 | `Nom_geografic_preferent` | tabla | nombre preferente |

### Campos de la capa 0 (`Lloc_anomenat`)

`OBJECTID`, `INSPIRE_ID`, `NOM_GEOGRAFIC`, `GRAFIA` (grafía del nombre),
`TIPUS_INSPIRE`, `TIPUS_LOCAL`, `TIPUS_SUPERLOCAL`, `MUNICIPI`, `NUCLI`, `ILLA`,
`EXPLOTACIO_AGRARIA`, `ORGANITZACIO_COMPETENT`, `FONT`, `ESTAT_NG`,
`ESCALA_MINIMA/MAXIMA_DE_VISUALITZACIO`, `OBSERVACIONS`, `BIBLIOGRAFIA`.

### Reparto por TIPUS_INSPIRE (55.696 total)

| código | tipo | nº |
|--------|------|----|
| 7 | Accident geogràfic | 28.155 |
| 2 | Construcció | 20.102 |
| 5 | Hidrografia | 3.737 |
| 4 | Xarxa de transport | 2.553 |
| 3 | Població | 832 |
| 9 | (otros) | 228 |
| 1 | Unitat administrativa | 67 |

## Parámetros de query relevantes

`/0/query` acepta (GET, form-urlencoded):
- `where=1=1` · `returnCountOnly=true` → conteo
- `outFields=*` · `returnGeometry=true|false`
- `outSR=25831` (o 4326)
- `resultOffset` + `resultRecordCount` → **paginación** (soportada)
- `f=json | geojson | pjson | html`
- `maxRecordCount = 1000` por página

`advancedQueryCapabilities`: pagination, orderBy, statistics, distinct,
sqlExpression, standardizedQueries → todo `true`.

## Alternativas de acceso

- **ogr2ogr / GDAL** driver `ESRIJSON` directo sobre el endpoint `/0/query`.
- **QGIS**: "Add ArcGIS REST Server Layer" con la URL del MapServer.
- **owslib/WMS/WFS**: IDEIB también expone WMS/WFS por GeoServer para otras
  capas; para el NGIB el camino directo es este ArcGIS REST.
