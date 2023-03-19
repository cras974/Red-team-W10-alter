<#
    .SYNOPSIS
        Installation script for CommandoVM.
    .DESCRIPTION
        Placeholder
    .PARAMETER password
        Current user password to allow reboot resiliency via Boxstarter
    .PARAMETER noPassword
        Switch parameter indicating a password is not needed for reboots.
    .PARAMETER customProfile
        Path to a configuration XML file. May be a file path or URL.
    .PARAMETER noGui
        Switch parameter to skip customization GUI.
    .PARAMETER noWait
    Switch parameter to skip installation message before installation begins.
    .PARAMETER noReboots
        Switch parameter to prevent reboots.
    .PARAMETER noChecks
        Switch parameter to skip validation checks (not recommended).
    .EXAMPLE
        .\install.ps1
    .LINK
        https://github.com/mandiant/commando-vm
        https://github.com/mandiant/VM-Packages
#>
param (
  [string]$password = $null,
  [switch]$noPassword,
  [string]$customProfile = $null,
  [switch]$noWait,
  [switch]$noGui,
  [switch]$noReboots,
  [switch]$noChecks
)

# Load the GUI controls
if (-not $noGui.IsPresent) {

    [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)
  
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $iconPath = Join-Path $PSScriptRoot "logo.png"
    $icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -ArgumentList $iconPath).GetHicon())

    #################################################################################################
    ################################# Main Installer Form Controls ##################################
    #################################################################################################

    $CommandoInstaller               = New-Object system.Windows.Forms.Form
    $CommandoInstaller.ClientSize    = New-Object System.Drawing.Point(693,574)
    $CommandoInstaller.text          = "CommandoVM Installer"
    $CommandoInstaller.TopMost       = $false
    $CommandoInstaller.Icon          = $icon

    $CommandoLogo                    = New-Object system.Windows.Forms.PictureBox
    $CommandoLogo.width              = 338
    $CommandoLogo.height             = 246
    $CommandoLogo.location           = New-Object System.Drawing.Point(179,37)
    $CommandoLogo.imageLocation      = Join-Path $PSScriptRoot "logo.png"
    $CommandoLogo.SizeMode           = [System.Windows.Forms.PictureBoxSizeMode]::zoom

    ################################# Main Installer Profile Selection Controls #################################

    $ProfileSelector                 = New-Object system.Windows.Forms.ComboBox
    $ProfileSelector.text            = "Select Profile"
    $ProfileSelector.width           = 141
    $ProfileSelector.height          = 108
    $ProfileSelector.location        = New-Object System.Drawing.Point(380,449)
    $ProfileSelector.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $ProfileSelector.DropDownStyle   = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $ProfileSelector.Add_SelectedIndexChanged({
        $global:selectedProfile = $ProfileSelector.SelectedItem
    
        # Find the DiskSize from $global:profileData where ProfileName equals $global:selectedProfile
        $diskSize = ($global:profileData | Where-Object { $_.ProfileName -eq $global:selectedProfile }).DiskSize
    
        # Set $RecommendedDiskSpace.Text to the found DiskSize
        $RecommendedDiskSpace.Text = "$($diskSize)GB"
    })
    

    $ConfigureProfileButton          = New-Object system.Windows.Forms.Button
    $ConfigureProfileButton.text     = "Configure Profile"
    $ConfigureProfileButton.width    = 142
    $ConfigureProfileButton.height   = 29
    $ConfigureProfileButton.location  = New-Object System.Drawing.Point(380,478)
    $ConfigureProfileButton.Font     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $ConfigureProfileButton.Add_Click({Open-ProfileManager})

    $RecommendedDiskSpace            = New-Object system.Windows.Forms.Label
    $RecommendedDiskSpace.text       = "40GB+"
    $RecommendedDiskSpace.AutoSize   = $true
    $RecommendedDiskSpace.width      = 25
    $RecommendedDiskSpace.height     = 10
    $RecommendedDiskSpace.location   = New-Object System.Drawing.Point(590,523)
    $RecommendedDiskSpace.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $RecommendedDiskSpaceLabel       = New-Object system.Windows.Forms.Label
    $RecommendedDiskSpaceLabel.text  = "Recommended Disk Space - "
    $RecommendedDiskSpaceLabel.AutoSize  = $true
    $RecommendedDiskSpaceLabel.width  = 25
    $RecommendedDiskSpaceLabel.height  = 10
    $RecommendedDiskSpaceLabel.location  = New-Object System.Drawing.Point(390,523)
    $RecommendedDiskSpaceLabel.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $RecommendedDiskSpaceLabel.ForeColor  = [System.Drawing.ColorTranslator]::FromHtml("#c10000")

    ################################# Main Installer Profile Labels #################################

    $ProfileLabels                   = New-Object system.Windows.Forms.Groupbox
    $ProfileLabels.height            = 166
    $ProfileLabels.width             = 304
    $ProfileLabels.text              = "Available Profiles"
    $ProfileLabels.location          = New-Object System.Drawing.Point(38,342)

    $ProfileLabelDefault             = New-Object system.Windows.Forms.Label
    $ProfileLabelDefault.text        = "Default"
    $ProfileLabelDefault.AutoSize    = $true
    $ProfileLabelDefault.width       = 25
    $ProfileLabelDefault.height      = 10
    $ProfileLabelDefault.location    = New-Object System.Drawing.Point(20,25)
    $ProfileLabelDefault.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $ProfileLabelFull                = New-Object system.Windows.Forms.Label
    $ProfileLabelFull.text           = "Full"
    $ProfileLabelFull.AutoSize       = $true
    $ProfileLabelFull.width          = 25
    $ProfileLabelFull.height         = 10
    $ProfileLabelFull.location       = New-Object System.Drawing.Point(20,50)
    $ProfileLabelFull.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $ProfileLabelLite                = New-Object system.Windows.Forms.Label
    $ProfileLabelLite.text           = "Lite"
    $ProfileLabelLite.AutoSize       = $true
    $ProfileLabelLite.width          = 25
    $ProfileLabelLite.height         = 10
    $ProfileLabelLite.location       = New-Object System.Drawing.Point(20,75)
    $ProfileLabelLite.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $ProfileLabelDeveloper           = New-Object system.Windows.Forms.Label
    $ProfileLabelDeveloper.text      = "Developer"
    $ProfileLabelDeveloper.AutoSize  = $true
    $ProfileLabelDeveloper.width     = 25
    $ProfileLabelDeveloper.height    = 10
    $ProfileLabelDeveloper.location  = New-Object System.Drawing.Point(20,100)
    $ProfileLabelDeveloper.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $ProfileLabelVictim              = New-Object system.Windows.Forms.Label
    $ProfileLabelVictim.text         = "Victim"
    $ProfileLabelVictim.AutoSize     = $true
    $ProfileLabelVictim.width        = 25
    $ProfileLabelVictim.height       = 10
    $ProfileLabelVictim.location     = New-Object System.Drawing.Point(20,125)
    $ProfileLabelVictim.Font         = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    ################################# Main Installer Profile Description Labels #################################

    $ProfileLabelDescriptionDefault   = New-Object system.Windows.Forms.Label
    $ProfileLabelDescriptionDefault.text  = "- numerous packages for pentesting"
    $ProfileLabelDescriptionDefault.AutoSize  = $true
    $ProfileLabelDescriptionDefault.width  = 25
    $ProfileLabelDescriptionDefault.height  = 10
    $ProfileLabelDescriptionDefault.location  = New-Object System.Drawing.Point(70,25)
    $ProfileLabelDescriptionDefault.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $ProfileLabelDescriptionFull     = New-Object system.Windows.Forms.Label
    $ProfileLabelDescriptionFull.text  = "- all tools suitable for CommandoVM"
    $ProfileLabelDescriptionFull.AutoSize  = $true
    $ProfileLabelDescriptionFull.width  = 25
    $ProfileLabelDescriptionFull.height  = 10
    $ProfileLabelDescriptionFull.location  = New-Object System.Drawing.Point(50,50)
    $ProfileLabelDescriptionFull.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $ProfileLabelDescriptionLite     = New-Object system.Windows.Forms.Label
    $ProfileLabelDescriptionLite.text  = "- only the bare minimum essential tools"
    $ProfileLabelDescriptionLite.AutoSize  = $true
    $ProfileLabelDescriptionLite.width  = 25
    $ProfileLabelDescriptionLite.height  = 10
    $ProfileLabelDescriptionLite.location  = New-Object System.Drawing.Point(50,75)
    $ProfileLabelDescriptionLite.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $ProfileLabelDescriptionDeveloper   = New-Object system.Windows.Forms.Label
    $ProfileLabelDescriptionDeveloper.text  = "- comes with development tools"
    $ProfileLabelDescriptionDeveloper.AutoSize  = $true
    $ProfileLabelDescriptionDeveloper.width  = 25
    $ProfileLabelDescriptionDeveloper.height  = 10
    $ProfileLabelDescriptionDeveloper.location  = New-Object System.Drawing.Point(90,100)
    $ProfileLabelDescriptionDeveloper.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $ProfileLabelDescriptionVictim   = New-Object system.Windows.Forms.Label
    $ProfileLabelDescriptionVictim.text  = "- set up with tools for payload testing"
    $ProfileLabelDescriptionVictim.AutoSize  = $true
    $ProfileLabelDescriptionVictim.width  = 25
    $ProfileLabelDescriptionVictim.height  = 10
    $ProfileLabelDescriptionVictim.location  = New-Object System.Drawing.Point(65,125)
    $ProfileLabelDescriptionVictim.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    ################################# Main Installer License Labels #################################

    $DisclaimerLabelLine1            = New-Object system.Windows.Forms.Label
    $DisclaimerLabelLine1.text       = "By proceeding with the installation, you are"
    $DisclaimerLabelLine1.AutoSize   = $true
    $DisclaimerLabelLine1.width      = 262
    $DisclaimerLabelLine1.height     = 12
    $DisclaimerLabelLine1.location   = New-Object System.Drawing.Point(380,344)
    $DisclaimerLabelLine1.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $DisclaimerLabelLine2            = New-Object system.Windows.Forms.Label
    $DisclaimerLabelLine2.text       = "accepting the license terms of each package,"
    $DisclaimerLabelLine2.AutoSize   = $true
    $DisclaimerLabelLine2.width      = 262
    $DisclaimerLabelLine2.height     = 10
    $DisclaimerLabelLine2.location   = New-Object System.Drawing.Point(380,368)
    $DisclaimerLabelLine2.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $DisclaimerLabelLine3            = New-Object system.Windows.Forms.Label
    $DisclaimerLabelLine3.text       = "and acknowledging that your use of each package"
    $DisclaimerLabelLine3.AutoSize   = $true
    $DisclaimerLabelLine3.width      = 262
    $DisclaimerLabelLine3.height     = 10
    $DisclaimerLabelLine3.location   = New-Object System.Drawing.Point(380,392)
    $DisclaimerLabelLine3.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $DisclaimerLabelLine4            = New-Object system.Windows.Forms.Label
    $DisclaimerLabelLine4.text       = " will be subject to its respective license terms."
    $DisclaimerLabelLine4.AutoSize   = $true
    $DisclaimerLabelLine4.width      = 262
    $DisclaimerLabelLine4.height     = 10
    $DisclaimerLabelLine4.location   = New-Object System.Drawing.Point(380,417)
    $DisclaimerLabelLine4.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    ################################# Main Installer Controls #################################

    $InstallButton                   = New-Object system.Windows.Forms.Button
    $InstallButton.text              = "Install"
    $InstallButton.width             = 104
    $InstallButton.height            = 60
    $InstallButton.location          = New-Object System.Drawing.Point(548,446)
    $InstallButton.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
    $InstallButton.Add_Click({Start-Install})

    $CommandoInstaller.controls.AddRange(@($CommandoLogo,$InstallButton,$ProfileSelector,$ConfigureProfileButton,$ProfileLabels,$RecommendedDiskSpaceLabel,$DisclaimerLabelLine1,$DisclaimerLabelLine2,$DisclaimerLabelLine3,$DisclaimerLabelLine4,$RecommendedDiskSpace))
    $ProfileLabels.controls.AddRange(@($ProfileLabelDescriptionLite,$Label1,$ProfileLabelLite,$ProfileLabelFull,$ProfileLabelDescriptionFull,$ProfileLabelDefault,$ProfileLabelDescriptionDefault,$ProfileLabelDeveloper,$ProfileLabelDescriptionDeveloper,$ProfileLabelVictim,$ProfileLabelDescriptionVictim))

    #################################################################################################
    ################################# Profile Manager Form Controls #################################
    #################################################################################################

    $CommandoProfileManager          = New-Object system.Windows.Forms.Form
    $CommandoProfileManager.ClientSize  = New-Object System.Drawing.Point(660,651)
    $CommandoProfileManager.text     = "CommandoVM Profile Manager"
    $CommandoProfileManager.TopMost  = $false
    $CommandoProfileManager.Icon     = $icon

    ################################# Profile Manager Preset Selector Controls #################################

    $PresetSelector                  = New-Object system.Windows.Forms.ComboBox
    $PresetSelector.text             = "Default"
    $PresetSelector.width            = 122
    $PresetSelector.height           = 20
    $PresetSelector.location         = New-Object System.Drawing.Point(252,11)
    $PresetSelector.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $PresetSelector.DropDownStyle   = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $PresetSelector.Add_SelectedIndexChanged({Set-ProfilePreset -ProfileName $PresetSelector.SelectedItem})

    $PresetSelectorLabel             = New-Object system.Windows.Forms.Label
    $PresetSelectorLabel.text        = "Preset"
    $PresetSelectorLabel.AutoSize    = $true
    $PresetSelectorLabel.width       = 25
    $PresetSelectorLabel.height      = 10
    $PresetSelectorLabel.location    = New-Object System.Drawing.Point(203,14)
    $PresetSelectorLabel.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    ################################# Profile Manager Package Installation Controls #################################

    $SelectedPackagesList            = New-Object system.Windows.Forms.ListBox
    $SelectedPackagesList.text       = "listBox"
    $SelectedPackagesList.width      = 232
    $SelectedPackagesList.height     = 266
    $SelectedPackagesList.location   = New-Object System.Drawing.Point(16,69)
    $SelectedPackagesList.Add_SelectedIndexChanged({
        # We're only gonna reset the available package selection if we have a selection in this listbox
        if ($SelectedPackagesList.SelectedIndex -ne -1) { 
            Set-PackageInformation -PackageName $SelectedPackagesList.SelectedItem
            $AvailablePackagesList.ClearSelected() 
        }
    })

    $AvailablePackagesList           = New-Object system.Windows.Forms.ListBox
    $AvailablePackagesList.text      = "listBox"
    $AvailablePackagesList.width     = 228
    $AvailablePackagesList.height    = 265
    $AvailablePackagesList.location  = New-Object System.Drawing.Point(318,69)
    $AvailablePackagesList.Add_SelectedIndexChanged({
        # We're only gonna reset the selected package selection if we have a selection in this listbox
        if ($AvailablePackagesList.SelectedIndex -ne -1) {
            Set-PackageInformation -PackageName $AvailablePackagesList.SelectedItem
            $SelectedPackagesList.ClearSelected()
        }
    })

    $SelectedPackagesLabel           = New-Object system.Windows.Forms.Label
    $SelectedPackagesLabel.text      = "Selected Packages"
    $SelectedPackagesLabel.AutoSize  = $true
    $SelectedPackagesLabel.width     = 25
    $SelectedPackagesLabel.height    = 10
    $SelectedPackagesLabel.location  = New-Object System.Drawing.Point(64,42)
    $SelectedPackagesLabel.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',12)

    $AvailablePackagesLabel          = New-Object system.Windows.Forms.Label
    $AvailablePackagesLabel.text     = "Available Packages"
    $AvailablePackagesLabel.AutoSize  = $true
    $AvailablePackagesLabel.width    = 25
    $AvailablePackagesLabel.height   = 10
    $AvailablePackagesLabel.location  = New-Object System.Drawing.Point(360,42)
    $AvailablePackagesLabel.Font     = New-Object System.Drawing.Font('Microsoft Sans Serif',12)

    ################################# Profile Manager Package Addition Controls #################################

    $PackageInstallationGroup        = New-Object system.Windows.Forms.Groupbox
    $PackageInstallationGroup.height = 367
    $PackageInstallationGroup.width  = 563
    $PackageInstallationGroup.text   = "Package Installation"
    $PackageInstallationGroup.location  = New-Object System.Drawing.Point(48,37)

    $AddPackageButton                = New-Object system.Windows.Forms.Button
    $AddPackageButton.text           = "<"
    $AddPackageButton.width          = 43
    $AddPackageButton.height         = 30
    $AddPackageButton.location       = New-Object System.Drawing.Point(260,103)
    $AddPackageButton.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $AddPackageButton.Add_Click({Add-SelectedPackage})

    $AddAllPackagesButton            = New-Object system.Windows.Forms.Button
    $AddAllPackagesButton.text       = "<<"
    $AddAllPackagesButton.width      = 43
    $AddAllPackagesButton.height     = 30
    $AddAllPackagesButton.location   = New-Object System.Drawing.Point(260,147)
    $AddAllPackagesButton.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $AddAllPackagesButton.Add_Click({Add-AllPackages})

    $RemovePackageButton             = New-Object system.Windows.Forms.Button
    $RemovePackageButton.text        = ">"
    $RemovePackageButton.width       = 43
    $RemovePackageButton.height      = 30
    $RemovePackageButton.location    = New-Object System.Drawing.Point(260,207)
    $RemovePackageButton.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $RemovePackageButton.Add_Click({Remove-SelectedPackage})

    $RemoveAllPackagesButton         = New-Object system.Windows.Forms.Button
    $RemoveAllPackagesButton.text    = ">>"
    $RemoveAllPackagesButton.width   = 43
    $RemoveAllPackagesButton.height  = 30
    $RemoveAllPackagesButton.location  = New-Object System.Drawing.Point(260,254)
    $RemoveAllPackagesButton.Font    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $RemoveAllPackagesButton.Add_Click({Remove-AllPackages})

    ################################# Profile Manager Package Count Labels #################################

    $SelectedCountLabel              = New-Object system.Windows.Forms.Label
    $SelectedCountLabel.text         = "Total:"
    $SelectedCountLabel.AutoSize     = $true
    $SelectedCountLabel.width        = 25
    $SelectedCountLabel.height       = 10
    $SelectedCountLabel.location     = New-Object System.Drawing.Point(15,342)
    $SelectedCountLabel.Font         = New-Object System.Drawing.Font('Microsoft Sans Serif',8)

    $AvailableCountLabel             = New-Object system.Windows.Forms.Label
    $AvailableCountLabel.text        = "Total:"
    $AvailableCountLabel.AutoSize    = $true
    $AvailableCountLabel.width       = 25
    $AvailableCountLabel.height      = 10
    $AvailableCountLabel.location    = New-Object System.Drawing.Point(316,340)
    $AvailableCountLabel.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',8)

    ################################# Profile Manager Package Information Controls #################################

    $PackageInformationGroup         = New-Object system.Windows.Forms.Groupbox
    $PackageInformationGroup.height  = 168
    $PackageInformationGroup.width   = 562
    $PackageInformationGroup.text    = "Package Information"
    $PackageInformationGroup.location  = New-Object System.Drawing.Point(48,424)

    $Authors                         = New-Object system.Windows.Forms.Label
    $Authors.text                    = "Authors"
    $Authors.AutoSize                = $false
    $Authors.AutoEllipsis            = $true
    $Authors.width                   = 450
    $Authors.height                  = 20
    $Authors.location                = New-Object System.Drawing.Point(70,25)
    $Authors.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $Version                         = New-Object system.Windows.Forms.Label
    $Version.text                    = "Version"
    $Version.AutoSize                = $true
    $Version.width                   = 25
    $Version.height                  = 10
    $Version.location                = New-Object System.Drawing.Point(70,50)
    $Version.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $Description                     = New-Object system.Windows.Forms.Label
    $Description.text                = "Tool Description"
    $Description.AutoSize            = $false
    $Description.width               = 529
    $Description.height              = 50
    $Description.location            = New-Object System.Drawing.Point(10,100)
    $Description.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

    $AuthorsLabel                    = New-Object system.Windows.Forms.Label
    $AuthorsLabel.text               = "Authors:"
    $AuthorsLabel.AutoSize           = $true
    $AuthorsLabel.width              = 25
    $AuthorsLabel.height             = 10
    $AuthorsLabel.location           = New-Object System.Drawing.Point(10,25)
    $AuthorsLabel.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $VersionLabel                    = New-Object system.Windows.Forms.Label
    $VersionLabel.text               = "Version:"
    $VersionLabel.AutoSize           = $true
    $VersionLabel.width              = 25
    $VersionLabel.height             = 10
    $VersionLabel.location           = New-Object System.Drawing.Point(10,50)
    $VersionLabel.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $DescriptionLabel                = New-Object system.Windows.Forms.Label
    $DescriptionLabel.text           = "Tool Description"
    $DescriptionLabel.AutoSize       = $true
    $DescriptionLabel.width          = 25
    $DescriptionLabel.height         = 10
    $DescriptionLabel.location       = New-Object System.Drawing.Point(10,75)
    $DescriptionLabel.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    ################################# Profile Manager Buttons #################################

    $DoneButton                      = New-Object system.Windows.Forms.Button
    $DoneButton.text                 = "Done"
    $DoneButton.width                = 94
    $DoneButton.height               = 30
    $DoneButton.location             = New-Object System.Drawing.Point(424,604)
    $DoneButton.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $DoneButton.Add_Click({
        Save-Profile
    
        # Check if "Custom" exists in $ProfileSelector.Items, and add it if it doesn't
        if ("Custom" -notin $ProfileSelector.Items) {
            $ProfileSelector.Items.Add("Custom")
        }
    
        # Set $ProfileSelector.Text to "Custom"
        $ProfileSelector.Text = "Custom"
    
        [void]$CommandoProfileManager.Close()
    })
    

    $SaveProfileButton               = New-Object system.Windows.Forms.Button
    $SaveProfileButton.text          = "Save Profile As"
    $SaveProfileButton.width         = 124
    $SaveProfileButton.height        = 30
    $SaveProfileButton.location      = New-Object System.Drawing.Point(115,604)
    $SaveProfileButton.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $SaveProfileButton.Add_Click({Save-ProfileAs})

    $ResetProfileButton              = New-Object system.Windows.Forms.Button
    $ResetProfileButton.text         = "Reset Profile"
    $ResetProfileButton.width        = 127
    $ResetProfileButton.height       = 30
    $ResetProfileButton.location     = New-Object System.Drawing.Point(269,604)
    $ResetProfileButton.Font         = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $ResetProfileButton.Add_Click({Set-ProfilePreset -ProfileName $selectedProfile})

    ################################# Profile Manager Form Constructor #################################

    $CommandoProfileManager.controls.AddRange(@($PackageInstallationGroup,$DoneButton,$SaveProfileButton,$ResetProfileButton,$PackageInformationGroup))
    $PackageInstallationGroup.controls.AddRange(@($SelectedPackagesLabel,$PresetSelectorLabel,$AddPackageButton,$AddAllPackagesButton,$RemovePackageButton,$RemoveAllPackagesButton,$PresetSelector,$AvailablePackagesLabel,$availableCountLabel,$selectedCountLabel,$SelectedPackagesList,$AvailablePackagesList))
    $PackageInformationGroup.controls.AddRange(@($AuthorsLabel,$Description,$DescriptionLabel,$VersionLabel,$Authors,$Version))
}

#################################################################################################
###################################### Installer Functions ######################################
#################################################################################################

################################# Functions that Get Profiles and Packages #################################

function Get-ProfileData {
    $profilesFolder = "./Profiles/"
    $profiles = @()

    # Loop over the profiles folder
    Get-ChildItem -Path $profilesFolder -Filter "*.xml" | ForEach-Object {
        $xmlContent = [xml](Get-Content $_.FullName)
        $profileName = $_.BaseName
        $diskSize = $xmlContent.config.envs.env | Where-Object { $_.name -eq "MIN_DISK_SPACE" } | Select-Object -ExpandProperty value

        # Write the profile metadata to a variable
        $profiles += [PSCustomObject]@{
            ProfileName = $profileName
            DiskSize    = $diskSize
            XmlPath     = $_.FullName
        }
    }

    return $profiles
}

function Get-PackagesFromProfile {
    param (
        [string]$ProfileName
    )

    # Get the XML profile path for the specified profile
    $profilePath = $global:profileData | Where-Object { $_.ProfileName -eq $ProfileName } | Select-Object -ExpandProperty XmlPath

    # Read the XML profile and pull the package names out
    if ($profilePath) {
        $xmlContent = [xml](Get-Content $profilePath)
        $packages = $xmlContent.config.packages.package
        return $packages
    }
    else {
        Write-Host "[!] Profile not found." -ForegroundColor Red
        return @()
    }
}

function Get-AvailablePackages {
    $apiUrl = "https://www.myget.org/F/vm-packages/Packages"
    $destination = "./available_packages.xml"

    # Download the XML from MyGet API
    try {
        # Download the XML from MyGet API
        Invoke-WebRequest -Uri $apiUrl -OutFile $destination -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to download available_packages.xml. Error: $_"
        return
    }

    # Load the XML content
    $xmlContent = [xml](Get-Content $destination)

    $packages = @()

    # Define XML namespaces
    $nsManager = New-Object -TypeName "System.Xml.XmlNamespaceManager" -ArgumentList $xmlContent.NameTable
    $nsManager.AddNamespace("atom", "http://www.w3.org/2005/Atom")
    $nsManager.AddNamespace("d", "http://schemas.microsoft.com/ado/2007/08/dataservices")
    $nsManager.AddNamespace("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata")

    # Extract package information from the XML
    $xmlContent.SelectNodes("//atom:entry", $nsManager) | ForEach-Object {
        $isLatestVersion = $_.SelectSingleNode("m:properties/d:IsLatestVersion", $nsManager).InnerText

        # There are multiple versions of packages, but we only display the latest
        if ($isLatestVersion -eq "true") {
            $packageName = $_.SelectSingleNode("m:properties/d:Id", $nsManager).InnerText
            $packageAuthor = $_.SelectSingleNode("atom:author/atom:name", $nsManager).InnerText
            $packageVersion = $_.SelectSingleNode("m:properties/d:Version", $nsManager).InnerText
            $packageSummary = $_.SelectSingleNode("m:properties/d:Description", $nsManager).InnerText

            $packages += [PSCustomObject]@{
                PackageName   = $packageName
                PackageAuthor = $packageAuthor
                PackageVersion = $packageVersion
                PackageSummary = $packageSummary
            }
        }
    }

    return $packages
}

################################# Functions that Set GUI Controls #################################

function Set-SelectedPackages {
    
    # Get the packages for the specified profile
    $packagesFromProfile = Get-PackagesFromProfile -ProfileName $global:selectedProfile

    # Update the SelectedPackagesList with the packages from the profile
    $SelectedPackagesList.Items.Clear()
    $SelectedPackagesList.Items.AddRange($packagesFromProfile.name)

    # Update the count labels
    $SelectedCountLabel.text = "Total: $($SelectedPackagesList.Items.count)"
}

function Set-AvailablePackages {
    
    # Update the AvailablePackagesList with all the package names from the $global:packageData that are not in the $SelectedPackagesList.Items
    $AvailablePackagesList.Items.Clear()

    $filteredPackages = $global:packageData.PackageName | Where-Object { $_ -notin $SelectedPackagesList.Items }
    
    # Add items only if there are items to add
    if ($filteredPackages.Count -gt 0) {
        $AvailablePackagesList.Items.AddRange($filteredPackages)
    }

    # Update the count labels
    $AvailableCountLabel.text = "Total: $($AvailablePackagesList.Items.count)"
}



function Set-PackageInformation {
    param (
        [string]$PackageName
    )

    # Get the available package list
    $package = $global:packageData | Where-Object { $_.PackageName -eq $PackageName }

    # Populate the package information fields
    if ($package) {
        $global:Description.Text = $package.PackageSummary
        $global:Authors.Text     = $package.PackageAuthor
        $global:Version.Text     = $package.PackageVersion
    } else {
        Write-Host "[!] Package not found."
    }
}

function Set-ProfilePreset {
    param (
        [string]$ProfileName
    )

    # Change the selected profile
    $global:selectedProfile = $ProfileName

    # Re-render the package lists
    Set-SelectedPackages
    Set-AvailablePackages

    # Set the package info to the first package in the selected list
    Set-PackageInformation -PackageName $SelectedPackagesList.Items[0]
}

################################# Functions that Select Packages #################################

function Add-SelectedPackage {

    $selectedItem = $AvailablePackagesList.SelectedItem

    # Move the selected package over to selected listbox from available
    if ($selectedItem) {
        $SelectedPackagesList.Items.Add($selectedItem)
        $AvailablePackagesList.Items.Remove($selectedItem)

        # Update the total counts
        $SelectedCountLabel.Text = "Total: $($SelectedPackagesList.Items.Count)"
        $AvailableCountLabel.Text = "Total: $($AvailablePackagesList.Items.Count)"
    }
}

function Add-AllPackages {
    # Move all items from $AvailablePackagesList.Items to $SelectedPackagesList.Items
    foreach ($item in $AvailablePackagesList.Items) {
        $SelectedPackagesList.Items.Add($item)
    }

    # Empty out the $AvailablePackagesList.Items
    $AvailablePackagesList.Items.Clear()

    # Update the count labels
    $SelectedCountLabel.text = "Total: $($SelectedPackagesList.Items.Count)"
    $AvailableCountLabel.text = "Total: $($AvailablePackagesList.Items.Count)"
}

function Remove-SelectedPackage {
    $selectedItem = $SelectedPackagesList.SelectedItem

    # Move over the selected package from selected list to available
    if ($selectedItem) {
        $AvailablePackagesList.Items.Add($selectedItem)
        $SelectedPackagesList.Items.Remove($selectedItem)

        # Update the total counts
        $SelectedCountLabel.Text = "Total: $($SelectedPackagesList.Items.Count)"
        $AvailableCountLabel.Text = "Total: $($AvailablePackagesList.Items.Count)"
    }
}

function Remove-AllPackages {

    # Add each item from selected to available
    foreach ($item in $SelectedPackagesList.Items) {
        $AvailablePackagesList.Items.Add($item)
    }

    # Clear out the selected listbox
    $SelectedPackagesList.Items.Clear()

    $SelectedCountLabel.Text = "Total: $($SelectedPackagesList.Items.Count)"
    $AvailableCountLabel.Text = "Total: $($AvailablePackagesList.Items.Count)"
}

################################# Functions that Save Profiles #################################

function Save-Profile {
    param (
        [string]$ProfilePath = "$(Join-Path -Path ".\Profiles" -ChildPath "Custom.xml")"
    )

    # Get the path to the XML of the preset we're basing the profile on and read it into memory
    $selectedProfilePath = ($global:profileData | Where-Object { $_.ProfileName -eq $global:selectedProfile }).XmlPath
    [xml]$xmlContent = Get-Content -Path $selectedProfilePath

    # Remove the profile if one already exists with the same name
    if (Test-Path -Path $ProfilePath) {
        Remove-Item -Path $ProfilePath -Force
    }

    # Clear out the packages section of the preset
    $packagesNode = $xmlContent.config.packages
    $packagesNode.RemoveAll()

    # Overwrite the packages section with our own from the selected packages listbox
    foreach ($item in $SelectedPackagesList.Items) {
        $packageNode = $xmlContent.CreateElement("package")
        $packageNode.SetAttribute("name", $item)
        $packagesNode.AppendChild($packageNode)
    }

    $xmlContent.Save($ProfilePath)
}

function Save-ProfileAs {

    $Title = "Save CommandoVM Profile As"
    $Filter = "XML Files (*.xml)|*.xml|All Files (*.*)|*.*"
    $InitialDirectory = Join-Path $PSScriptRoot ".\Profiles"

    # Create a save-as dialog window at the profiles directory
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = $Title
    $saveFileDialog.Filter = $Filter
    $saveFileDialog.InitialDirectory = $InitialDirectory

    $result = $saveFileDialog.ShowDialog()

    # If the user picks a file location, we will pass it to Save-Profile
    if ($result -eq "OK") {
        Save-Profile -ProfilePath $saveFileDialog.FileName
    }
}

################################# Functions that Open GUI Windows #################################

function Open-Installer {

    # Populate the profile selector combo box
    $ProfileSelector.Items.Clear()
    $ProfileSelector.Items.AddRange($global:profileData.ProfileName)

    # Set the value of the profile selector to default
    $ProfileSelector.Text = $global:selectedProfile

    [void]$CommandoInstaller.ShowDialog()
}

function Open-ProfileManager {

    # Populate the combo box with profile names from the $global:profileData array
    $PresetSelector.Items.Clear()
    $PresetSelector.Items.AddRange($global:profileData.ProfileName)

    # Set the value of $PresetSelector.Text to $global:selectedProfile
    $PresetSelector.Text = $global:selectedProfile

    # Render the package lists
    Set-SelectedPackages
    Set-AvailablePackages

    # Set the package info to the first package in the selected list
    Set-PackageInformation -PackageName $SelectedPackagesList.Items[0]

    [void]$CommandoProfileManager.ShowDialog()
}

#################################################################################################
###################################### Installer Workflows ######################################
#################################################################################################

# Fetch profiles and packages
$global:profileData = Get-ProfileData
$global:packageData = Get-AvailablePackages
$global:selectedProfile = "Default"

################################# GUI Workflow #################################

if (-not $noGui.IsPresent) {

    # Draw the profile manager GUI
    Open-Installer
}

################################# CLI Workflow #################################

if ($noGui.IsPresent) {

    Write-Host "[!] Not implemented yet"
}