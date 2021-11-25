$location = 'Norway East'
$resourceGroupName = 'TrondAker'
$storageAccount = 'trondstorageaccountz'
$subscriptionId = '86f78996-5db5-46fb-b33c-8ce0d97f7f0b'
$functionAppName = 'blackjack-function-ta'
$appInsightsName = 'blackjack-function-ta-insights' 
$appServicePlanName = 'blackjack-serviceplan'
$tier = 'Basic'

# Velge subscription
Select-AzSubscription -SubscriptionID $subscriptionId

# Opprette resource-group hvis den ikke fins allerede.
# ErrorAction med SilentlyContinue er bare for å ikke stoppe opp hvis resource-group ikke fins.
if(Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)  
{  
     Write-Host -ForegroundColor Magenta $resourceGroupName "Resource group already exists."  
}  
else  
{  
     Write-Host -ForegroundColor Magenta $resourceGroupName "Resource group does not exist."  
     Write-Host -ForegroundColor Green "Creating the resource group." $resourceGroupName  

     # Gruppa fins ikke, oppretter ny.
     New-AzResourceGroup -Name $resourceGroupName -Location $location  
}   

# Opprette storage account hvis den ikke fins allerede
if(Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount -ErrorAction SilentlyContinue)  
{  
     Write-Host -ForegroundColor Magenta $storageAccount "Storage account already exists."     
}  
else  
{  
     Write-Host -ForegroundColor Magenta "Storage account does not exist."  
     Write-Host -ForegroundColor Green "Creating the storage account" $storageAccount
     # StorageAccount fins ikke, opprett ny. 
     New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount -Location $location -SkuName Standard_LRS    
}   


# App-service-plan
New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName -Location $location -Tier $tier
$functionAppSettings = @{
    ServerFarmId="/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/serverfarms/$appServicePlanName";
    alwaysOn=$True;
}

# Oppretter selve funksjonen
$functionAppResource = Get-AzResource | Where-Object { $_.ResourceName -eq $functionAppName -And $_.ResourceType -eq "Microsoft.Web/Sites" }
if ($functionAppResource -eq $null)
{
  New-AzResource -ResourceType 'Microsoft.Web/Sites' -ResourceName $functionAppName -kind 'functionapp' -Location $location -ResourceGroupName $resourceGroupName -Properties $functionAppSettings -force
}

# Oppretter AppInsights-ressursene
New-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightsName -Location $location
$resource = Get-AzResource -Name $appInsightsName -ResourceType "Microsoft.Insights/components"
$details = Get-AzResource -ResourceId $resource.ResourceId
$appInsightsKey = $details.Properties.InstrumentationKey

# Trenger key1 fra min storage-account (key1 er bare generic navn, key2 brukes hvis key1 skal fases ut.)
$keys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccount
$accountKey = $keys | Where-Object { $_.KeyName -eq 'Key1' } | Select-Object -ExpandProperty Value
$storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName='+$storageAccount+';AccountKey='+$accountKey

# Settings for selve function-app. Skulle version ha vært noe annet tro?
$AppSettings =@{}
$AppSettings =@{'APPINSIGHTS_INSTRUMENTATIONKEY' = $appInsightsKey;
                'AzureWebJobsDashboard' = $storageAccountConnectionString;
                'AzureWebJobsStorage' = $storageAccountConnectionString;
                'FUNCTIONS_EXTENSION_VERSION' = '~3';
                'FUNCTIONS_WORKER_RUNTIME' = 'powershell';
                'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING' = $storageAccountConnectionString;
                'WEBSITE_CONTENTSHARE' = $storageAccount;}

# Binder app-settings og function-app sammen.                
Set-AzWebApp -Name $functionAppName -ResourceGroupName $resourceGroupName -AppSettings $AppSettings