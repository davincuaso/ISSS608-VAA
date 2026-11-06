# Dataset Licenses

The source of each station coordinate is indicated in the `source` field. Coordinates with `source` marked as `manual` are manual estimates.

The operational-station file began with [Singapore Train Station Coordinates](https://github.com/elliotwutingfeng/singapore_train_station_coordinates) at commit `9f5972c71db8a529801eee9c527946a45a78e409` (5 March 2026). For the September 2026 analysis, Keppel, Cantonment and Prince Edward Road were added as centroids of the corresponding station polygons in LTA's Train Station geospatial layer downloaded through DataMall on 6 November 2026. Bayfront and Marina Bay were updated from the older `CE1`/`CE2` codes to `CC34`/`CC33`. These changes reconcile the station list with the September OD extract; polygon centroids are not station entrances.

- Contains information from the Land Transport Authority accessed via the LTA DataMall API which is made available under the terms of the Singapore Open Data Licence version 1.0 <https://datamall.lta.gov.sg/content/datamall/en/SingaporeOpenDataLicence.html>.
- Contains information from the Urban Redevelopment Authority accessed via the data.gov.sg API which is made available under the terms of the Singapore Open Data Licence version 1.0 <https://data.gov.sg/open-data-licence>.
