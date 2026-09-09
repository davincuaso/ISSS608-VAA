# Take-home Exercise 1: option comparison

This note supports the student's decision. It is not an assessed finding and should not be copied into the report without independent checking and rewriting.

## Recommendation

Use **Option B with the Thailand Road Accident 2019–2022 dataset restricted to 2022**, subject to a local audit of the downloaded files. It is the more reproducible route for this deadline because the study year is complete, the dataset includes English-language fields and coordinates, and the Bangkok Metropolitan Region can be defined with six ADM1 provinces.

## Comparison

| Criterion | Option A: 2026 Kalimantan fire detections | Option B: 2022 Bangkok-region accidents |
|---|---|---|
| Event source | NASA FIRMS satellite active-fire detections | Thailand Road Accident 2019–2022 on Kaggle |
| Time coverage | 2026 is still incomplete before the submission deadline | Fixed full year of 2022 |
| Access | Recent FIRMS files are public; archive downloads require an Earthdata login or API key | Kaggle account or API access may be required, but the historical file is stable |
| Study-area work | Select and justify one Kalimantan regency; inspect Indonesian boundary compatibility | Filter six ADM1 provinces that form Bangkok and its vicinities |
| Observation process | Satellite revisit, cloud or smoke effects, sensor confidence, and repeated detections can complicate the point definition | Reporting practice, coordinate quality, duplicated reports, and uneven traffic exposure remain material |
| First-order scope | Strong seasonal and spatial intensity questions | Strong time-of-day, monthly, severity, and spatial intensity questions |
| Second-order scope | Possible clustering at fire-spread or land-use scales, but repeated detections must be resolved | Possible clustering relative to CSR or an inhomogeneous null; road-network support needs careful treatment |
| Main reproducibility risk | Moving end date and archive access | Third-party hosting and the need to document the original data owner and licence |
| Bonus potential | Sensor comparison, confidence sensitivity, or space-time interaction | Inhomogeneous or network-aware comparison, temporal permutation, or severity-mark analysis |

## Proposed Option B scope

- **Events:** valid 2022 accident records with coordinates inside the study boundary. The exact event definition must follow the downloaded file's identifiers and metadata.
- **Boundary:** Bangkok, Samut Prakan, Nonthaburi, Pathum Thani, Nakhon Pathom, and Samut Sakhon.
- **Boundary source:** geoBoundaries ADM1 or another documented provincial boundary source with a compatible licence.
- **Official area definition:** Thailand's National Statistical Office lists the same six provinces under Bangkok and Metropolitan/Bangkok and Vicinities.
- **Exposure caveat:** event density is not accident risk unless traffic volume, road length, population at risk, or another suitable denominator is incorporated.

## Source record

- Exercise brief: <https://isss626-ay2026-27aug.netlify.app/take-home_ex01>
- Thailand Road Accident 2019–2022: <https://www.kaggle.com/datasets/thaweewatboy/thailand-road-accident-2019-2022>
- Thailand Road Accident Fatalities 2024: <https://www.kaggle.com/datasets/pornsakkamchan/thailand-road-accident-fatalities-2024>
- NASA FIRMS active-fire downloads: <https://firms.modaps.eosdis.nasa.gov/download/>
- geoBoundaries downloads: <https://www.geoboundaries.org/globalDownloads.html>
- National Statistical Office definition of Bangkok and Metropolitan, page 16: <https://www.nso.go.th/nsoweb/storage/survey_detail/2026/20241211125403_33653.pdf>

## Decision gates before analysis

1. Download and inspect the actual event file rather than relying on the Kaggle summary.
2. Confirm that 2022 records, coordinates, identifiers, and relevant fields match the proposed scope.
3. Record the file name, checksum, access date, row count, licence, and data owner.
4. Check whether the reported points are precise crash locations, approximate locations, or reporting locations.
5. Decide whether Euclidean point-pattern methods are defensible for events generated on a road network.
6. If the audit fails, reconsider Option A or narrow the research question before writing results.
