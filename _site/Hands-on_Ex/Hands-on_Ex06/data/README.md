# Hands-on Exercise 6 data record

This folder contains the data used in Hands-on Exercise 6.

## Files

- `aspatial/Shan-ICT.csv`: 55 township records and six household ICT counts from the 2014 Myanmar Population and Housing Census.
- `geospatial/myanmar_township_boundaries.*`: Myanmar township boundary shapefile with 330 polygons. The analysis filters it to 55 townships in Shan (East), Shan (North), and Shan (South).

The chapter attributes the township boundary to the [Myanmar Information Management Unit](https://themimu.info/) and the ICT data to the [2014 Myanmar Population and Housing Census](https://myanmar.unfpa.org/en/publications/2014-population-and-housing-census-myanmar-data-sheet). These local copies were retrieved on 1 October 2026 from the public [course-file mirror](https://github.com/endurrus/IS415-GAA/tree/master/Hands-on_Ex/Hands-On_Ex07/data) used to reproduce Chapter 12.

## Verification

The files match the structure expected by the chapter:

- 330 polygons in the full township layer;
- 55 Shan polygons after filtering;
- 55 rows and 11 columns in the ICT table;
- 55 unique township codes; and
- no unmatched ICT rows after joining on `TS_PCODE`.

SHA-256 checksums:

```text
2fedd5242ea0e3da00575f06f42806404448e45895e583a380e97f465b0f2528  Shan-ICT.csv
3ad3031f5503a4404af825262ee8232cc04d4ea6683d42c5dd0a2f2a27ac9824  myanmar_township_boundaries.cst
1622669a062c0dd389b1b5fe35d698ffb69a811d3a790db9cda0e0491e0cf115  myanmar_township_boundaries.dbf
de5c1395a1ffc517ee2112b217c89595d01a7944eb65374c06547d4771b29167  myanmar_township_boundaries.prj
6fc902d968ca489b5f9ba0fa430a1fa435b8c03970244057c8d7467112fc518d  myanmar_township_boundaries.shp
29b5459d7a387da441ff2df8ebe9e659ad792aefddf390d1ced5d5695458734b  myanmar_township_boundaries.shx
```

