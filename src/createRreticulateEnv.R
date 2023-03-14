env_name <- 'r-reticulate'
reticulate::conda_create(envname = env_name, python_version = "3.8")

packages <- c("numpy", "scipy=1.8.0", "scikit-learn=1.0.2", "pandas", "pydotplus", "joblib=1.1.0", "sklearn-json=0.1.0")

reticulate::conda_install(envname = 'r-reticulate', packages = packages, 
                          forge = TRUE, pip = FALSE, pip_ignore_installed = TRUE, 
                          conda = "auto")