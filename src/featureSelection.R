library(reticulate)
source_python("fs/feature_evaluation.py")


lrRdsPath <- "./PlpMultiOutput/Analysis_1/plpResult/runPlp.rds"
lrRDS <- readRDS(lrRdsPath)

covariate_summary_csv <- './fs/allCovariateSummary.csv'
write.csv(lrRDS$covariateSummary, covariate_summary_csv)

# It creates all concept ids selected from all domains using PNF metric  
run_feature_selection(covariate_summary_csv = covariate_summary_csv, output_dir = './fs', fs_file_name = 'fs-pnf')
