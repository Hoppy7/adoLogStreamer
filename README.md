# adoLogStreamer

[![Build Status](https://dev.azure.com/hoppy7/Azure/_apis/build/status/Hoppy7.adoLogStreamer?branchName=main)](https://dev.azure.com/hoppy7/Azure/_build/latest?definitionId=12&branchName=main)

![image](https://user-images.githubusercontent.com/18079003/116765233-09106980-a9d9-11eb-8f7c-12cb1ee94c0f.png)

## Log Stream Flow
  1.  [Templates/streamLogs.yml](https://github.com/Hoppy7/adoLogStreamer/blob/main/templates/streamLogs.yml) template stage gets the pipeline definition run's current context and puts it on the storage queue
  2.  Function app triggers and processes message
  3.  Function app calls the Azure DevOps [Pipeline List Logs API](https://docs.microsoft.com/en-us/rest/api/azure/devops/pipelines/logs/list?view=azure-devops-rest-6.0) and downloads the pipeline run's logs
  4.  Function app pushes the pipeline run's logs to blob storage
