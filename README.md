# Windows 11 & Office 365 Lab Kit - Host Preparation Script

## Executive Summary

This PowerShell script automates the preparation of your Windows host machine for the [Microsoft Windows 11 & Office 365 Evaluation Lab Kit](https://www.microsoft.com/en-gb/evalcenter/download-windows-11-office-365-lab-kit). It verifies system requirements, enables Hyper-V if needed, creates the necessary virtual networking infrastructure, and sets up the lab folder structure—saving you time and reducing configuration errors.

**What it does:**
- ✅ Checks and enables Hyper-V if not already installed
- ✅ Creates an external virtual switch for VM networking
- ✅ Validates system meets minimum requirements (RAM, disk space, CPU)
- ✅ Sets up the lab folder structure (defaults to D: drive, falls back to C:)
- ✅ Provides detailed logging for troubleshooting
- ✅ Verifies virtualization support

**Usage:** Run the script as Administrator before extracting and running the Microsoft lab Setup.exe.

---

## About the Microsoft Lab Kit

The Windows 11 & Office 365 Lab Kit is a comprehensive hands-on evaluation environment provided by Microsoft for IT professionals to test Windows 11 deployment, management, and Office 365 integration in a safe, isolated virtual environment.

**Lab Kit Details:**
- **Source:** [Microsoft Evaluation Center](https://www.microsoft.com/en-gb/evalcenter/download-windows-11-office-365-lab-kit)
- **Expiration:** VMs expire 90 days after provisioning
- **Purpose:** Evaluation and testing only—not for production use
- **Target Audience:** IT professionals managing corporate networks and devices

---

## Prerequisites

### System Requirements

Your Hyper-V host machine must meet these minimum specifications:

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Operating System** | Windows 10/11 or Windows Server 2016 (64-bit) | Windows 11 Pro or Enterprise |
| **RAM** | 16 GB | 32 GB or more |
| **Free Disk Space** | 150 GB | 300 GB or more |
| **CPU** | 4+ cores with virtualization support | 8+ cores, high-end processor |
| **Disk Subsystem** | Standard HDD | SSD or NVMe for best performance |
| **Hyper-V** | Must be enabled | - |
| **User Rights** | Administrator access required | - |
| **Network** | Active network adapter | Ethernet (Wi-Fi supported but not ideal) |

### Additional Requirements

- **BIOS/UEFI:** CPU virtualization must be enabled (Intel VT-x or AMD-V)
- **Internet:** High-bandwidth connection recommended for downloading the ~20GB lab kit
- **Time:** Allow 1-2 hours for download and initial setup

---

## Installation & Usage

### Step 1: Download This Script

1. Download the `HostPrep.ps1` script from this repository
2. Save it to a convenient location (e.g., `C:\Temp\`)

### Step 2: Run the Preparation Script

Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
cd C:\Temp
.\HostPrep.ps1
```

The script will:
- Check if Hyper-V is installed (and enable it if needed—requires restart)
- Create an external virtual switch named "External 2"
- Validate your system meets minimum requirements
- Create the lab folder at `D:\Win11Lab` (or `C:\Win11Lab` if D: doesn't exist)
- Generate a detailed log at `D:\LabSetup\HostPrep.log`

### Step 3: Restart (if required)

If the script enables Hyper-V, you'll be prompted to restart your computer. Run the script again after restarting.

### Step 4: Download the Microsoft Lab Kit

1. Visit the [Microsoft Evaluation Center](https://www.microsoft.com/en-gb/evalcenter/download-windows-11-office-365-lab-kit)
2. Download the lab kit (approximately 20 GB)
3. Extract the downloaded files to your lab folder (`D:\Win11Lab` or `C:\Win11Lab`)

### Step 5: Run the Lab Setup

1. Navigate to the extracted lab kit folder
2. Run `Setup.exe` as Administrator
3. Follow the on-screen instructions to provision the lab environment

---

## Script Features

### Automatic Checks

- **Hyper-V Installation:** Detects and enables Hyper-V if missing
- **Virtualization Support:** Verifies CPU virtualization is enabled
- **System Resources:** Checks RAM, disk space, and CPU cores
- **Network Adapters:** Automatically selects the best physical NIC for external switching
- **Path Validation:** Ensures lab folder paths don't contain spaces (prevents provisioning errors)

### Intelligent Defaults

- **Drive Selection:** Prefers D: drive for lab files, automatically falls back to C: if unavailable
- **Logging:** All operations logged to `D:\LabSetup\HostPrep.log` (or `C:\LabSetup\HostPrep.log`)
- **Error Handling:** Graceful failure with clear error messages and exit codes

### Color-Coded Output

- **🟢 Green:** Successful operations
- **🟡 Yellow:** Warnings (non-critical issues)
- **🔴 Red:** Errors (require attention)

---

## Troubleshooting

### "Hyper-V is not enabled"

**Solution:** The script will attempt to enable Hyper-V automatically. You'll need to restart your computer after this step.

### "CPU virtualization is not enabled"

**Solution:** 
1. Restart your computer
2. Enter BIOS/UEFI settings (usually F2, F10, DEL, or ESC during boot)
3. Look for "Virtualization Technology", "VT-x", "AMD-V", or "SVM Mode"
4. Enable it and save changes

### "No active external NIC found"

**Solution:** 
- Ensure you have an active network connection (Ethernet preferred)
- Check that your network adapter is enabled in Device Manager
- The script filters out virtual adapters—make sure you have a physical NIC connected

### "Insufficient disk space"

**Solution:**
- Free up disk space on your C: or D: drive
- Consider using an external SSD/HDD for the lab environment
- Minimum 150 GB required, 300 GB recommended

### "External switch creation failed"

**Solution:**
- Ensure no other application is using the network adapter
- Try disabling and re-enabling your network adapter
- Check Windows Event Viewer for Hyper-V errors

---

## Log Files

The script generates a detailed transcript log:

**Location:** 
- `D:\LabSetup\HostPrep.log` (default)
- `C:\LabSetup\HostPrep.log` (if D: drive unavailable)

**Contents:**
- Timestamp of all operations
- System configuration details
- Success/warning/error messages
- Full PowerShell command output

Review this log if you encounter issues during setup.

---

## Important Notes

### ⚠️ Evaluation Environment Only

This lab is designed for **evaluation and testing purposes only**. Do not:
- Connect it to your production environment
- Use it for production workloads
- Store sensitive or business-critical data in the lab VMs

### ⏰ VM Expiration

The Windows 11 VMs in this lab **expire 90 days** after provisioning. Plan your evaluation accordingly.

### 🔒 Security Considerations

- The lab uses pre-configured credentials—change them if exposing to any network
- Keep the lab isolated from production networks
- Do not use the lab for internet-facing services

### 💾 Storage Recommendations

- **SSD/NVMe:** Strongly recommended for acceptable VM performance
- **HDD:** Will work but expect slower boot times and application performance
- **External drives:** Supported but may impact performance

---

## Exit Codes

The script uses the following exit codes:

| Code | Meaning |
|------|---------|
| `0` | Success - host is ready |
| `1` | General error (see log for details) |
| `2` | Restart required (Hyper-V was enabled) |

---

## Technical Details

### Virtual Switch Configuration

The script creates an external virtual switch named **"External 2"** with the following characteristics:

- **Type:** External
- **Management OS Sharing:** Enabled (allows host to use the network adapter)
- **NIC Selection:** Automatically selects the first active physical network adapter
- **Purpose:** Allows VMs to communicate with the external network and internet

### System Validation Logic

```powershell
# RAM Check
$RAM = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
if ($RAM -lt 16) { Warning: Below minimum }

# Disk Space Check
$Disk = (Get-PSDrive -Name C).Free / 1GB
if ($Disk -lt 150) { Warning: Below minimum }

# CPU Core Check
$CPUCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
if ($CPUCores -lt 4) { Warning: Below minimum }
```

### Virtualization Detection

The script checks for running Hyper-V services (`vmcompute` and `vmms`) as the most reliable indicator of working virtualization, rather than relying on WMI properties which can be inaccurate.

---

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page or submit a pull request.

---

## License

This script is provided as-is for use with the Microsoft Windows 11 & Office 365 Evaluation Lab Kit. The Microsoft lab kit itself is subject to Microsoft's evaluation license terms.

---

## Support

For issues related to:
- **This script:** Open an issue in this repository
- **The Microsoft Lab Kit:** Refer to Microsoft's [Evaluation Center support](https://www.microsoft.com/en-gb/evalcenter)
- **Hyper-V:** Consult [Microsoft Hyper-V documentation](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/)

---

## Acknowledgments

- Microsoft for providing the comprehensive evaluation lab kit
- The PowerShell community for best practices and patterns

---

**Last Updated:** November 2025  
**Script Version:** 1.0  
**Tested On:** Windows 11 Pro (Build 26200)
