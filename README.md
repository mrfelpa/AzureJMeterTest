# Prerequisites

- An Azure subscription with sufficient permissions to create Azure resources.
  
- A jmeter (.jmx) file containing the load test script.
  
- The Azure PowerShell Az.LoadTest module installed. Run the following command to install the module:

      Install-Module Az.LoadTest

# Configuration

- Replace the ***<subscriptionId>*** value with your Azure subscription ID.
  
- Replace the value of ***<pathToJMXFile>*** with the path of the jmeter (.jmx) file that contains the load test script.

# Running the Script

- Open PowerShell as an administrator.
  
- Navigate to the directory where you saved the script.
  
- Run the script using the following command:

      jmeter-loadtest.ps1
