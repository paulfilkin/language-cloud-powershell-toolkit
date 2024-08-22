function New-Project 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(mandatory=$true)]
        [String] $projectName,

        [Parameter(mandatory=$true)]
        [String] $projectDueDate,

        [Parameter(Mandatory=$true)]
        [String] $filesPath,

        [String[]] $referenceFileNames,
        [String] $sourceLanguage,
        [String[]] $targetLanguages,
        [String] $customerName,
        [String] $description,
        [String] $projectTemplate,
        [String] $translationEngine,
        [String] $fileProcessingConfiguration,
        [String] $workflow,
        [String] $pricingModel,
        [Bool] $restrictFileDownload = $false,
        [String] $scheduletemplate,
        [String[]] $userManagers,
        [String[]] $groupsManager,
        [Bool] $includeSettings = $false,
        [Int32] $configCompleteDays = 90,
        [Int32] $configArchiveDays = 90,
        [Int32] $configReminderDays = 7
    )

    $projectCreateResponse = New-ProjectRequest $accessKey $projectName $projectDueDate $sourceLanguage $targetLanguages $customerName $description $projectTemplate $translationEngine $fileProcessingConfiguration $workflow $pricingModel $restrictFileDownload $scheduletemplate $userManagers $groupsManager $includeSettings $configCompleteDays $configArchiveDays $configReminderDays

    if ($null -eq $projectCreateResponse)
    {
        return;
    }

    $sourceLang = $projectCreateResponse.languageDirections[0].sourceLanguage.languageCode;
    Add-SourceFiles $accessKey $projectCreateResponse.Id $sourceLang $filesPath $referenceFileNames
    return Start-Project $accessKey $projectCreateResponse.Id;
}

function Start-Project
{
    param (
        [psobject] $accessKey,
        [String] $projectId)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    return Invoke-RestMethod "https://lc-api.sdl.com/public-api/v1/projects/$projectId/start" -Method 'PUT' -Headers $headers
}

function Add-File # this should be changed to add-files
{
    param (
        [psobject] $accessKey,
        [String] $projectId,
        [psobject] $file,
        [psobject] $properties
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "multipart/form-data")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

        
    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
    $stringHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $stringHeader.Name = "properties"
    $json = $properties | ConvertTo-Json -depth 5;
    $stringContent = [System.Net.Http.StringContent]::new($json)
    $stringContent.Headers.ContentDisposition = $stringHeader
    $multipartContent.Add($stringContent)

    $multipartFile = $file.FullName
    $FileStream = [System.IO.FileStream]::new($multipartFile, [System.IO.FileMode]::Open)
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileHeader.Name = "file"
    $fileHeader.FileName = $file.FullName
    $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $multipartContent.Add($fileContent)

    $body = $multipartContent
    
    $Null = Invoke-RestMethod "https://lc-api.sdl.com/public-api/v1/projects/$projectId/source-files" -Method 'POST' -Headers $headers -Body $body
}

function Add-SourceFiles 
{
    param (
        [psobject] $accessKey,
        [string] $projectId,
        [String] $sourceLanguage,
        [String] $filesPath,
        [string[]] $referenceFileNames
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "multipart/form-data")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    $files = @();
    if (Test-Path $filesPath) {
        $item = Get-Item $filesPath
        if ($item.PSIsContainer) {
            $files = Get-ChildItem -Path $filesPath -Recurse -File
        } else {
            $files += Get-Item $filesPath
        }
    }
    else 
    {
        return;
    }

    foreach ($file in $files)
    {
        if ($file.Name -in $referenceFileNames)
        {
            $fileRole = "reference"
        }
        else 
        {
            $fileRole = "translatable"
        }

        if ($file.FullName.EndsWith(".sdlxliff"))
        {
            $fileType = "sdlxliff"
        }
        else 
        {
            $fileType = "native"
        }

        $properties = [ordered]@{
            name = $file.Name
            role = $fileRole
            type = $fileType
            language = $sourceLanguage
        }

        # Here I should also create the type of file..
        $null = Add-File $accessKey $projectId $file $properties
    }   

}

function New-ProjectRequest 
{
    param (
        [psobject] $accessKey,
        [String] $projectName,
        [String] $projectDueDate,
        [String] $sourceLanguage,
        [String[]] $targetLanguages,
        [String] $customerName, #mandatory for location
        [String] $description,
        [String] $projectTemplate,
        [String] $translationEngine,
        [String] $fileProcessingConfiguration,
        [String] $workflow,
        [String] $pricingModel,
        [Bool] $restrictFileDownload = $false,
        [String] $scheduletemplate,
        [String[]] $userManagers,
        [String[]] $groupsManager,
        [Bool] $includeSettings = $false,
        [Int32] $configCompleteDays = 90,
        [Int32] $configArchiveDays = 90,
        [Int32] $configReminderDays = 7
    )

    $projectBody = Get-ProjectBody $accessKey $projectName $projectDueDate $sourceLanguage $targetLanguages $customerName $description $projectTemplate $translationEngine $fileProcessingConfiguration $workflow $pricingModel $restrictFileDownload $scheduletemplate $userManagers $groupsManager $includeSettings $configCompleteDays $configArchiveDays $configReminderDays
    $jsonBody = $projectBody | ConvertTo-Json -Depth 100;

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    try 
    {
        return Invoke-RestMethod 'https://lc-api.sdl.com/public-api/v1/projects' -Method 'POST' -Headers $headers -Body $jsonBody;
    }
    catch {
        Write-Host "$_"
    }
}

function Get-ProjectBody
{
    param (
        [psobject] $accessKey,
        [String] $name,
        [String] $dueBy,
        [String] $sourceLanguage,
        [String[]] $targetLanguages,
        [String] $customerName,
        [String] $description,
        [String] $projectTemplate,
        [String] $translationEngine,
        [String] $fileProcessingConfiguration,
        [String] $workflow,
        [String] $pricingModel,
        [Bool] $restrictFileDownload = $false,
        [String] $scheduletemplate,
        [String[]] $userManagers,
        [String[]] $groupsManager,
        [Bool] $includeSettings = $false,
        [Int32] $configCompleteDays = 90,
        [Int32] $configArchiveDays = 90,
        [Int32] $configReminderDays = 7
    )

    $project = [ordered]@{
        "name" = $name
        "dueBy" = $dueBy
        "languageDirections" = @($(Get-LanguageDirections $sourceLanguage $targetLanguages))
    }

    $customer = Get-ResourceByNameOrId $accessKey $customerName "Customer"
    $project.location = $customer.location.id;

    $project.description = $description;

    if ($projectTemplate)
    {
        $template = Get-ResourceByNameOrId $accessKey $projectTemplate "ProjectTemplate"
        $project.projectTemplate = @{
            "id" = $template.Id
            "strategy" = "copy"
        }

        if ($project.languageDirections.Count -eq 0)
        {
            $project.languageDirections = $template.LanguageDirections
        }
    }

    if ($translationEngine)
    {
        $tEngine = Get-ResourceByNameOrId $accessKey $translationEngine "TranslationEngine"
        $project.translationEngine = @{
            "id" = $tEngine.Id
            "strategy" = "copy"
        }
    }

    if ($fileProcessingConfiguration)
    {
        $fConfig = Get-ResourceByNameOrId $accessKey $fileProcessingConfiguration "FileProcessingConfiguration"
        $project.fileProcessingConfiguration = @{
            "id" = $fConfig.Id
            "strategy" = "copy"
        }
    }

    if ($workflow)
    {
        $workflowResponse = Get-ResourceByNameOrId $accessKey $workflow "Workflow"
        $project.workflow = @{
            "id" = $workflowResponse.Id 
            "strategy" = "copy"
        }
    }

    if ($pricingModel)
    {
        $pricingModelResponse = Get-ResourceByNameOrId $accessKey $pricingModel "PricingModel"
        $project.pricingModel = @{
            "id" = $pricingModelResponse.Id
            "strategy" = "copy"
        }
    }

    if ($scheduletemplate)
    {
        $scheduleTemplateResponse = Get-ResourceByNameOrId $accessKey $scheduletemplate "ScheduleTemplate"
        $project.scheduleTemplate = @{
            "id" = $scheduleTemplateResponse.Id 
            "strategy" = "copy"
        }
    }

    $project.forceOnline = $restrictFileDownload.ToString().ToLower();

    if ($includeSettings)
    {
        $projectsettings = @{
            "general" = @{
                "completeDays" = $configCompleteDays
                "archiveDays" = $configArchiveDays
                "archiveReminderDays" = $configReminderDays
            } 
        }

        $project.settings = $projectsettings;
    }

    return $project
}

function Get-LanguageDirections 
{
    param (
        [String] $sourceLanguage,
        [String[]] $targetLanguages
    )

    $result = @()

    foreach ($language in $targetLanguages)
    {
        $sourceLanguageObject = @{"languageCode" = $sourceLanguage}
        $targetLanguageObject = @{"languageCode" = $language}

        $result += @{
            "sourceLanguage" = $sourceLanguageObject
            "targetLanguage" = $targetLanguageObject
        }
    }

    return $result;
}

function Get-ResourceByNameOrId
{
    param (
        [psobject] $accessKey,
        [String] $resourceIdOrName,
        [String] $resourceType
    )

    switch ($resourceType) {
        "Customer" { 
            $items = Get-AllCustomers $accessKey;
         }

         "ProjectTemplate"
         {
            $items = Get-AllProjectTemplates $accessKey
         }

         "TranslationEngine"
         {
            $items = Get-AllTranslationEngines $accessKey
         }

         "FileProcessingConfiguration"
         {
            $items = Get-AllFileTypeConfigurations $accessKey
         }

         "Workflow"
         {
            $items = Get-AllWorkflows $accessKey
         }

         "PricingModel"
         {
            $items = Get-AllPricingModels $accessKey
         }

         "ScheduleTemplate"
         {
            $items = Get-AllScheduleTemplates $accessKey
         }
        Default { return; }
    }

    foreach ($item in $items)
    {
        if ($item.Name -eq $resourceIdOrName -or $item.Id -eq $resourceIdOrName)
        {
            return $item;
        }
    }
}

Export-ModuleMember New-Project;
Export-ModuleMember Get-ProjectBody;