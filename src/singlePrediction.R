library(PatientLevelPrediction)
library(FeatureExtraction)
source("src/databaseConnection.R")

getModel <- function(modelName = 'LR') {
  if (modelName == "LR") {
    return (setLassoLogisticRegression())
  } else if (modelName == "RF") {
    return (
      setRandomForest(
        ntrees = list(500),
        criterion = list("gini"),
        maxDepth = list(17),
        minSamplesSplit = list(2),
        minSamplesLeaf = list(1),
        minWeightFractionLeaf = list(0),
        mtries = list("sqrt"),
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
  } else if (modelName == "SVM") {
    return (
      setSVM(
        C = list(1),
        kernel = list("linear"),
        degree = list(1),
        gamma = list("scale"),
        coef0 = list(0),
        shrinking = list(TRUE),
        tol = list(0.001),
        classWeight = list(NULL),
        cacheSize = 500,
        seed = 13
      )
    )
  } else if (modelName == "GB") {
    return (
      setGradientBoostingMachine(
        ntrees = c(300),
        nthread = 20,
        earlyStopRound = 25,
        maxDepth = c(8),
        minChildWeight = 1,
        learnRate = c(0.1),
        scalePosWeight = 1,
        lambda = 1,
        alpha = 0,
        seed = 13
      )
    )
  } else if (modelName == "NB") {
    return (setNaiveBayes())
  } else if (modelName == "AB") {
    return (return (setAdaBoost(
      nEstimators = list(50),
      learningRate = list(1)
    )))
  } else {
    return (NULL)
  }
}

runSinglePrediction <-
  function(config,
           logger,
           modelName = 'LR',
           readPlpData = T) {
    
    connectionDetails <- getConnectionDetails(config, logger)
    databaseDetails <-
      getDatabaseDetails(connectionDetails, config, logger)
    
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
      endDays = 0
    )
    
    if(modelName == "NB"){
      info(logger = logger, "Top relevant features are used in th feature extraction")
      covariateSettings$includedCovariateConceptIds = as.vector(scan(file = "./fs/fs-pnf", what = numeric(), sep = "\n"))
    }
    
    if (readPlpData) {
      info(logger = logger, "PLP data is loaded ...")
      plpData <- loadPlpData("./singleOutput/plpData")
    } else {
      info(logger = logger, "PLP data is generated ...")
      plpData <- getPlpData(
        databaseDetails = databaseDetails,
        covariateSettings = covariateSettings,
        restrictPlpDataSettings = createRestrictPlpDataSettings()
      )
      savePlpData(plpData, "./singleOutput/plpData")
    }
    
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
    
    
    splitSettings <- createDefaultSplitSetting(
      trainFraction = 0.80,
      testFraction = 0.20,
      type = 'stratified',
      nfold = 5,
      splitSeed = 13
    )
    
    
    preprocessSettings <- createPreprocessSettings(
      minFraction = 0.001,
      normalize = T,
      removeRedundancy = T
    )
    
    if(modelName == "NB"){
      info(logger = logger, "Min Fraction was set to 0.00001 for Naive Bayes")
      preprocessSettings$minFraction = 0.0001
    }
    
    executeSettings <- createExecuteSettings(
      runSplitData = T,
      runSampleData = T,
      runfeatureEngineering = T,
      runPreprocessData = T,
      runModelDevelopment = T,
      runCovariateSummary = T
    )
    
    plpResult <- runPlp(
      plpData = plpData,
      outcomeId = config$cdm$outcome_cohort_id,
      analysisId = modelName,
      analysisName = 'PORPOISE',
      populationSettings = populationSettings,
      splitSettings = splitSettings,
      sampleSettings = createSampleSettings(),
      featureEngineeringSettings = createFeatureEngineeringSettings(),
      preprocessSettings = preprocessSettings,
      modelSettings = getModel(modelName),
      logSettings = createLogSettings(),
      executeSettings = executeSettings,
      saveDirectory = "singleOutput"
    )
    plotPlp(plpResult = plpResult,
            saveLocation = file.path("singleOutput", modelName, "plots"))
    return (plpResult)
  }
