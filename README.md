# Language Cloud Powershell Toolkit
## Introduction
The Language Cloud PowerShell Toolkit allows users to script the REST API available for SDL Language Cloud. The purpose of this toolkit is to automate project creation and retrieve essential resources through the PowerShell console.

## Table of Contents
<details>
  <summary>Expand</summary>

  - [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Configuring and running the Sample Roundtrip script](#configuring-and-running-the-sample-roundtrip-script)
  - [Importing and Using PowerShell Modules](#importing-and-using-powershell-modules)
  - [Accessing Module Documentation](#accessing-module-documentation)
  - [Function Documentation](#function-documentation)
  - [Ensuring File Permissions for Toolkit Files](#ensuring-file-permissions-for-toolkit-files)
  - [Contribution](#contribution)
  - [Issues](#issues)
  - [Changes](#changes)
</details>

## Getting Started
To run the scripts, ensure you have the following:

- **PowerShell Version 7.4 or Higher**  
    If you need to install PowerShell 7.4, follow the instructions provided [here](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows).

- **SDL Language Cloud License**  
    Ensure you have access to an SDL Language Cloud account, as the scripts will interact with the Language Cloud API for various operations.

## Installation
1. Download the Files
    - Obtain all necessary files: Ensure you have downloaded the toolkit files, including sample roundtrip script and PowerShell modules. These files should be obtained from the [here](#ensuring-file-permissions-for-toolkit-files).
    - After downloading, you may need to unblock the zip file. For instructions on how to unblock files, see [Ensuring File Permissions for Toolkit Files](#ensuring-file-permissions-for-toolkit-files).
2. Create Required Folders
    - Create the following folders if they do not already exist:
        - `C:\users\{your_user_name}\Documents\Powershell`
        - `C:\users\{your_user_name}\Documents\Powershell\Modules`
3. Copy Sample Roundtrip Script
    - Copy the `Sample_Roundtrip.ps1` scripts into the `Powershell` folder.
    - Ensure these files are placed directly in `C:\Users\{your_user_name}\Documents\Powershell`.
4. Copy PowerShell Modules
    -   Copy the PowerShell modules into the `Modules` folder:
        -   `...\Powershell\Modules\AuthenticationHelper`
        -   `...\Powershell\Modules\ResourcesHelper`
        -   `...\Powershell\Modules\ProjectHelper`
        -   `...\Powershell\Modules\UsersHelper`
    - Ensure each module folder contains its respective `.psd1` and `.psm1` files.
5. Verify File Locations
    - Confirm the locations of the files:
        - The roundtrip script should be in `C:\Users\{your_user_name}\Documents\Powershell`.
        - Modules should be in `C:\Users\{your_user_name}\Documents\Powershell\Modules` with appropriate subfolders for each module.

## Configuring and running the Sample Roundtrip script.
### Configuring the Sample Roundtrip
To configure the roundtrip scripts, you need to provide specific authentication details, including the **Client ID**, **Client Secret**, and **Tenant ID**. Follow the steps below to obtain and populate these values.

1. **Retrieve Your Client ID and Client Secret:** To obtain your Client ID and Client Secret, follow these instructions:
    - **Log in** to the RWS Trados Enterprise web UI as a human Administrator user. If you do not have administrator access, contact your administrator for assistance.
    - **Expand the account menu** in the top right corner and select Integrations.
    - Navigate to the **Applications** sub-tab.
    - Click on **New Application** and enter the following information:
        - **Name**: Enter a unique name for your custom application.
        - **(Optional) URL**: Enter your custom application URL.
        - **(Optional) Description**: Enter any relevant details.   
        - **Service User**: Select a service user from the dropdown.
    - Click **Add**.
    - Back in the **Applications** sub-tab, select the checkbox corresponding to your application and then click **Edit**.
    - On the **Overall Information** page, you can change any of the following if necessary: name, URL, or description.
    - On the **WebHooks** page:
        - Enter a default callback URL for your application Webhooks (all Webhooks defined in RWS Language Cloud).
        - Enter a value for **Webhook URL** (this is your Webhook endpoint URL that RWS Language Cloud will call).
        - Select one or more event types and hit Enter. You can create a separate webhook for every event you are interested in or combine notifications for multiple event types into one webhook.
        - Note that if you delete your application, all its associated webhooks will also be deleted.
    - Finally, navigate to the **API Access** page to retrieve your **Client ID** and **Client Secret**.
2. **Retrieve Your Tenant ID:**
    - Navigate to the **Users** section in the RWS Trados Enterprise web UI.
    - Select **Manage Account**
    - Copy your **Trados Account ID**. This ID serves as your **Tenant ID**
3. **Update the Script**: After obtaining your Client ID, Client Secret, and Tenant ID, update the script with the retrieved values.
    ```powershell
        # Define the client ID, client secret, and tenant ID for authentication
        $clientId = "YOUR_CLIENT_ID"          # Change this with your actual client ID
        $clientSecret = "YOUR_CLIENT_SECRET"  # Change this with your actual client secret
        $lcTenant = "YOUR_TENANT_ID"          # Change this with your actual tenant ID
    ```
### Running the Sample Roundtrip script.
This section assumes that you have already configured the `Sample_Roundtrip.ps1` script and set up your environment as described in the previous sections. To run the script, follow these steps:
1. Open PowerShell 7.4 or Higher
    - Launch PowerShell 7.4 or a later version.
2. Set the Execution Policy (If Needed)
    -  If you haven’t unblocked the files as described in the [Ensuring File Permissions](#ensuring-file-permissions-for-toolkit-files) for Toolkit Files section, you may need to set the execution policy to Unrestricted to allow script execution. Execute the following command:
        ```powershell
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
        ```
    - This command permits PowerShell script execution without requiring local Windows admin privileges and should be executed once per machine and user profile. Note: If you have already unblocked the files, setting the execution policy may not be necessary.
3. Navigate to the Script Location
    - Use the `cd` command to change your directory to the location where the `Sample_Roundtrip.ps1` script is saved:
      ```powershell
      cd C:\Users\{your_user_name}\Documents\Powershell
      ```
4. Run the Script
    - Execute the script using the following command
      ```powershell
      .\Sample_Roundtrip.ps1
      ```

## Importing and Using PowerShell Modules
Before using the functions provided by the modules, you need to ensure they are correctly imported into your PowerShell session. This section outlines the steps to import the modules based on their availability in your environment.

### Importing Modules
1. Check Module Availability
    - Use the `Get-Module` command to verify if the required modules are available in your PowerShell environment:
      ```powershell
      Get-Module -ListAvailable -Name AuthenticationHelper, ProjectHelper, ResourcesHelper, UsersHelper
      ```
    - If the modules are listed, they are available in the environment path.
2. Import Modules from Environment Path
   -  If the modules are available in the environment path, you can import them directly by name. For example:
      ```powershell
      Import-Module -Name AuthenticationHelper
      Import-Module -Name ProjectHelper 
      Import-Module -Name ResourcesHelper 
      Import-Module -Name UsersHelper 
      ```
3. Import Modules from Specific Path
    - If the modules are not available in the environment path, you will need to import them from their specific location. Use the full path to the module when importing. For example:
      ```powershell
      Import-Module -Name "C:\Users\{your_user_name}\Documents\Powershell\Modules\AuthenticationHelper"
      Import-Module -Name "C:\Users\{your_user_name}\Documents\Powershell\Modules\ProjectHelper" 
      Import-Module -Name "C:\Users\{your_user_name}\Documents\Powershell\Modules\ResourcesHelper"
      Import-Module -Name "C:\Users\{your_user_name}\Documents\Powershell\Modules\UsersHelper"
      ```

#### Permanently Add the Module Path to `$env:PSModulePath`
If you want to add the module path permanently so that it remains available across PowerShell sessions and system reboots, follow these steps:
1. Open PowerShell 7 as Administrator
    - Right-click on the PowerShell 7 icon and select *"Run as administrator."*
2. Add the Directory to the Environment Variable
    - Execute the following commands to add your module path to the $env:PSModulePath environment variable:
        ```powershell
        $modulePath = "C:\Users\{Your_username}\Documents\Powershell\Modules"
        [System.Environment]::SetEnvironmentVariable("PSModulePath", "$env:PSModulePath;$modulePath", [System.EnvironmentVariableTarget]::User)
        ```
    - Replace `{Your_username}` with your actual username.
3. Confirm the Path Has Been Added Permanently
    - To verify that the path has been successfully added, run:
        ```powershell
        $env:PSModulePath
        ```
    - You should see your new path included in the output.

### Using the Modules 
Once the modules are imported, you can start using their functions in PowerShell 7. Each module provides specific cmdlets and functions that you can call directly in your session. For example:
  - List available functions in a module:
    ```powershell
    Get-Command -Module AuthenticationHelper
    ```
  - Run a function from a module:
    ```powershell
    Get-AccessKey -id "{your-client-id}" -secret "{your-client-secret}" -lctenant "{your-lctenant}" 
    ```
    Replace `Get-AccessKey` with any cmdlet or function provided by the module you wish to use. Consult the module's documentation or use `Get-Help` for details on available functions.

## Accessing Module Documentation
The toolkit has been documented with `Get-Help` to provide detailed information on the available cmdlets and functions. Follow these steps to access the documentation:
1. Ensure Modules Are Loaded
    - Before accessing the help documentation, make sure that the necessary modules are imported into your PowerShell 7 session. You can do this by running:
        ```powershell
        Import-Module -Name AuthenticationHelper
        Import-Module -Name ProjectHelper
        Import-Module -Name ResourcesHelper
        Import-Module -Name UsersHelper
        ```
    If modules are not in the environment path, use the full path for importing as needed.

2. Access Documentation
    - Once the modules are loaded, you can use `Get-Help` to access the documentation for any cmdlet or function provided by the module. For example:
      ```powershell
      Get-Help Get-AccessKey
      ```
    - Replace `Get-AccessKey` with the name of the cmdlet or function you want to learn more about.

3. Explore Additional Help Topics
    - To view a list of available cmdlets and functions in a module, use:
        ```powershell
        Get-Command -Module AuthenticationHelper
        ```
    - For more detailed information on each cmdlet or function, including examples and parameter descriptions, use:
        ```powershell
        Get-Help <Function-Name> -Detailed
        ```
      or  
        ```powershell
        Get-Help <Function-Name> -Examples
        ```

By using `Get-Help`, you can access comprehensive documentation and examples for all the functions available in the toolkit, aiding you in effectively utilizing the provided modules.

## Function Documentation
This section provides detailed documentation for the functions included in the PowerShell script modules.

| Function Name	| Description | Module |
| ------ | --------- | ------  |
| `Get-AccessKey` | Authenticates using the provided client ID, secret, and tenant ID, and returns an object containing the access token and tenant necessary for making API calls. | `AuthenticationHelper` |
| `New-Project`                | Creates a new project                          |  `ProjectHelper`  |
| `Get-AllProjectTemplates`    | Retrieves all project templates.               | `ResourcesHelper` |
| `Get-AllTranslationEngines`  | Retrieves all translation engines.             | `ResourcesHelper` |
| `Get-AllCustomers`           | Retrieves all customers.                       | `ResourcesHelper` |
| `Get-AllFileTypeConfigurations` | Retrieves all file type configurations.     | `ResourcesHelper` |
| `Get-AllWorkflows`           | Retrieves all workflows.                       | `ResourcesHelper` |
| `Get-AllPricingModels`       | Retrieves all pricing models.                  | `ResourcesHelper` |
| `Get-AllScheduleTemplates`   | Retrieves all schedule templates.              | `ResourcesHelper` |
| `Get-AllLocations`           | Retrieves all locations.                       | `ResourcesHelper` |
| `Get-AllUsers`               | Retrieves all users.                           | `ResourcesHelper` |
| `Get-AllGroups`              | Retrieves all groups.                          | `ResourcesHelper` |

## Ensuring File Permissions for Toolkit Files

Windows may block files downloaded from the internet for security reasons. To ensure the toolkit functions properly, unblock the downloaded zip file.

### Step-by-Step Instructions

#### Locate the Downloaded File:
- Open File Explorer and navigate to the folder containing the downloaded file.

#### Right-Click on the File:
- Right-click on the file to open the context menu.

#### Open File Properties:
- Select "Properties" from the context menu. 

#### Unblock the File:
- In the Properties dialog, go to the "General" tab.
- Look for the message: "This file came from another computer and might be blocked to help protect this computer."
- If this message is present, check the box next to "Unblock."

#### Apply and Close:
- Click "Apply" to save the changes.
- Click "OK" to close the Properties dialog.

## Contribution
If you want to add a new functionality or you spot a bug please fill free to create a pull request with your changes.

## Issues
If you find an issue you report it here.

## Changes
### Version
