
# Before running, please check that the target cohort id and other CDM parameters have been correctly set in the config.yml
# Characterization is performed on the target cohort.

config <- yaml::yaml.load_file('./config/config.yml')
source("src/multiplePrediction.R")

connectionDetails <- getConnectionDetails()

covariateSettings <- createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAgeGroup = TRUE,
  useDemographicsRace = TRUE, 
  useDemographicsEthnicity = TRUE,
  
  useDrugGroupEraLongTerm = TRUE,
  useConditionGroupEraLongTerm = TRUE,
  
  longTermStartDays = -180,
  endDays = 0,
)

covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                      oracleTempSchema = config$cdm$target_database_schema,
                                      cdmDatabaseSchema = config$cdm$cdm_database_schema,
                                      cohortDatabaseSchema = config$cdm$target_database_schema,
                                      cohortTable = config$cdm$cohort_table,
                                      cohortId = config$cdm$target_cohort_id,
                                      covariateSettings = covariateSettings,
                                      aggregated = TRUE)

result <- createTable1(covariateData)
write.csv(result, file = './fs/table1.csv')



