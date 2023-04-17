source("src/cohortGenerator.R")

config <- yaml::yaml.load_file('./config/config.yml')

if (is.null(config) || "run" %in% names(config) == FALSE || 
    "cdm" %in% names(config) == FALSE){
  stop("Missing CDM database details in config file!")
}


if (tolower(config$run$cohort_generator) == "yes" || 
    tolower(config$run$cohort_subgroup_generator) == "yes") {
  print("cohort generator is running ...")
  generateCohorts()
}

if (tolower(config$run$cdm_subset_generator) == "yes") {
  print("CDM subset generation is running ...")
  res_time <- system.time(generateCdmSubset())
  sprintf("CDM subset was generated in %.3f seconds", res_time[3])
}

if (tolower(config$run$external_validation) == "no") {
  if (tolower(config$run$type) == "multiple") {
    source("src/multiplePrediction.R")
    print("Multiple prediction module is running ...")
    res_time <- system.time(runMultiplePrediction())
    sprintf(
     "Multiple prediction was completed in %.3f mins",
     res_time[3] / 60
   )
  }
  
} else if (tolower(config$run$external_validation) == "yes") {
  source("src/multiplePrediction.R")
  print("External validation module is running ...")
  res_time <- system.time(runExternalValiadtion())
  sprintf(
   "External validation was completed in %.3f mins",
   res_time[3] / 60
  )
}
  
  