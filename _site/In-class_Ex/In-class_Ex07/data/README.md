# In-Class Exercise 7 data record

This exercise uses the same teaching inputs as [Hands-on Exercise 7](../../../Hands-on_Ex/Hands-on_Ex07/data/README.md). The original specification comes from Dr. Kam Tin Seong's supplied `In-class_Ex07-accessibility.qmd` and [Chapter 17](https://r4gdsa.netlify.app/chap17.html).

## Input copies

- `geospatial/MP14_SUBZONE_NO_SEA_PL.*`: 323 URA Master Plan 2014 subzones, used for the map context. The chapter attributes the original layer to data.gov.sg.
- `geospatial/hexagons.*`: 3,125 teaching-grid origin polygons. The source key `fid` becomes `id` in the analysis.
- `geospatial/ELDERCARE.*`: 120 teaching-snapshot destinations. Their `fid` values contain gaps between 1 and 133.
- `aspatial/OD_Matrix.csv`: 375,000 origin-destination pairs with entry, network, exit and total costs in metres.

Local copies were reused from Hands-on Exercise 7 and verified by their fingerprints. Their retrieval source is the public [course-file mirror](https://github.com/credor/ISSS626-GAA/tree/316e52d2088516f6fae69eb983757e021d1a2a10/Hands-on_Ex/Hands-on_Ex01/data), fixed at commit `316e52d2088516f6fae69eb983757e021d1a2a10`. This identifies the copies used; it is not a claim that the mirror is an official publisher or that the locations are current.

The raw inputs remain local and are ignored by Git. Run `Rscript scripts/download_data.R` from this exercise folder to retrieve the pinned copies. The original files are unchanged by the analysis. Invalid subzone geometries are repaired in memory. The full set of input MD5 fingerprints is written to `results/input-checksums.csv` during rendering.

## Key SHA-256 fingerprints

```text
f52e4009b0bea32ca52841223f8c37bd880b022faf8ba1a752c563377665c2ef  aspatial/OD_Matrix.csv
bd0fd7fff4064617aedff906c8664768b869aa4fce3a8f0728011e789df10dae  geospatial/MP14_SUBZONE_NO_SEA_PL.shp
7c91fbb2d8012a91cbf45b7e93e04305075709aa662da6d40f285d39c02c5af7  geospatial/hexagons.shp
66930af902256e2e9b2d2964537739f9aa8953765f87858fccb5cc2f990efcbb  geospatial/ELDERCARE.shp
```

## Teaching assumptions

Every hexagon is assigned demand 100 and every centre capacity 100, following the supplied guide. The nearest-centre calculation uses one opportunity per actual centre. These are different quantities: the first identifies the nearest location, while the catchment models compare assumed capacity with assumed demand.

Chapter 17 describes the prepared grid, centre layer and OD matrix as Prof. Kam's teaching/research materials, permitted for the hands-on exercise with approval required for other uses. Preserve that condition when reusing the inputs.
