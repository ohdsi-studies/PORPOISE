library(log4r)
source("src/cohortGenerator.R")

logfile <- "output-file.log"
ca <- console_appender(layout = default_log_layout())
fa <- file_appender(logfile, layout = default_log_layout())
logger <- log4r::logger(threshold = "DEBUG", appenders= list(ca, fa))
config <- yaml::yaml.load_file('./config/config.yml')

if (is.null(config) || "run" %in% names(config) == FALSE || 
    "cdm" %in% names(config) == FALSE){
  error(logger, "Missing CDM database or run details in the config file!")
  stop("Missing CDM database details in config file!")
}


if (tolower(config$run$cohort_generator) == "yes" || 
    tolower(config$run$cohort_subgroup_generator) == "yes") {
  info(logger, "")
  info(logger, "cohort generator is running ...")
  generateCohorts(config, logger)
}

if (tolower(config$run$cdm_subset_generator) == "yes") {
  info(logger, "")
  info(logger, "CDM subset generation is running ...")
  res_time <- system.time(generateCdmSubset(config, logger))
  info(logger,
       sprintf("CDM subset was generated in %.3f seconds", res_time[3]))
}

if (tolower(config$run$external_validation) == "no") {
  if (tolower(config$run$type) == "multiple") {
    source("src/multiplePrediction.R")
    info(logger, "Multiple prediction module is running ...")
    res_time <- system.time(runMultiplePrediction(config, logger))
    info(logger,
         sprintf(
           "Multiple prediction was completed in %.3f mins",
           res_time[3] / 60
         ))
  } else if (tolower(config$run$type) == "ensemble"){
    source("src/multiplePrediction.R")
    source("src/ensembleLearning.R")
    info(logger, "Ensemble prediction module is running ...")
    res_time <- system.time(runEnsembleLearning(config, logger))
    info(logger,
         sprintf(
           "Ensemble prediction was completed in %.3f mins",
           res_time[3] / 60
         ))
  } else if (tolower(config$run$type) == "single"){
    source("src/singlePrediction.R")
    info(logger, "Single prediction module is running ...")
    res_time <-
      system.time(runSinglePrediction(config, logger, modelName = config$run$models[1], readPlpData = T))
    info(logger,
         sprintf("Ensemble prediction was completed in %.3f mins",
                 res_time[3] / 60))
  }
  
} else {
  source("src/multiplePrediction.R")
  info(logger, "")
  info(logger, "External validation module is running ...")
  res_time <- system.time(runExternalValiadtion(config, logger))
  info(logger,
       sprintf(
         "External validation was completed in %.3f mins",
         res_time[3] / 60
       ))
}
  
  