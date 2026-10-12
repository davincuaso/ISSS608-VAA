# Hands-on Exercise 7 data record

The local inputs reproduce the teaching scenario in [Chapter 17](https://r4gdsa.netlify.app/chap17.html). They were retrieved on 13 October 2026 from the public [credor/ISSS626-GAA course-file mirror](https://github.com/credor/ISSS626-GAA/tree/316e52d2088516f6fae69eb983757e021d1a2a10/Hands-on_Ex/Hands-on_Ex01/data), pinned to commit `316e52d2088516f6fae69eb983757e021d1a2a10`. This is a mirror of the teaching files, not a new download of current service locations.

## Inputs

- `geospatial/MP14_SUBZONE_NO_SEA_PL.*`: 323 Master Plan 2014 subzone polygons. The chapter attributes the source to URA via data.gov.sg. Nine invalid geometries are repaired in memory before joining; the original file is unchanged.
- `geospatial/hexagons.*`: 3,125 origin cells with the chapter's 250 m radius grid. `fid` is the origin key.
- `geospatial/ELDERCARE.*`: 120 listed centres. `fid` is the destination key and contains gaps between 1 and 133. The source metadata dates to 2016; these records are not a 2026 inventory.
- `aspatial/OD_Matrix.csv`: 375,000 origin-destination pairs. The six columns are `origin_id`, `destination_id`, `entry_cost`, `network_cost`, `exit_cost` and `total_cost`. All costs are in metres.

The feature counts, IDs, matrix dimensions and sample distances agree with the structure shown in Chapter 17. This verification does not claim a byte-for-byte comparison with an unavailable instructor upload.

## Retrieval and use

From the exercise folder, run `Rscript scripts/download_data.R` before rendering. The script fetches the pinned files. The raw inputs are ignored by Git, while the retrieval script, analysis, checksums and derived score tables are included.

Chapter 17 identifies the grid, prepared centre layer and OD matrix as Prof. Kam's teaching/research materials, with hands-on use permitted and approval required for other uses. Keep that condition with the files and obtain the relevant approval before reusing them outside the exercise.

## SHA-256 fingerprints

```text
f52e4009b0bea32ca52841223f8c37bd880b022faf8ba1a752c563377665c2ef  aspatial/OD_Matrix.csv
bd0fd7fff4064617aedff906c8664768b869aa4fce3a8f0728011e789df10dae  geospatial/MP14_SUBZONE_NO_SEA_PL.shp
d0e3698e14237ee6243b89844c68ce8c959c612df5f763155b857aa97badc3db  geospatial/MP14_SUBZONE_NO_SEA_PL.dbf
c06a0fbc6324a796994f47f31f45443a7b5c49d80ac279882eee89406c13dfea  geospatial/MP14_SUBZONE_NO_SEA_PL.shx
154dc78ac6632ba94b86bc576c9ef3311f4b51c2c6df994ce57b5d57f10271d0  geospatial/MP14_SUBZONE_NO_SEA_PL.prj
7c91fbb2d8012a91cbf45b7e93e04305075709aa662da6d40f285d39c02c5af7  geospatial/hexagons.shp
03b89082ce3770309eeff20df3a5991ff9339bdae4921b29b518205574336203  geospatial/hexagons.dbf
da2e2cb20be7b6391b7f96f3474efe450e1015131068b03fc404fc0246dcc342  geospatial/hexagons.shx
3d70480f485191054b744263ab4c9632116edab90b1fd2a0da26d64b8752a11c  geospatial/hexagons.prj
66930af902256e2e9b2d2964537739f9aa8953765f87858fccb5cc2f990efcbb  geospatial/ELDERCARE.shp
b1624bbb840f373bbbba1b955395d42faaf8a35bb954e3fa0527e777498c4771  geospatial/ELDERCARE.dbf
e749a9a786c55e2285b8ca2bf53133cbe449533b5f377ab66a797b2dc6dd03bb  geospatial/ELDERCARE.shx
3d70480f485191054b744263ab4c9632116edab90b1fd2a0da26d64b8752a11c  geospatial/ELDERCARE.prj
```

## Checks performed on render

The Quarto source checks CRS, valid geometry, unique IDs, complete pair coverage, positive and finite total distances, and agreement between total cost and its three components. It aligns matrix rows and columns by source IDs, checks the three model scores against independent formulas, and assigns exactly one planning region to each hexagon.
