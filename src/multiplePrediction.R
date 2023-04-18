library(PatientLevelPrediction)
library(FeatureExtraction)
#library(OhdsiShinyModules)

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
  
  useDrugEraMediumTerm = TRUE,
  useDrugGroupEraMediumTerm = TRUE,
  useConditionEraMediumTerm = TRUE,
  
  useDistinctConditionCountMediumTerm = TRUE,
  useDistinctProcedureCountMediumTerm = TRUE,
  useDistinctIngredientCountMediumTerm = TRUE,
  useDistinctMeasurementCountMediumTerm = TRUE,
  
  useDrugEraStartShortTerm = TRUE,
  useDrugExposureShortTerm = TRUE,
  useDistinctIngredientCountShortTerm = TRUE,
  
  mediumTermStartDays = -180,
  shortTermStartDays = -30,
  endDays = 0,
)

relevantCovariateSettings <- covariateSettings
relevantCovariateSettings$includedCovariateConceptIds = as.vector(scan(file = config$run$feature_selection_output, what = numeric(), sep = "\n"))

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

preprocessSettings = createPreprocessSettings(minFraction = 0.00001, normalize = TRUE, removeRedundancy = FALSE)

getModelDesignList <- function(){
  
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
  
  modelDesignLRwithFS <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = preprocessSettings,
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
  
  modelDesignRFwithFS <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = preprocessSettings,
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
  
  modelDesignGBwithFS <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = preprocessSettings,
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
    covariateSettings = covariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setAdaBoost(
      nEstimators = list(50),
      learningRate = list(1)
    )
  )
  
  modelDesignABwithFS <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = preprocessSettings,
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
    covariateSettings = covariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = createPreprocessSettings(),
    modelSettings = setNaiveBayes()
  )
  
  modelDesignNBwithFS <- createModelDesign(
    targetId = config$cdm$target_cohort_id,
    outcomeId = config$cdm$outcome_cohort_id,
    restrictPlpDataSettings = createRestrictPlpDataSettings(),
    populationSettings = populationSettings,
    covariateSettings = relevantCovariateSettings,
    featureEngineeringSettings = createFeatureEngineeringSettings(),
    sampleSettings = sampleSettings,
    splitSettings = splitSettings,
    preprocessSettings = preprocessSettings,
    modelSettings = setNaiveBayes()
  )
  
  modelDesignList = list(modelDesignLR, modelDesignRF, modelDesignAB, modelDesignGB, modelDesignNB,
                         modelDesignLRwithFS, modelDesignRFwithFS, modelDesignABwithFS, modelDesignGBwithFS, modelDesignNBwithFS)
  names(modelDesignList) = c("LR", "RF", "AB", "GB", "NB", "LRFS", "RFFS", "ABFS", "GBFS", "NBFS")
  
  return(modelDesignList[config$run$models])
}

regenerateSqliteWithValidation <- function(saveDirectoryDev, saveDirectoryValidation){
  unlink(file.path(getwd(), config$run$plp_output_folder_name, "sqlite"), recursive = T)
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
  unlink(file.path(getwd(), config$run$plp_output_folder_name, "sqlite"), recursive = T)
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
  unlink(file.path(getwd(), config$run$plp_output_folder_name, "csv"), recursive = T)
  
  PatientLevelPrediction::extractDatabaseToCsv(
    connectionDetails = DatabaseConnector::createConnectionDetails(
      server = file.path(getwd(), config$run$plp_output_folder_name, "sqlite", "databaseFile.sqlite"), 
      dbms = "sqlite"
    ), 
    databaseSchemaSettings = PatientLevelPrediction::createDatabaseSchemaSettings(
      resultSchema = "main", 
      tablePrefix = "", 
      targetDialect = "sqlite"
    ), 
    csvFolder = file.path(getwd(), config$run$plp_output_folder_name, "csv")
  )
}


runMultiplePrediction <- function() {
  connectionDetails <- getConnectionDetails()
  databaseDetails <- getDatabaseDetails(connectionDetails)
  
  results <- runMultiplePlp(
    databaseDetails = databaseDetails,
    modelDesignList = getModelDesignList(),
    onlyFetchData = F,
    logSettings = createLogSettings(),
    saveDirectory = file.path(getwd(), config$run$plp_output_folder_name)
  )
  exportResultsToCsv()
}

runExternalValiadtion <- function(){
  connectionDetails <- getConnectionDetails()
  validationDatabaseDetailsList <- getValidationDatabaseDetails(connectionDetails)
  val <- validateMultiplePlp(
    analysesLocation = file.path(getwd(), config$run$pretrained_models_folder_name),
    validationDatabaseDetails = validationDatabaseDetailsList,
    validationRestrictPlpDataSettings = createRestrictPlpDataSettings(),
    recalibrate = "weakRecalibration"
  )
  exportResultsToCsv()
}



