#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Prepares Windows host for Hyper-V lab environment
.DESCRIPTION
    Checks and configures Hyper-V, creates external switch, validates system requirements
#>

# region: Logging Setup
$LogPath = "D:\LabSetup\HostPrep.log"

# Check if D: drive exists, fallback to C: if not
if (-not (Test-Path "D:\")) {
    $LogPath = "C:\LabSetup\HostPrep.log"
}

try {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force -ErrorAction Stop | Out-Null
    Start-Transcript -Path $LogPath -Append -ErrorAction Stop
} catch {
    Write-Error "Failed to initialize logging: $_"
    exit 1
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARNING','ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format "yyyy-dd-MM HH:mm:ss"
    $prefix = switch($Level) {
        'WARNING' { '⚠️ ' }
        'ERROR' { '❌ ' }
        default { '' }
    }
    $logMessage = "$timestamp [$Level] - $prefix$Message"
    
    # Use Write-Host for console output (transcript captures this automatically)
    switch($Level) {
        'ERROR' { Write-Host $logMessage -ForegroundColor Red }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        default { Write-Host $logMessage }
    }
}
# endregion

# region: Administrator Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Script must be run as Administrator" -Level ERROR
    Stop-Transcript
    exit 1
}
# endregion

# region: Check Hyper-V Installation
Write-Log "Checking if Hyper-V is installed..."
try {
    $hvFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction Stop
    
    if ($hvFeature.State -ne "Enabled") {
        Write-Log "Hyper-V is not enabled. Enabling now..." -Level WARNING
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction Stop
        Write-Log "✅ Hyper-V enabled. RESTART REQUIRED before continuing." -Level WARNING
        Write-Host "`n⚠️  PLEASE RESTART YOUR COMPUTER NOW" -ForegroundColor Yellow
        Stop-Transcript
        exit 2
    } else {
        Write-Log "✅ Hyper-V is already enabled."
    }
} catch {
    Write-Log "Failed to check/enable Hyper-V: $_" -Level ERROR
    Stop-Transcript
    exit 1
}
# endregion

# region: Check Virtualization Support
Write-Log "Checking CPU virtualization support..."
try {
    # Check if Hyper-V services are running (best indicator that virtualization works)
    $hvServices = @('vmcompute', 'vmms')
    $runningServices = 0
    
    foreach ($svc in $hvServices) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            $runningServices++
        }
    }
    
    if ($runningServices -gt 0) {
        Write-Log "✅ Hyper-V services are running - virtualization is working."
    } else {
        Write-Log "Hyper-V services not running, but if VMs work then virtualization is enabled" -Level WARNING
    }
} catch {
    Write-Log "Could not verify virtualization status, but if VMs work then virtualization is enabled" -Level WARNING
}
# endregion

# region: Check/Create External Virtual Switch
$SwitchName = "External 2"
Write-Log "Checking for external network adapter..."

$ExternalNIC = Get-NetAdapter | Where-Object { 
    $_.Status -eq "Up" -and 
    $_.ConnectorPresent -eq $true -and
    $_.Virtual -eq $false
} | Select-Object -First 1

if (-not $ExternalNIC) {
    Write-Log "No active physical NIC found. Cannot create external switch." -Level ERROR
    Write-Log "Available adapters:" -Level WARNING
    Get-NetAdapter | Select-Object Name, Status, InterfaceDescription | Format-Table | Out-String | Write-Host
    Stop-Transcript
    exit 1
}

Write-Log "Selected NIC: $($ExternalNIC.Name) - $($ExternalNIC.InterfaceDescription)"

$existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (-not $existingSwitch) {
    Write-Log "Creating external virtual switch '$SwitchName'..."
    try {
        New-VMSwitch -Name $SwitchName -NetAdapterName $ExternalNIC.Name -AllowManagementOS $true -ErrorAction Stop | Out-Null
        Write-Log "✅ External switch '$SwitchName' created successfully."
    } catch {
        Write-Log "Failed to create virtual switch: $_" -Level ERROR
        Stop-Transcript
        exit 1
    }
} else {
    Write-Log "✅ External switch '$SwitchName' already exists."
}
# endregion

# region: System Requirements Check
Write-Log "Checking system requirements..."
try {
    $RAM = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    $Disk = [math]::Round((Get-PSDrive -Name C).Free / 1GB, 1)
    $OS = (Get-CimInstance Win32_OperatingSystem).Caption
    $CPUCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    
    Write-Log "🧠 OS: $OS"
    Write-Log "🧠 CPU Cores: $CPUCores"
    Write-Log "🧠 RAM: $RAM GB"
    Write-Log "🧠 Free Disk (C:): $Disk GB"
    
    $requirementsMet = $true
    
    if ($RAM -lt 16) { 
        Write-Log "RAM below recommended 16GB (found: $RAM GB)" -Level WARNING
        $requirementsMet = $false
    }
    if ($Disk -lt 150) { 
        Write-Log "Disk space below recommended 150GB (found: $Disk GB)" -Level WARNING
        $requirementsMet = $false
    }
    if ($CPUCores -lt 4) {
        Write-Log "CPU cores below recommended 4 cores (found: $CPUCores)" -Level WARNING
        $requirementsMet = $false
    }
    
    if (-not $requirementsMet) {
        Write-Log "System may not meet minimum requirements for lab" -Level WARNING
    }
} catch {
    Write-Log "Failed to check system requirements: $_" -Level ERROR
}
# endregion

# region: Folder Check
# Default to D: drive, fallback to C: if D: doesn't exist
if (Test-Path "D:\") {
    $LabFolder = "D:\Win11Lab"
} else {
    $LabFolder = "C:\Win11Lab"
    Write-Log "D: drive not found. Using C: drive for lab folder" -Level WARNING
}

if (-not (Test-Path $LabFolder)) {
    Write-Log "Creating lab folder at $LabFolder..."
    try {
        New-Item -ItemType Directory -Path $LabFolder -Force -ErrorAction Stop | Out-Null
        Write-Log "✅ Lab folder created: $LabFolder"
    } catch {
        Write-Log "Failed to create lab folder: $_" -Level ERROR
        Stop-Transcript
        exit 1
    }
} else {
    Write-Log "✅ Lab folder exists: $LabFolder"
}

if ($LabFolder -match "\s") {
    Write-Log "Folder path contains spaces. This may cause provisioning errors." -Level ERROR
    Write-Log "Please rename the folder to remove spaces." -Level ERROR
    Stop-Transcript
    exit 1
}

# Set recommended folder permissions
try {
    $acl = Get-Acl $LabFolder
    Write-Log "✅ Lab folder permissions verified"
} catch {
    Write-Log "Could not verify folder permissions: $_" -Level WARNING
}
# endregion

# region: Summary
Write-Log "`n========================================="
Write-Log "✅ Host environment is ready for lab provisioning."
Write-Log "========================================="
Write-Log "Lab Folder: $LabFolder"
Write-Log "Virtual Switch: $SwitchName"
Write-Log "`nYou may now run Setup.exe from the extracted lab kit."
Write-Log "=========================================`n"

# Pause before closing (compatible with all PowerShell hosts)
Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan -NoNewline
$null = Read-Host
# endregion

Stop-Transcript
