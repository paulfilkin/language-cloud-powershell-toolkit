# Define the client ID, client secret, and tenant ID for authentication
$clientId = "{YOUR_CLIENT_ID}"          # Change this with your actual client ID
$clientSecret = "{YOUR_CLIENT_SECRET}"  # Change this with your actual client secret
$lcTenant = "{YOUR_TENANT_ID}"      # Change this with your actual tenant ID

# Clear the console to start with a clean output screen
Clear-Host

# Display script title and purpose with decorative separators
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "    Language Cloud Toolkit Demo       " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Yellow


# Inform the user that the script is starting
Write-Host "`nStarting script to demonstrate operations using the Language Cloud Toolkit..."

# Load necessary PowerShell modules for interacting with the LanguageCloud server
Write-Host "`nLoading required modules into the PowerShell session..." -ForegroundColor Cyan
Import-Module -Name AuthenticationHelper
Import-Module -Name ProjectHelper
Import-Module -Name ResourcesHelper
Import-Module -Name UsersHelper
Import-Module -Name TerminologyHelper

# Retrieve the access key using provided credentials
Write-Host "`nRetrieving access key..." -ForegroundColor Cyan
$accessKey = Get-AccessKey -id $clientId -secret $clientSecret -lcTenant $lcTenant

# Confirm that the access key was retrieved successfully
Write-Host "Access key retrieved successfully." -ForegroundColor Green

# List all locations
Write-Host "`nListing all locations:" -ForegroundColor Cyan
$locations = Get-AllLocations -accessKey $accessKey
if ($locations) {
    for ($i = 0; $i -lt $locations.Count; $i++) {
        Write-Host "[$($i + 1)] $($locations[$i].name)" -ForegroundColor Green
    }
} else {
    Write-Host "No locations found." -ForegroundColor Yellow
}

$rootLocation = $locations[0];

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all users
Write-Host "`nListing all users from the root location:" -ForegroundColor Cyan
$users = Get-AllUsers -accessKey $accessKey -locationId $rootLocation.Id
if ($users) {
    for ($i = 0; $i -lt $users.Count; $i++) {
        Write-Host "[$($i + 1)] $($users[$i].email) - $($users[$i].firstName) $($users[$i].lastName)" -ForegroundColor Green
    }
} else {
    Write-Host "No users found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all groups
Write-Host "`nListing all groups from the root location:" -ForegroundColor Cyan
$groups = Get-AllGroups -accessKey $accessKey -locationId $rootLocation.Id
if ($groups) {
    for ($i = 0; $i -lt $groups.Count; $i++) {
        Write-Host "[$($i + 1)] $($groups[$i].name) - $($groups[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No groups found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all project templates
Write-Host "`nListing all project templates from the root location:" -ForegroundColor Cyan
$projectTemplates = Get-AllProjectTemplates -accessKey $accessKey -locationId $rootLocation
if ($projectTemplates) {
    for ($i = 0; $i -lt $projectTemplates.Count; $i++) {
        Write-Host "[$($i + 1)] $($projectTemplates[$i].name)" -ForegroundColor Green
    }
} else {
    Write-Host "No project templates found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all translation engines
Write-Host "`nListing all translation engines from the root location:" -ForegroundColor Cyan
$translationEngines = Get-AllTranslationEngines -accessKey $accessKey -locationId $rootLocation.Id
if ($translationEngines) {
    for ($i = 0; $i -lt $translationEngines.Count; $i++) {
        Write-Host "[$($i + 1)] $($translationEngines[$i].name)" -ForegroundColor Green
    }
} else {
    Write-Host "No translation engines found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all file type configurations
Write-Host "`nListing all file type configurations from the root location:" -ForegroundColor Cyan
$fileTypeConfigs = Get-AllFileTypeConfigurations -accessKey $accessKey -locationId $rootLocation.Id
if ($fileTypeConfigs) {
    for ($i = 0; $i -lt $fileTypeConfigs.Count; $i++) {
        Write-Host "[$($i + 1)] $($fileTypeConfigs[$i].name)" -ForegroundColor Green
    }
} else {
    Write-Host "No file type configurations found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all workflows
Write-Host "`nListing all workflows from the root location:" -ForegroundColor Cyan
$workflows = Get-AllWorkflows -accessKey $accessKey -locationId $rootLocation.Id
if ($workflows) {
    for ($i = 0; $i -lt $workflows.Count; $i++) {
        Write-Host "[$($i + 1)] $($workflows[$i].name)" -ForegroundColor Green
    }
} else {
    Write-Host "No workflows found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all pricing models
Write-Host "`nListing all pricing models from the root location:" -ForegroundColor Cyan
$pricingModels = Get-AllPricingModels -accessKey $accessKey -locationId $rootLocation.Id
if ($pricingModels) {
    for ($i = 0; $i -lt $pricingModels.Count; $i++) {
        Write-Host "[$($i + 1)] $($pricingModels[$i].name)" -ForegroundColor Green
    }
} else {
    Write-Host "No pricing models found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

# List all customers
Write-Host "`nListing all customers from the rootLocation:" -ForegroundColor Cyan
$customers = Get-AllCustomers -accessKey $accessKey -locationId $rootLocation.Id
if ($customers) {
    for ($i = 0; $i -lt $customers.Count; $i++) {
        Write-Host "[$($i + 1)] $($customers[$i].name) - $($customers[$i].location)" -ForegroundColor Green
    }
} else {
    Write-Host "No customers found." -ForegroundColor Yellow
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

Write-Host "`nCreating a new customer" -ForegroundColor Cyan
$customerName = "PowerShell Customer Sample"

$newCustomer = New-Customer -accessKey $accessKey -customerName $customerName -locationId $rootLocation.Id
if ($newCustomer)
{
    Write-Host "`nCutomer [$($newCustomer.Name)] created." -ForegroundColor Green
    Write-Host "`nUpdating the rag status" -ForegroundColor Cyan;
    Update-Customer -accessKey $accessKey -customerId $newCustomer.Id -ragStatus "red";
}

Write-Host "`nManaging Translation Memories from the root location." -ForegroundColor Cyan;
Write-Host "`nListing all the existing Translation Memories" -ForegroundColor Cyan;
$tms = Get-AllTranslationEngines -accessKey $accessKey -locationId $rootLocation.Id;
if ($tms) 
{
    for ($i = 0; $i -lt $tms.Count; $i++)
    {
        Write-Host "[$($i + 1)] $($tms[$i].name)" -ForegroundColor Green
    }
}

# Wait 3 seconds after each retrieve to view the list
Start-Sleep -Seconds 3;

Write-Host "`nCreating a new translation memory" -ForegroundColor Cyan;
$languageProcessingRule = Get-AllLanguageProcessingRules -accessKey $accessKey | Select-Object -First 1;
$fieldTemplate = Get-AllFieldTemplates -accessKey $accessKey | Select-Object -First 1;
if ($languageProcessingRule -and $fieldTemplate)
{
    $newTM = New-TranslationMemory -accessKey $accessKey -name "Powershell Translation Memory" `
                -languageProcessingIdOrName $languageProcessingRule.Id -fieldTemplateIdOrName $fieldTemplate.Id `
                -sourceLanguage "en-US" -targetLanguages @("de-DE")

    if ($newTM)
    {
        Write-Host "`nTranslation Memory [$($newTM.Name)] created" -ForegroundColor Green;
    }
}

Write-Host "`nCreating a project template" -ForegroundColor Cyan;
# Initialize the dependencies to be used for project template creation and project creation
$fileTypeConfiguration = $fileTypeConfigs[0]
$translationEngine = $translationEngines[0]
$workflow = $workflows[0]

# Create the project Template
$newProjectTemplate = New-ProjectTemplate -accessKey $accessKey -projectTemplateName "Powershell Project Template" `
                -locationId $rootLocation.Id -fileTypeConfigurationIdOrName $fileTypeConfiguration.Id `
                -translationEngineIdOrName $translationEngine.Id -workflowIdOrName $workflow.Id `
                -sourceLanguage "en-US" -targetLanguages @("de-DE");

if ($newProjectTemplate)
{
    Write-Host "Project Template [$($newProjectTemplate.Name)] created" -ForegroundColor Green;
}

Write-Host "`nCreating a new project" -ForegroundColor Cyan;

# Creates a file in the script location for project creation
$scriptDirectory = $PSScriptRoot
$fileName = "sample_text_file.txt"
$fileContent = "This is a sample text file created by PowerShell."
$filePath = Join-Path $scriptDirectory $fileName
Set-Content -Path $filePath -Value $fileContent

# declare the basic data.
$dueDate = "2025-03-24"
$dueTime = "12:00"
$workflow = $workflows[0]

# Create the project
new-project $accessKey -name "PowerShell Project" -dueDate $dueDate -dueTime $dueTime `
        -fileTypeConfigurationIdOrName $fileTypeConfiguration.Id -translationEngineIdOrName $translationEngine.id `
        -filesPath $filePath -locationId $rootLocation.Id `
        -sourceLanguage "en-US" -targetLanguages @("de-DE") -workflowIdOrName $workflow.Id

# Display script completion message with decorative separators
Write-Host "`n======================================" -ForegroundColor Yellow
Write-Host "            Script Completed            " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Yellow