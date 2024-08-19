function Show-Header {
    param (
        [string]$title
    )
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host $title -ForegroundColor Yellow
    Write-Host "======================`n" -ForegroundColor Cyan
}

function Get-UserInput {
    param (
        [string]$prompt,
        [string]$validationPattern = ".+"
    )
    do {
        $input = Read-Host -Prompt $prompt
        if ($input -notmatch $validationPattern) {
            Write-Host "Invalid input. Please try again." -ForegroundColor Red
        }
    } while ($input -notmatch $validationPattern)
    return $input
}

function Show-Progress {
    param (
        [string]$activity,
        [int]$percent
    )
    Write-Progress -Activity $activity -Status "$activity in progress..." -PercentComplete $percent
}

Show-Header "Load Test Automation Script"

$subscriptionId = Get-UserInput "Enter your Subscription ID"
$resourceGroupName = "LoadTestResourceGroup"
$loadTestName = "LoadTest"
$location = "East US"
$jmeterFilePath = Get-UserInput "Enter the path to your JMeter (JMX) file"
$storageAccountName = Get-UserInput "Enter the name for the storage account (lowercase, 3-24 characters)"
$containerName = "loadtestcontainer"
$reportFileName = "LoadTestReport.txt"

Show-Progress "Connecting to Azure" 10
try {
    Connect-AzAccount
    Set-AzContext -SubscriptionId $subscriptionId
} catch {
    Write-Host "Failed to connect to Azure: $_" -ForegroundColor Red
    exit
}

Show-Progress "Creating Resource Group" 30
New-AzResourceGroup -Name $resourceGroupName -Location $location

Show-Progress "Creating Load Test" 50
try {
    New-AzResource -ResourceGroupName $resourceGroupName -ResourceName $loadTestName -ResourceType "Microsoft.LoadTestService/loadtests" -ApiVersion "2021-12-01-preview" -Location $location -Properties @{ "JMeterFilePath" = $jmeterFilePath } -Force
} catch {
    Write-Host "Failed to create load test: $_" -ForegroundColor Red
    exit
}

$loadTest = Get-AzResource -ResourceGroupName $resourceGroupName -ResourceName $loadTestName -ResourceType "Microsoft.LoadTestService/loadtests"

Show-Header "Load Test Details"
Write-Host "Name: $($loadTest.Name)"
Write-Host "Resource Group: $($loadTest.ResourceGroupName)"
Write-Host "Location: $($loadTest.Location)"
Write-Host "JMeter File Path: $($loadTest.Properties.JMeterFilePath)`n"

Show-Progress "Creating Storage Account" 70
try {
    New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2
} catch {
    Write-Host "Failed to create storage account: $_" -ForegroundColor Red
    exit
}

Show-Progress "Creating Blob Container" 80
New-AzStorageContainer -Name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

Show-Progress "Uploading Load Test Report" 90
Set-AzStorageBlobContent -File $reportFileName -Container $containerName -Blob $reportFileName -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

Show-Progress "Running Load Test" 100
az loadtest run --name $loadTestName --subscription $subscriptionId --storage-account-name $storageAccountName --storage-container-name $containerName --jmx $jmeterFilePath --report $reportFileName

$loadTestResults = az loadtest result show --name $loadTestName --subscription $subscriptionId --output json

$loadTestResults | ConvertTo-Json | Out-File $reportFileName

Remove-AzResource -ResourceGroupName $resourceGroupName -ResourceName $loadTestName -ResourceType "Microsoft.LoadTestService/loadtests" -ApiVersion "2021-12-01-preview" -Force

Remove-AzResourceGroup -Name $resourceGroupName -Force

Write-Host "Load test completed and results saved to $reportFileName" -ForegroundColor Green
