library(PatientLevelPrediction)
library(FeatureExtraction)
library(OhdsiShinyModules)
library(log4r)
source("src/databaseConnection.R")

covariateSettings <- createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAgeGroup = TRUE,
  useDemographicsRace = TRUE, 
  useDemographicsEthnicity = TRUE,
  
  useConditionOccurrenceMediumTerm = TRUE,
  useProcedureOccurrenceMediumTerm = TRUE,
  useDrugExposureMediumTerm = TRUE,
  useMeasurementMediumTerm = TRUE,
  
  useConditionGroupEraMediumTerm = TRUE,
  useDrugGroupEraMediumTerm = TRUE,
  
  useDistinctConditionCountMediumTerm = TRUE,
  useDistinctProcedureCountMediumTerm = TRUE,
  useDistinctIngredientCountMediumTerm = TRUE,
  useDistinctMeasurementCountMediumTerm = TRUE,
  
  mediumTermStartDays = -180,
  endDays = 0,
)

relevantCovariateSettings <- covariateSettings
relevantCovariateSettings$includedCovariateConceptIds = as.vector(scan(file = "./fs/fs-pnf", what = numeric(), sep = "\n"))

populationSettings <- createStudyPopulationSettings(
  washoutPeriod = 0,
  firstExposureOnly = FALSE,
  removeSubjectsWithPriorOutcome = FALSE,
  priorOutcomeLookback = 9999,
  riskWindowStart = 90,
  riskWindowEnd = 180,
  minTimeAtRisk = 90,
  startAnchor = 'cohort start',
  endAnchor = 'cohort start',
  requireTimeAtRisk = TRUE,
  includeAllOutcomes = TRUE
)

sampleSettings = createSampleSettings()

splitSettings = createDefaultSplitSetting(
  testFraction = 0.20,
  trainFraction = 0.80,
  nfold = 5,
  type = "stratified",
  splitSeed = 13
)

getModelDesignList <- function(config){
  
  modelDesignLR <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = covariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setLassoLogisticRegression()
  )
  
  modelDesignRF <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = covariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setRandomForest(
      ntrees = list(500),
      criterion = list("gini"),
      maxDepth = list(17),
      minSamplesSplit = list(2),
      minSamplesLeaf = list(1),
      minWeightFractionLeaf = list(0),
      mtries = list("auto"),
      maxLeafNodes = list(NULL),
      minImpurityDecrease = list(0),
      bootstrap = list(TRUE),
      maxSamples = list(NULL),
      oobScore = list(FALSE),
      nJobs = list(NULL),
      classWeight = list(NULL),
      seed = 13
    )
  )
  
  modelDesignGB <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = covariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setGradientBoostingMachine(
      ntrees = c(300),
      nthread = 20,
      earlyStopRound = 25,
      maxDepth = c(4),
      minChildWeight = 1,
      learnRate = c(0.1),
      scalePosWeight = 1,
      lambda = 1,
      alpha = 0,
      seed = 13
    )
  )
  
  modelDesignAB <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setAdaBoost(
      nEstimators = list(50),
      learningRate = list(1)
    )
  )
  
  modelDesignNB <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setNaiveBayes()
  )
  
  modelDesignList = list(modelDesignLR, modelDesignRF, modelDesignAB, modelDesignGB, modelDesignNB)
  names(modelDesignList) = c("LR", "RF", "AB", "GB", "NB")
  
  return(modelDesignList[config$run$models])
}

regenerateSqliteWithValidation <- function(saveDirectoryDev, saveDirectoryValidation){
  unlink(file.path(getwd(), "PlpMultiOutput", "sqlite"), recursive = T)
  sqliteLocation <- file.path(saveDirectoryDev, 'sqlite')
  insertResultsToSqlite(
    resultLocation = saveDirectoryDev,
    cohortDefinitions = NULL,
    databaseList = PatientLevelPrediction::createDatabaseList(
      cdmDatabaseSchemas = c(saveDirectoryDev, saveDirectoryValidation)
    ),
    sqliteLocation = sqliteLocation
  )
}

regenerateSqlite <- function(saveDirectoryDev){
  unlink(file.path(getwd(), "PlpMultiOutput", "sqlite"), recursive = T)
  sqliteLocation <- file.path(saveDirectoryDev, 'sqlite')
  insertResultsToSqlite(
    resultLocation = saveDirectoryDev,
    cohortDefinitions = NULL,
    databaseList = PatientLevelPrediction::createDatabaseList(
      cdmDatabaseSchemas = NULL
    ),
    sqliteLocation = sqliteLocation
  )
}


exportResultsToCsv <- function(){
  unlink(file.path(getwd(), "PlpMultiOutput", "csv"), recursive = T)
  
  PatientLevelPrediction::extractDatabaseToCsv(
    connectionDetails = DatabaseConnector::createConnectionDetails(
      server = file.path(getwd(), "PlpMultiOutput", "sqlite", "databaseFile.sqlite"), 
      dbms = "sqlite"
    ), 
    databaseSchemaSettings = PatientLevelPrediction::createDatabaseSchemaSettings(
      resultSchema = "main", 
      tablePrefix = "", 
      targetDialect = "sqlite"
    ), 
    csvFolder = file.path(getwd(), "PlpMultiOutput", "csv")
  )
}



runMultiplePrediction <- function(config, logger) {
  connectionDetails <- getConnectionDetails(config, logger)
  databaseDetails <- getDatabaseDetails(connectionDetails, config, logger)
  
  results <- runMultiplePlp(
    databaseDetails = databaseDetails,
    modelDesignList = getModelDesignList(config),
    onlyFetchData = F,
    logSettings = createLogSettings(),
    saveDirectory = file.path(getwd(), "PlpMultiOutput")
  )
  
  exportResultsToCsv()
}

runExternalValiadtion <- function(config, logger){
  connectionDetails <- getConnectionDetails(config, logger)
  validationDatabaseDetailsList <- getValidationDatabaseDetails(connectionDetails, config, logger)
  val <- validateMultiplePlp(
    analysesLocation = file.path(getwd(), "PlpMultiOutput"),
    validationDatabaseDetails = validationDatabaseDetailsList,
    validationRestrictPlpDataSettings = createRestrictPlpDataSettings(),
    recalibrate = NULL
  )

  exportResultsToCsv()
}



