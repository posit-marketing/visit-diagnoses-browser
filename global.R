# Packages ----------------------------------------------------------------

library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(ggplot2)
library(showtext)
library(purrr)
library(janitor)
library(plotly)
library(gt)

showtext::showtext_auto()
sysfonts::font_add_google("DM Sans", "dm-sans")

# Data --------------------------------------------------------------------

con <-
  DBI::dbConnect(odbc::databricks(),
                 httpPath = "/sql/1.0/warehouses/300bd24ba12adf8e")

encounters <-
  dplyr::tbl(con,
             dbplyr::in_catalog("hive_metastore", "default", "encounters")) |>
  dplyr::select(Id, PATIENT, REASONDESCRIPTION) |>
  dplyr::filter(!is.na(REASONDESCRIPTION),
                REASONDESCRIPTION != "Normal pregnancy")

patients <-
  dplyr::tbl(con,
             dbplyr::in_catalog("hive_metastore", "default", "patients")) |>
  dplyr::select(Id, BIRTHDATE, RACE, GENDER)

join_dat <-
  dplyr::inner_join(encounters, patients, join_by(PATIENT == Id))

all_dat <-
  join_dat |>
  dplyr::collect() |>
  janitor::clean_names() |>
  dplyr::mutate(
    reasondescription = stringr::str_remove(reasondescription, "\\(disorder\\)"),
    reasondescription = stringr::str_wrap(reasondescription, 25),
    birthdate = as.Date(birthdate),
    age = lubridate::year(lubridate::as.period(
      lubridate::interval(start = birthdate, end = Sys.Date())
    ))
  )

race_select <-
  c("white", "hispanic", "black", "asian", "native", "other")

comorbidities <-
  c(
    "Hyperlipidemia",
    "Anemia",
    "Sinusitis"
  )