param([string] $QueueItem, $TriggerMetadata)

# get pipeline definition & run ids from message
$definitionId = $TriggerMetadata["definitionId"];
$runId = $TriggerMetadata["runId"];

# headers
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($env:azureDevOpsPat)"));
$headers = @{Authorization = "Basic $token"};

# list logs
try
{
    $listLogsUri = "https://dev.azure.com/$($env:azureDevOpsOrg)/$($env:azureDevOpsProject)/_apis/pipelines/$($definitionId)/runs/$($runId)/logs?`$expand=signedContent&api-version=6.0-preview.1";
    $listResponse = Invoke-WebRequest -Uri $listLogsUri -Method GET -Headers $headers -SkipHttpErrorCheck;
    $logs = $listResponse.Content | ConvertFrom-Json;
}
catch [exception]
{
    throw "Failed to list the pipeline run logs.  $($_)";
}

# get logs zip from signedContent url
try 
{
    $zipName = "pipeline_" + $definitionId + "-" + "run_" + $runId + ".zip";
    $outputPath = "$env:TEMP\$zipName";
    Invoke-WebRequest -Uri $logs.signedContent.url -Method GET -Headers $headers -SkipHttpErrorCheck -OutFile $outputPath;
}
catch [exception]
{
    throw "Failed to output the pipeline run's logs zip.  $($_)";
}

# push to blob
try
{
    $ctx = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage;
    Set-AzStorageBlobContent -File $outputPath -Container $env:logOutputContainer -Blob $zipName -Context $ctx -Force;
}
catch [exception]
{
    throw "Failed to upload pipeline logs zip to blob container. $($_)";
}