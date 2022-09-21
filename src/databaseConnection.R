library(BQJdbcConnectionStringR)
library(DatabaseConnector)
library(SqlRender)
library(log4r)
library(yaml)

getBqConnectionDetails <- function(config){
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


getDbConnectionDetails <- function(config){
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=config$db$dbms,
                                                                  server = config$db$server,
                                                                  port = config$db$port,
                                                                  user=config$db$user,
                                                                  password=config$db$password,
                                                                  pathToDriver = config$db$driverPath)
  return(connectionDetails)
}


getConnectionDetails <- function(config, logger) {
  if ("bq" %in% names(config) &&
      "credentials" %in% names(config$bq)) {
    return(getBqConnectionDetails(config))
  } else if ("db" %in% names(config) &&
             "dbms" %in% names(config$db)) {
    return(getDbConnectionDetails(config))
  } else{
    if (!is.null(logger))
      error(logger = logger, "Missing db configuration!")
    
    stop("Missing db configuration!")
  }
}

getDatabaseDetails <- function(connectionDetails, config, logger){
  if ("cdm" %in% names(config) == FALSE ||
      "target_database_schema" %in% names(config$cdm) == FALSE || 
      "cohort_table" %in% names(config$cdm) == FALSE) {
    if (is.null(logger) == FALSE){
      error(logger, "Missing CDM database details in config file!")
    }
    stop("Missing CDM database details in config file!")
  }
  
  databaseDetails <- createDatabaseDetails(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = config$cdm$cdm_database_schema,
    cdmDatabaseName = config$cdm$cdm_database_name,
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

getValidationDatabaseDetails <- function(connectionDetails, config, logger){
  if ("cdm" %in% names(config) == FALSE ||
      "target_database_schema" %in% names(config$cdm) == FALSE || 
      "cohort_table" %in% names(config$cdm) == FALSE) {
    if (is.null(logger) == FALSE){
      error(logger, "Missing CDM database details in config file!")
    }
    stop("Missing CDM database details in config file!")
  }
  
  validationCohortNames <- list("-target-cohort-id-")
  names(validationCohortNames) = c(config$cdm$target_cohort_id)
  
  validationCohortIds <- c(config$cdm$target_cohort_id)
  if (tolower(config$run$validation_subgroup) == "yes"){
    validationCohortIds <- c(validationCohortIds, config$cdm$diabetes_cohort_id)
    validationCohortIds <- c(validationCohortIds, config$cdm$depression_cohort_id)
    validationCohortIds <- c(validationCohortIds, config$cdm$obesity_cohort_id)
    
    validationCohortNames <- list("-target-cohort-id-", "-diabetes-cohort-id-", "-depression-cohort-id-", "-obesity-cohort-id-")
    names(validationCohortNames) = c(config$cdm$target_cohort_id, config$cdm$diabetes_cohort_id, config$cdm$depression_cohort_id, config$cdm$obesity_cohort_id)
  }
  
  databaseDetailsList <- list()
  for (cohortId in validationCohortIds){
    databaseDetails <- createDatabaseDetails(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = config$cdm$cdm_database_schema,
      cdmDatabaseName = config$cdm$cdm_database_name,
      cohortDatabaseSchema = config$cdm$target_database_schema,
      cohortTable = config$cdm$cohort_table,
      outcomeDatabaseSchema = config$cdm$target_database_schema,
      outcomeTable = config$cdm$cohort_table,
      targetId = cohortId,
      outcomeIds = config$cdm$outcome_cohort_id,
      cdmVersion = 5,
      databaseDetailsName = paste0(config$cdm$cdm_database_name, validationCohortNames[as.character(cohortId)], cohortId)
    )
    databaseDetailsList[[length(databaseDetailsList) + 1]] <- databaseDetails
  }

  class(databaseDetailsList) <- "list"
  return(databaseDetailsList)
}

