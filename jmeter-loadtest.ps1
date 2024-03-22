
$subscriptionId = "<subscriptionId>"
$resourceGroupName = "LoadTestResourceGroup"
$loadTestName = "LoadTest"
$location = "East US"
$jmeterFilePath = "<pathToJMXFile>"
$storageAccountName = "loadteststorageaccount"
$containerName = "loadtestcontainer"
$reportFileName = "LoadTestReport.txt"

Connect-AzAccount

Set-AzContext -SubscriptionId $subscriptionId

New-AzResourceGroup -Name $resourceGroupName -Location $location

New-AzResource -ResourceGroupName $resourceGroupName -ResourceName $loadTestName -ResourceType "Microsoft.LoadTestService/loadtests" -ApiVersion "2021-12-01-preview" -Location $location -Properties @{ "JMeterFilePath" = $jmeterFilePath } -Force

$loadTest = Get-AzResource -ResourceGroupName $resourceGroupName -ResourceName $loadTestName -ResourceType "Microsoft.LoadTestService/loadtests"

# Display the load test details
Write-Host "Load Test Details:"
Write-Host "Name: $($loadTest.Name)"
Write-Host "Resource Group: $($loadTest.ResourceGroupName)"
Write-Host "Location: $($loadTest.Location)"
Write-Host "JMeter File Path: $($loadTest.Properties.JMeterFilePath)"

# Create a storage account
New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2

# Create a blob container
New-AzStorageContainer -Name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

# Upload the load test report to the blob container
Set-AzStorageBlobContent -File $reportFileName -Container $containerName -Blob $reportFileName -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

# Run the load test using the CLI command
az loadtest run --name $loadTestName --subscription $subscriptionId --storage-account-name $storageAccountName --storage-container-name $containerName --jmx $jmeterFilePath --report $reportFileName

# Get the load test results
$loadTestResults = az loadtest result show --name $loadTestName --subscription $subscriptionId --output json

# Save the load test results to a local file
$loadTestResults | ConvertTo-Json | Out-File $reportFileName

# Delete the load test resource
Remove-AzResource -ResourceGroupName $resourceGroupName -ResourceName $loadTestName -ResourceType "Microsoft.LoadTestService/loadtests" -ApiVersion "2021-12-01-preview" -Force

# Delete the resource group
Remove-AzResourceGroup -Name $resourceGroupName -Force

Write-Host "Load test completed and results saved to $reportFileName"
