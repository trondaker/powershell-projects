$location = 'Norway East'
$resourceGroupName = 'trond-workshop'
$storageAccount = 'trondstorageaccountz'
$subscriptionId = '9f1b36f0-ab4c-444f-bd67-0b742263c2d6'
$functionAppName = 'blackjack-function-ta'
$appInsightsName = 'blackjack-function-ta-insights' 
$appServicePlanName = 'blackjack-serviceplan'
$tier = 'Basic'

# Velge subscription
Select-AzSubscription -SubscriptionID $subscriptionId
#Set-AzContext $subscriptionId

# Opprette resource-group hvis den ikke fins allerede
if(Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)  
{  
     Write-Host -ForegroundColor Magenta $resourceGroupName "Resource group already exists."  
}  
else  
{  
     Write-Host -ForegroundColor Magenta $resourceGroupName "Resource group does not exist."  
     Write-Host -ForegroundColor Green "Creating the resource group." $resourceGroupName  

     ## Create a new resource group  
     New-AzResourceGroup -Name $resourceGroupName -Location $location  
}   

if(Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount -ErrorAction SilentlyContinue)  
{  
     Write-Host -ForegroundColor Magenta $storageAccount "Storage account already exists."     
}  
else  
{  
     Write-Host -ForegroundColor Magenta "Storage account does not exist."  
     Write-Host -ForegroundColor Green "Creating the storage account" $storageAccount
     ## Create a new Azure Storage Account  
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

#========Creating AppInsight Resource========
New-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightsName -Location $location
$resource = Get-AzResource -Name $appInsightsName -ResourceType "Microsoft.Insights/components"
$details = Get-AzResource -ResourceId $resource.ResourceId
$appInsightsKey = $details.Properties.InstrumentationKey

#========Retrieving Keys========
$keys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccount
$accountKey = $keys | Where-Object { $_.KeyName -eq 'Key1' } | Select-Object -ExpandProperty Value
$storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName='+$storageAccount+';AccountKey='+$accountKey

#========Defining Azure Function Settings========
$AppSettings =@{}
$AppSettings =@{'APPINSIGHTS_INSTRUMENTATIONKEY' = $appInsightsKey;
                'AzureWebJobsDashboard' = $storageAccountConnectionString;
                'AzureWebJobsStorage' = $storageAccountConnectionString;
                'FUNCTIONS_EXTENSION_VERSION' = '~2';
                'FUNCTIONS_WORKER_RUNTIME' = 'dotnet';
                'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING' = $storageAccountConnectionString;
                'WEBSITE_CONTENTSHARE' = $storageAccount;}
Set-AzWebApp -Name $functionAppName -ResourceGroupName $resourceGroupName -AppSettings $AppSettings