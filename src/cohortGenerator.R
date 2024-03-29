library(DatabaseConnector)
library(SqlRender)

source("src/databaseConnection.R")

createCohortQueries <- function() {
  sql <- list()
  if (tolower(config$run$cohort_generator) == "yes") {
    sql["target"] <- readSql("./sql/target-cohort.sql")
    sql["outcome"] <- readSql("./sql/outcome-cohort.sql")
  }
  
  if (tolower(config$run$cohort_subgroup_generator) == "yes") {
    sql["diabetes"] <- readSql("./sql/target-cohort-diabetes.sql")
    sql["depression"] <- readSql("./sql/target-cohort-depression.sql")
    sql["obesity"] <- readSql("./sql/target-cohort-obesity.sql")
    sql["targetNoPostCriteria"] <- readSql("./sql/target-cohort-noPostCriteria.sql")
  }
  
  cohortQueries <- list()
  for (q in names(sql)) {
    cohort_id <- config$cdm$target_cohort_id
    if (q == "outcome"){
      cohort_id <- config$cdm$outcome_cohort_id
    } else if (q == "diabetes") {
      cohort_id <- config$cdm$diabetes_cohort_id
    } else if (q == "depression") {
      cohort_id <- config$cdm$depression_cohort_id
    } else if (q == "obesity") {
      cohort_id <- config$cdm$obesity_cohort_id
    } else if (q == "targetNoPostCriteria") {
      cohort_id <- config$cdm$targetNoPostCriteria_cohort_id
    }
    
    print(paste(q, "cohort_id is", cohort_id))
    
    cohortQueries[q] = render(
      sql[[q]],
      vocabulary_database_schema = config$cdm$vocabulary_database_schema,
      cdm_database_schema = config$cdm$cdm_database_schema,
      target_database_schema = config$cdm$target_database_schema,
      target_cohort_table = config$cdm$cohort_table,
      target_cohort_id = cohort_id
    )
  }
  
  return(cohortQueries)
}

createTestCohortQuery <- function() {
  sql <- paste(
    "SELECT cohort_definition_id, COUNT(*) AS count",
    "FROM @target_database_schema.@target_cohort_table",
    "GROUP BY cohort_definition_id"
  )
  sql <- render(
    sql,
    target_database_schema = config$cdm$target_database_schema,
    target_cohort_table = config$cdm$cohort_table
  )
  
  return(sql)
}

createCohortTableQuery <- function() {
  sql <- readSql("./sql/cohort-table.sql")
  cohortQuery = render(
    sql,
    target_database_schema = config$cdm$target_database_schema,
    target_cohort_table = config$cdm$cohort_table
  )
  return(cohortQuery)
}

generateCohorts <- function() {
  print("Database connection ...")
  connectionDetails = getConnectionDetails()
  connection <- connect(connectionDetails)
  
  print("Checking cohort table in the target schema ...")
  sql <-
    translate(createCohortTableQuery(), targetDialect = connectionDetails$dbms)
  DatabaseConnector::executeSql(connection, sql)
  
  print("Cohort queries are generating ...")
  
  queries = createCohortQueries()
  
  for (cohortName in names(queries)) {
    print(cohortName)
    print(paste(cohortName, "cohort query is translating ..."))
    sql <-
      translate(queries[[cohortName]], targetDialect = connectionDetails$dbms)
    
    print(paste(cohortName, "cohort is running ..."))
    res_time <- system.time(DatabaseConnector::executeSql(connection, sql))
    sprintf(
     "%s cohort was generated in %.3f minutes.",
     cohortName,
     res_time[3] / 60
    )
  }
  
  print("Target and outcome cohorts were generated. The results are as follows:")
  testQuery <- createTestCohortQuery()
  testSql <-
    translate(testQuery, targetDialect = connectionDetails$dbms)
  testResult <- DatabaseConnector::querySql(connection, testSql)
  print(testResult)
  disconnect(connection = connection)
}


generateCdmSubset <- function(){
  cdmTables = c(
    'person',
    'observation_period',
    'condition_occurrence',
    'procedure_occurrence',
    'drug_exposure',
    'measurement',
    'condition_era',
    'drug_era'
  )
  
  print("Database connection ...")
  connectionDetails = getConnectionDetails()
  connection <- connect(connectionDetails)
  
  for (table in cdmTables) {
    sprintf("A subset of Table %s is generating ...", table)
    
    query <- "
    CREATE OR REPLACE TABLE @target_database_schema.@cdm_table AS
        SELECT 
         table_.*
        FROM
          @cdm_database_schema.@cdm_table table_    
        JOIN
          @target_database_schema.@cohort_table cohort
        ON
         table_.person_id = cohort.subject_id
        WHERE
         cohort_definition_id = @target_cohort_id
    "
    sql <- render(
      sql = query,
      cdm_database_schema = config$cdm$cdm_database_schema,
      cdm_table = table,
      target_database_schema = config$cdm$target_database_schema,
      cohort_table = config$cdm$cohort_table,
      target_cohort_id = config$cdm$target_cohort_id
    )
    sql <- translate(sql, targetDialect = connectionDetails$dbms)
    DatabaseConnector::executeSql(connection, sql)
  }
  disconnect(connection = connection)
}



