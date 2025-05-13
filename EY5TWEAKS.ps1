<#
.EY5 TWEAKS - Fully Functional Version
.DESCRIPTION
 Windows optimization tool with complete tweak implementations
.NOTES
 Version: 3.0
 Author: EY5 TWEAKS
 GitHub: https://github.com/iiey5/ey5-tweaks
#>

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Admin Elevation Check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

#region GUI Configuration
$form = New-Object System.Windows.Forms.Form
$form.Text = "EY5 TWEAKS"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.BackColor = [System.Drawing.Color]::Black
$form.ForeColor = [System.Drawing.Color]::Goldenrod
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\System32\cmd.exe")
#endregion

#region Tweak Implementations
$tweakActions = @{
    # Essential Tweaks
    "Create Restore Point" = {
        Checkpoint-Computer -Description "EY5 Tweak Restore Point" -RestorePointType "MODIFY_SETTINGSINGS"
    }

    "Delete Temporary Files" = {
        Get-ChildItem -Path $env:TEMP, "$env:SystemRoot\Temp" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    "Disable Telemetry" = {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value 0 -Force
    }

    "Disable Hibernation" = {
        powercfg /hibernate off
    }

    "Remove OneDrive" = {
        taskkill /f /im OneDrive.exe > $null 2>&1
        Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
        Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Performance Plans
    "Add Ultimate Performance Profile" = {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    }

    "Disable Microsoft Copilot" = {
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot") {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Force
        }
    }
}

$undoActions = @{
    "Disable Telemetry" = {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Force -ErrorAction SilentlyContinue
    }

    "Disable Hibernation" = {
        powercfg /hibernate on
    }

    "Add Ultimate Performance Profile" = {
        powercfg -delete e9a42b02-d5df-448d-aa00-03f14749eb61
    }
}
#endregion

#region GUI Elements
$flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowPanel.AutoScroll = $true

# Create checkboxes dynamically
foreach ($tweakName in $tweakActions.Keys) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $tweakName
    $cb.Width = 400
    $cb.Height = 30
    $cb.ForeColor = [System.Drawing.Color]::Goldenrod
    $cb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $flowPanel.Controls.Add($cb)
}

# Action Buttons
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Apply Selected Tweaks"
$runButton.Width = 200
$runButton.Height = 40
$runButton.BackColor = [System.Drawing.Color]::Goldenrod
$runButton.ForeColor = [System.Drawing.Color]::Black
$runButton.Add_Click({
    foreach ($control in $flowPanel.Controls) {
        if ($control -is [System.Windows.Forms.CheckBox] -and $control.Checked) {
            $tweakName = $control.Text
            try {
                if ($tweakActions.ContainsKey($tweakName)) {
                    & $tweakActions[$tweakName]
                    [System.Windows.Forms.MessageBox]::Show("Successfully applied: $tweakName", "EY5 TWEAKS", "OK", "Information")
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to apply $tweakName`nError: $_", "Error", "OK", "Error")
            }
        }
    }
})

$undoButton = New-Object System.Windows.Forms.Button
$undoButton.Text = "Undo Selected Tweaks"
$undoButton.Width = 200
$undoButton.Height = 40
$undoButton.BackColor = [System.Drawing.Color]::DarkGoldenrod
$undoButton.ForeColor = [System.Drawing.Color]::White
$undoButton.Add_Click({
    foreach ($control in $flowPanel.Controls) {
        if ($control -is [System.Windows.Forms.CheckBox] -and $control.Checked) {
            $tweakName = $control.Text
            try {
                if ($undoActions.ContainsKey($tweakName)) {
                    & $undoActions[$tweakName]
                    [System.Windows.Forms.MessageBox]::Show("Successfully reverted: $tweakName", "EY5 TWEAKS", "OK", "Information")
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to revert $tweakName`nError: $_", "Error", "OK", "Error")
            }
        }
    }
})

# Add controls to form
$form.Controls.Add($flowPanel)
$form.Controls.Add($runButton)
$form.Controls.Add($undoButton)

# Position buttons
$runButton.Location = New-Object System.Drawing.Point(800, 700)
$undoButton.Location = New-Object System.Drawing.Point(550, 700)
#endregion

# Show form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()