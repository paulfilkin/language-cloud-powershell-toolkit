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

# Retrieve the access key using provided credentials
Write-Host "`nRetrieving access key..." -ForegroundColor Cyan
$accessKey = Get-AccessKey -id $clientId -secret $clientSecret -lcTenant $lcTenant

# Confirm that the access key was retrieved successfully
Write-Host "Access key retrieved successfully." -ForegroundColor Green

# List all users
Write-Host "`nListing all users:" -ForegroundColor Cyan
$users = Get-AllUsers -accessKey $accessKey
if ($users) {
    for ($i = 0; $i -lt $users.Count; $i++) {
        Write-Host "[$($i + 1)] $($users[$i].email) - $($users[$i].firstName) $($users[$i].lastName)" -ForegroundColor Green
    }
} else {
    Write-Host "No users found." -ForegroundColor Yellow
}

# List all groups
Write-Host "`nListing all groups:" -ForegroundColor Cyan
$groups = Get-AllGroups -accessKey $accessKey
if ($groups) {
    for ($i = 0; $i -lt $groups.Count; $i++) {
        Write-Host "[$($i + 1)] $($groups[$i].name) - $($groups[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No groups found." -ForegroundColor Yellow
}

# List all project templates
Write-Host "`nListing all project templates:" -ForegroundColor Cyan
$projectTemplates = Get-AllProjectTemplates -accessKey $accessKey
if ($projectTemplates) {
    for ($i = 0; $i -lt $projectTemplates.Count; $i++) {
        Write-Host "[$($i + 1)] $($projectTemplates[$i].name) - $($projectTemplates[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No project templates found." -ForegroundColor Yellow
}

# List all translation engines
Write-Host "`nListing all translation engines:" -ForegroundColor Cyan
$translationEngines = Get-AllTranslationEngines -accessKey $accessKey
if ($translationEngines) {
    for ($i = 0; $i -lt $translationEngines.Count; $i++) {
        Write-Host "[$($i + 1)] $($translationEngines[$i].name) - $($translationEngines[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No translation engines found." -ForegroundColor Yellow
}

# List all customers
Write-Host "`nListing all customers:" -ForegroundColor Cyan
$customers = Get-AllCustomers -accessKey $accessKey
if ($customers) {
    for ($i = 0; $i -lt $customers.Count; $i++) {
        Write-Host "[$($i + 1)] $($customers[$i].name) - $($customers[$i].location)" -ForegroundColor Green
    }
} else {
    Write-Host "No customers found." -ForegroundColor Yellow
}

# List all file type configurations
Write-Host "`nListing all file type configurations:" -ForegroundColor Cyan
$fileTypeConfigs = Get-AllFileTypeConfigurations -accessKey $accessKey
if ($fileTypeConfigs) {
    for ($i = 0; $i -lt $fileTypeConfigs.Count; $i++) {
        Write-Host "[$($i + 1)] $($fileTypeConfigs[$i].name) - $($fileTypeConfigs[$i].location)" -ForegroundColor Green
    }
} else {
    Write-Host "No file type configurations found." -ForegroundColor Yellow
}

# List all workflows
Write-Host "`nListing all workflows:" -ForegroundColor Cyan
$workflows = Get-AllWorkflows -accessKey $accessKey
if ($workflows) {
    for ($i = 0; $i -lt $workflows.Count; $i++) {
        Write-Host "[$($i + 1)] $($workflows[$i].name) - $($workflows[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No workflows found." -ForegroundColor Yellow
}

# List all pricing models
Write-Host "`nListing all pricing models:" -ForegroundColor Cyan
$pricingModels = Get-AllPricingModels -accessKey $accessKey
if ($pricingModels) {
    for ($i = 0; $i -lt $pricingModels.Count; $i++) {
        Write-Host "[$($i + 1)] $($pricingModels[$i].name) - $($pricingModels[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No pricing models found." -ForegroundColor Yellow
}

# List all schedule templates
Write-Host "`nListing all schedule templates:" -ForegroundColor Cyan
$scheduleTemplates = Get-AllScheduleTemplates -accessKey $accessKey
if ($scheduleTemplates) {
    for ($i = 0; $i -lt $scheduleTemplates.Count; $i++) {
        Write-Host "[$($i + 1)] $($scheduleTemplates[$i].name) - $($scheduleTemplates[$i].description)" -ForegroundColor Green
    }
} else {
    Write-Host "No schedule templates found." -ForegroundColor Yellow
}

# List all locations
Write-Host "`nListing all locations:" -ForegroundColor Cyan
$locations = Get-AllLocations -accessKey $accessKey
if ($locations) {
    for ($i = 0; $i -lt $locations.Count; $i++) {
        Write-Host "[$($i + 1)] $($locations[$i].name) - $($locations[$i].location)" -ForegroundColor Green
    }
} else {
    Write-Host "No locations found." -ForegroundColor Yellow
}


# Create a sample text file with "Hello, World!" content
$filePath = Join-Path -Path (Get-Location) -ChildPath "HelloWorld.txt"
Set-Content -Path $filePath -Value "Hello, World!"
Write-Host "`nSample text file created at: $filePath" -ForegroundColor Cyan

# Get the due date 7 days from now and format it to YYYY-MM-DDTHH-MMZ
$dueDate = (Get-Date).AddDays(7)
$projectDueDate = $dueDate.ToString("yyyy-MM-ddTHH:mmZ")  # Format to desired string
c
# Define project parameters
$projectName = "Sample Project"
$projectDueDate = $projectDueDate
$sourceLanguage = "en-US"
$targetLanguages = @("de-DE", "fr-FR")
$location = $locations[0].id
$description = "This is a sample project created via PowerShell script."
$translationEngine = $translationEngines[0].name  # Use the first translation engine
$workflow = $workflows[0].id # Use the first workflow
$fileTypeConfiguration = $fileTypeConfigs[0].id # Use the first file type configuration
$filesPath = $filePath  # Use the current directory for files

Write-Host $pricingModel;

# Create the project using New-Project function
Write-Host "`nCreating new project..." -ForegroundColor Green
New-Project -accessKey $accessKey -projectName $projectName -projectDueDate $projectDueDate `
    -filesPath $filesPath -referenceFileNames @() -sourceLanguage $sourceLanguage `
    -targetLanguages $targetLanguages -location $location `
    -description $description -workflow $workflow `
    -translationEngine $translationEngine -fileProcessingConfiguration $fileTypeConfiguration

# Display script completion message with decorative separators
Write-Host "`n======================================" -ForegroundColor Yellow
Write-Host "            Script Completed            " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Yellow