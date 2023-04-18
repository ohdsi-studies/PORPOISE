library(DatabaseConnector)
library(SqlRender)

getBqConnectionDetails <- function(){
  library(BQJdbcConnectionStringR)
  connectionString <- createBQConnectionString(projectId = config$bq$projectId,
                                               defaultDataset = config$bq$defaultDataset,
                                               authType = 2,
                                               jsonCredentialsPath = config$bq$credentials)
  
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms="bigquery",
                                                                  connectionString=connectionString,
                                                                  user="",
                                                                  password='',
                                                                  pathToDriver = config$bq$driverPath)
  return(connectionDetails)
}


getDbConnectionDetails <- function(){
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=config$db$dbms,
                                                                  server = config$db$server,
                                                                  port = config$db$port,
                                                                  user=config$db$user,
                                                                  password=config$db$password,
                                                                  pathToDriver = config$db$driverPath)
  return(connectionDetails)
}


getConnectionDetails <- function() {
  if ("bq" %in% names(config) &&
      "credentials" %in% names(config$bq)) {
    return(getBqConnectionDetails())
  } else if ("db" %in% names(config) &&
             "dbms" %in% names(config$db)) {
    return(getDbConnectionDetails())
  } else{
    stop("Missing db configuration!")
  }
}

getDatabaseDetails <- function(connectionDetails){
  if ("cdm" %in% names(config) == FALSE ||
      "target_database_schema" %in% names(config$cdm) == FALSE || 
      "cohort_table" %in% names(config$cdm) == FALSE) {
    stop("Missing CDM database details in config file!")
  }
  
  databaseDetails <- createDatabaseDetails(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = config$cdm$cdm_database_schema,
    cdmDatabaseName = config$cdm$cdm_database_name,
    cdmDatabaseId = config$cdm$cdm_database_name,
    tempEmulationSchema = config$cdm$target_database_schema,
    cohortDatabaseSchema = config$cdm$target_database_schema,
    cohortTable = config$cdm$cohort_table,
    outcomeDatabaseSchema = config$cdm$target_database_schema,
    outcomeTable = config$cdm$cohort_table,
    targetId = config$cdm$target_cohort_id,
    outcomeIds = config$cdm$outcome_cohort_id,
    cdmVersion = 5
  )
  
  return(databaseDetails)
}

getValidationDatabaseDetails <- function(connectionDetails){
  if ("cdm" %in% names(config) == FALSE ||
      "target_database_schema" %in% names(config$cdm) == FALSE || 
      "cohort_table" %in% names(config$cdm) == FALSE) {

    stop("Missing CDM database details in config file!")
  }
  test_suffix = ''
  if (tolower(config$run$only_validation_test_set) == "yes"){
    config$cdm$target_cohort_id <- config$cdm$target_cohort_id * 10
    config$cdm$diabetes_cohort_id <- config$cdm$diabetes_cohort_id * 10
    config$cdm$depression_cohort_id <- config$cdm$depression_cohort_id * 10
    config$cdm$obesity_cohort_id <- config$cdm$obesity_cohort_id * 10
    config$cdm$targetNoPostCriteria_cohort_id <- config$cdm$targetNoPostCriteria_cohort_id * 10
    test_suffix <- "testset-"
  }
  
  validationCohortNames <- list()
  validationCohortNames[[as.character(config$cdm$target_cohort_id)]] <- paste0("-target-cohort-", test_suffix)
  
  if (tolower(config$run$validation_subgroup) == "yes"){
    validationCohortNames[[as.character(config$cdm$diabetes_cohort_id)]] <- paste0("-diabetes-cohort-", test_suffix)
    validationCohortNames[[as.character(config$cdm$depression_cohort_id)]] <- paste0("-depression-cohort-", test_suffix)
    validationCohortNames[[as.character(config$cdm$obesity_cohort_id)]] <- paste0("-obesity-cohort-", test_suffix)
  }
  
  if (tolower(config$run$validation_noPostCriteria) == "yes"){
    validationCohortNames[[as.character(config$cdm$targetNoPostCriteria_cohort_id)]] <- paste0("-noPostCriteria-cohort-", test_suffix)
  }
  
  databaseDetailsList <- list()
  for (cohortId in names(validationCohortNames)){
    databaseDetails <- createDatabaseDetails(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = config$cdm$cdm_database_schema,
      cdmDatabaseName = paste0(config$cdm$cdm_database_name, validationCohortNames[[cohortId]], cohortId),
      cdmDatabaseId = paste0(config$cdm$cdm_database_name, validationCohortNames[[cohortId]], cohortId),
      tempEmulationSchema = config$cdm$target_database_schema,
      cohortDatabaseSchema = config$cdm$target_database_schema,
      cohortTable = config$cdm$cohort_table,
      outcomeDatabaseSchema = config$cdm$target_database_schema,
      outcomeTable = config$cdm$cohort_table,
      targetId = as.integer(cohortId),
      outcomeIds = config$cdm$outcome_cohort_id,
      cdmVersion = 5
    )
    databaseDetailsList[[length(databaseDetailsList) + 1]] <- databaseDetails
  }
 
  config <- yaml::yaml.load_file('./config/config.yml')
  class(databaseDetailsList) <- "list"
  return(databaseDetailsList)
}

