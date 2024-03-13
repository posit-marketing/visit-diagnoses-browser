# Packages ----------------------------------------------------------------

library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(ggplot2)
library(showtext)
library(dbplot)

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
                REASONDESCRIPTION != "Normal pregnancy") |>
  dplyr::collect()

encounters <-
  encounters |>
  distinct(PATIENT, REASONDESCRIPTION) |> 
  dplyr::mutate(
    REASONDESCRIPTION = stringr::str_remove(REASONDESCRIPTION, "\\(disorder\\)"),
    REASONDESCRIPTION = stringr::str_wrap(REASONDESCRIPTION, 11)
  )

comorbidities <-
  c(
    "Asthma",
    "Pulmonary emphysema",
    "Chronic congestive heart failure",
    "Chronic obstructive bronchitis"
  )
