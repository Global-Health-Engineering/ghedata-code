# Research Collection


``` r
library(tidyverse)
library(ggthemes)
library(kableExtra)

overview  <- read_csv("raw-data/ghe-research-collection.csv")
monthly_visits  <- read_csv("raw-data/monthly_visits.csv") |> 
    mutate(date = parse_date_time(month, orders = "my"))
```

### Overview

``` r
paste0("Total publications: ", nrow(overview))
```

    [1] "Total publications: 119"

``` r
overview |> 
    group_by(publication_type) |> 
    count() |> 
    arrange(desc(n)) |>  
    kable(format = "html")
```

<div>

| publication_type      |   n |
|:----------------------|----:|
| Journal Article       |  39 |
| Master Thesis         |  22 |
| Bachelor Thesis       |  17 |
| Student Paper         |  17 |
| Dataset               |   5 |
| Other Research Data   |   5 |
| Report                |   5 |
| Other Publication     |   2 |
| Book Chapter          |   1 |
| Conference Poster     |   1 |
| Data Collection       |   1 |
| Model                 |   1 |
| Other Conference Item |   1 |
| Review Article        |   1 |
| Working Paper         |   1 |

</div>

### Number of publications

``` r
overview |> 
    group_by(year) |> 
    count() |> 
    ggplot(aes(x = year, y = n, label = n)) +
    geom_col() +
    geom_label() +
    labs(x = "",
    y = "Publications\n") +
        theme_few()
```

![](analysis_files/figure-commonmark/unnamed-chunk-3-1.png)

### Publication Types (absolute numbers)

``` r
overview |> 
    group_by(year, publication_type_group) |> 
    count() |> 
    ggplot(aes(x = year, y = n, fill = publication_type_group)) +
    geom_col(position = "stack") +
    labs(x = "",
    y = "Publications\n",
    fill = "Publication Type") +
        theme_few()
```

![](analysis_files/figure-commonmark/unnamed-chunk-4-1.png)

### Publication Types (relative numbers)

``` r
overview |> 
    group_by(year, publication_type_group) |> 
    count() |> 
    group_by(year) |> 
    mutate(rel_freq = n/sum(n))  |> 
    ggplot(aes(x = year, y = rel_freq, fill = publication_type_group)) +
    geom_col(position = "stack") +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(x = "",
    y = "Share\n",
    fill = "Publication Type") +
        theme_few()
```

![](analysis_files/figure-commonmark/unnamed-chunk-5-1.png)

### Licenses

``` r
overview |> 
    group_by(year, license_short_group) |> 
    count() |> 
    ggplot(aes(x = year, y = n, fill = license_short_group)) +
    geom_col(position = "stack") +
    labs(x = "",
    y = "Publications\n",
    fill = "Publication Type") +
        theme_few()
```

![](analysis_files/figure-commonmark/unnamed-chunk-6-1.png)

### DOIs

``` r
overview |> 
    group_by(year, doi_dummy) |> 
    count() |> 
    group_by(year) |> 
    mutate(rel_freq = n/sum(n))  |> 
    ggplot(aes(x = year, y = rel_freq, fill = doi_dummy)) +
    geom_col(position = "stack") +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(x = "",
    y = "Publications\n",
    fill = "Publication Type") +
        theme_few()
```

![](analysis_files/figure-commonmark/unnamed-chunk-7-1.png)

### Visits: Top 10

``` r
monthly_visits |> 
    group_by(title) |> 
    summarize(total_visits = sum(visits)) |> 
    arrange(desc(total_visits)) |> 
    slice_max(n = 10, order_by = total_visits) |> 
    kable(format = "html")
```

<div>

| title                                                                                                  | total_visits |
|:-------------------------------------------------------------------------------------------------------|-------------:|
| Land use in the Seychelles – Rethinking the Sustainability of Tourism                                  |          215 |
| Air quality monitoring from open waste and incinerator burning in Cape Maclear, Malawi                 |          181 |
| Plastic separation - A review                                                                          |          171 |
| Construction of a Glass Crusher and Evaluation of Waste Valorization Pathways for Cape Maclear, Malawi |          127 |
| Transforming Waste into Value: A Study on PET Recycling for Insulation Solutions in Malawi             |          116 |
| Design of an HDPE bottle collection and pre-cleaning system for recycling in Blantyre, Malawi          |          113 |
| Development of a Low-Cost Incinerator in Cape Maclear, Malawi                                          |          101 |
| Microcontroller Based Particulate Matter Monitors Utilising the Alphasense OPC-N3                      |          101 |
| Exploring Injection Molding for the Development of a Sensor Casings in Biogas Monitoring System        |           98 |
| Tipping aid for loading small trucks on waste collection tours                                         |           97 |

</div>

### Visits: Individual items

``` r
monthly_visits |> 
    filter(title == "Life cycle assessment of household biogas digesters: A preliminary study on emissions and system interdependencies") |> 
    ggplot(aes(x = date, y = visits)) +
    geom_col() +
    scale_x_date(date_labels = "%b %y",
        date_breaks = "1 month") +
    labs(x = "",
    y = "Visits\n",
    title = "Life cycle assessment of household biogas digesters: A preliminary study on emissions and system interdependencies") +
        theme_few()
```

![](analysis_files/figure-commonmark/unnamed-chunk-9-1.png)
