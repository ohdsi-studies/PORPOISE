library(EnsemblePatientLevelPrediction)
source("src/databaseConnection.R")
source("src/multiplePrediction.R")

runEnsembleLearning <- function(configObj, loggerObj){
  filterSettings <- list(
    metric = 'AUROC',
    evaluation = 'CV',
    minValue = 0.2,
    maxValue = 1
  )
  combinerSettings1 <- createFusionCombiner(
    type = 'uniform',
    scaleFunction = 'normalize'
  )
  combinerSettings2 <- createStackerCombiner(
    levelTwoType = 'logisticRegressionStacker',
    levelTwoDataSettings = list(type = 'CV')
  )
  combinerSettings3 <- createStackerCombiner(
    levelTwoType = 'logisticRegressionStacker',
    levelTwoDataSettings = list(
      type = 'Test',
      proportion = 0.5
    )
  )
  
  connectionDetails <- getConnectionDetails(configObj, loggerObj)
  databaseDetails <- getDatabaseDetails(connectionDetails, configObj, loggerObj)
  
  ensembleSettings <- setEnsembleFromDesign(
    modelDesignList = getModelDesignList(config),
    databaseDetails = databaseDetails,
    #splitSettings = splitSettings,
    filterSettings = filterSettings,
    combinerSettings = combinerSettings1
  )
  
  ensemble <- runEnsemble(
    ensembleSettings = ensembleSettings,
    saveDirectory = './EnsembleOutput'
  )
}

