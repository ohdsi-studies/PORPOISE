source("src/multiplePrediction.R")

# Set the path to the targetId_1_L1 folder obtained from running logistic regression with all covariates.
plpDataFolder <- file.path(getwd(), "PlpMultiOutput-LR", "targetId_1_L1")

config <- yaml::yaml.load_file('./config/config.yml')

createSplitData <- function(){
  if (dir.exists(plpDataFolder)){
    plpData <- loadPlpData(plpDataFolder)
    population <- createStudyPopulation(plpData = plpData, 
                                        outcomeId = config$cdm$outcome_cohort_id, 
                                        populationSettings = populationSettings, 
                                        population = plpData$population)
    data <- splitData(plpData = plpData, population = population, splitSettings = splitSettings)
    return(data$Train)
  }
}

createTestSetCohorts <- function(){
  trainData <- createSplitData()
  
  connectionDetails = getConnectionDetails()
  connection <- connect(connectionDetails)
  
  sqlQuery <- readSql("./sql/test-cohorts.sql")
  evaluation_cohorts <- c(config$cdm$target_cohort_id, config$cdm$diabetes_cohort_id, config$cdm$depression_cohort_id, config$cdm$obesity_cohort_id, config$cdm$targetNoPostCriteria_cohort_id)
  for (cohort_id in evaluation_cohorts){
    sql <- render(
      sqlQuery,
      target_database_schema = config$cdm$target_database_schema,
      target_cohort_table = config$cdm$cohort_table,
      target_cohort_id = cohort_id,
      test_cohort_id = cohort_id * 10,
      train_subject_ids = paste(trainData$labels$subjectId,collapse = ',')
    )
    print(paste("Test cohort id",cohort_id * 10, "is created for target cohort id", cohort_id))
    sql <- translate(sql, targetDialect = connectionDetails$dbms)
    DatabaseConnector::executeSql(connection, sql)
  }
}


createTestSetCohorts()


