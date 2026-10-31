# Chapter 13 data record

## Original source

The files are from Dr Kam Tin Seong's public [IS415 teaching archive](https://github.com/tskam/IS415/tree/acaa1f9995d3d778a02a09c6bbdd5ef4f4eae773/Hands-on_Ex/Hands-on_Ex09/data), at commit `acaa1f9995d3d778a02a09c6bbdd5ef4f4eae773`. Retrieved on 31 October 2026. The source exercise uses the same 2015 condominium resale data and Master Plan 2014 subzones as [Chapter 13](https://r4gdsa.netlify.app/chap13.html).

- `Condo_resale_2015.csv`: 1,436 observations and 23 fields. The raw file has no missing values or duplicate complete rows.
- `MP14_SUBZONE_WEB_PL`: 323 URA Master Plan 2014 subzone polygons, with a declared SVY21 coordinate system. Nine polygons require geometry repair in memory.

No fabricated records or geocoded replacements are used. The chapter's representative source counts, the first records and the area-only OLS fit are reproduced. The revised global and GWR results also reproduce the chapter to numerical tolerance.

## Meaning and preparation

`SELLING_PRICE` is the response; `AREA_SQM` is floor area in square metres and `AGE` is age in years. The `PROX_` fields retain their supplied values. No undocumented source-distance conversion is applied. `FAMILY_FRIENDLY`, `FREEHOLD` and `LEASEHOLD_99YR` retain their source indicator coding. No more detailed definition of the family-friendly flag is invented.

Longitude and latitude are transformed from EPSG 4326 to EPSG 3414. All newly calculated inter-property distances, the 1,500 m neighbour band and the fixed GWR bandwidth use metres. Source postal codes are treated as text and padded to six characters. A sequential `transaction_id` preserves original row identity; it is an analytical key, not a claimed official transaction number.

The data have 1,367 unique coordinate pairs. Repeated locations remain because different properties or units can share coordinates. They are not jittered or deleted. All transactions intersect the repaired subzone layer.

## Retrieval and fingerprints

Run `Rscript scripts/download_data.R` from the exercise folder. It retrieves only the CSV and the four essential shapefile components, verifies each Git blob SHA-1, and refuses to overwrite a different local input. Raw files remain local; the repository contains the retrieval script, code and derived results. Public availability of the archive is not treated as a new blanket redistribution licence.

```text
97be7d012906f1691bbba476533a6f14c36d8ef4  aspatial/Condo_resale_2015.csv
93b82c5d54935bb00abb81c25327c443e348b4ff  geospatial/MP14_SUBZONE_WEB_PL.shp
a87ae19fcb35006e4a69e1ba4486966fad4871da  geospatial/MP14_SUBZONE_WEB_PL.shx
ebaed6594a501171aca80dce88415ebf4e578437  geospatial/MP14_SUBZONE_WEB_PL.dbf
b848068d2e9a4320ae8a549c31a43cc2672d2eb1  geospatial/MP14_SUBZONE_WEB_PL.prj
```

These are Git blob fingerprints, which include Git's blob header, not plain file SHA-1 checksums. The render also writes plain file MD5 checksums to `results/input-checksums.csv`.
