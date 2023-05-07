<#
.Synopsis
    Update cloudflared
.DESCRIPTION
    Automate the update process for users running cloudflared
.NOTES
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!! THIS IS NOT CREATED NOR MAINTAINED BY CLOUDFLARE !!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Author:         Dubz
    Discord:        Dubz#0001 | https://discord.gg/cloudflaredev
    Version:        2023.05.07
    Creation:       2023-05-07
    Hosted at:      https://cloudflared.app/update.ps1
#>

# Find executables (configure as needed)
param(
    # Name of Cloudflared service
    [string]$service = "cloudflared",

    # Name of executable
    [string]$filename = "cloudflared.exe",

    # Try and find the executable using environmental paths
    [string]$cloudflared_path = (get-command $filename).Path,

    # Cloudflare seems to default the update path to "*.new"
    [string]$cloudflared_path_new = $cloudflared_path + ".new",
    # UPDATE: Later versions replace the file and rename the current to "*.old"
    # This was changed around 2023.5.0
    [string]$cloudflared_path_old = $cloudflared_path + ".old",

    # Commands used by cloudflared
    [string]$cloudflared_command_update = $cloudflared_path + " update",
    [string]$cloudflared_command_version = $cloudflared_path + " version",

    # Run cloudflared update for us?
    [switch]$cloudflared_run_update = $true
)


# Enforce Administrator rights

#Requires -RunAsAdministrator

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host ("Administrative rights are required for this script to run properly.")
    Start-Sleep 5
    Exit
}


# Test for files (Is cloudflared.exe found, or does it even need updated?)
If (!(Test-Path -LiteralPath $cloudflared_path -PathType Leaf)) {
    Write-Host ($filename + " not found, exiting.")
    Start-Sleep 3
    Exit
}

Write-Host ("Cloudflared found, getting current version:")
iex $cloudflared_command_version
Write-Host ("")

# Is the service currently running?
# Moved here now since the update replaces the file properly but does not restart the service
# Backwards compatible as the order did not matter initially
$running = ((Get-Service -Name $service).Status -eq "Running")
if($running) {
    Write-Host ("cloudflared service: running")
}
Else {
    Write-Host ("cloudflared service: stopped")
}

# Run update command
if ($cloudflared_run_update) {
    iex $cloudflared_command_update
    # Pause for 2 seconds to allow the update to complete file renames before continuing
    Start-Sleep 2
}

# Is there an updated binary?
If (!(Test-Path -LiteralPath $cloudflared_path_old -PathType Leaf)) {
    Write-Host ("Old binary not found")
    If (!(Test-Path -LiteralPath $cloudflared_path_new -PathType Leaf)) {
        Write-Host ("LEGACY CHECK: New binary not found either, exiting.")
        Start-Sleep 3
        Exit
    }
    Else {
        # Legacy update found, continuing...

        # If so, stop it so we can remove the old binary and move the new one to its place
        if ($running -And !(Test-Path -LiteralPath $cloudflared_path_new -PathType Leaf)) {
            # Stop the service
            Stop-Service $service;
        }

        # Remove
        rm $cloudflared_path

        # Move/replace
        mv $cloudflared_path_new $cloudflared_path;

        # Restart the service if it was running previously
        if ($running) {
            # Start back up
            Write-Host ("Starting cloudflared service back up...")
            Start-Service $service;
        }

        Write-Host ("LEGACY UPDATE: Cloudflared has been updated!")
        iex $cloudflared_command_version
        Start-Sleep 3
        Exit
    }
}
Else {
    # Nothing to do as the update does 95% of the work now
    # Restart the service if it was running previously
    # For some reason, the native update returns the service state to its polar opposite. We fix that here.
    if ($running) {
        # Start back up
        If((Get-Service -Name $service).Status -eq "Running") {
            Write-Host ("Service already running!")
        }
        Else {
            Write-Host ("Starting cloudflared service back up...")
            Start-Service $service;
        }
    }
    Else {
        If(((Get-Service -Name $service).Status -ne "Running")) {
            Write-Host ("Service already stopped!")
        }
        Else {
            Write-Host ("Service was stopped before, but the update starts it.")
            Write-Host ("Stopping service to match original state...")
            Stop-Service $service;
        }
    }

    Write-Host ("Cloudflared has been updated!")
    Write-Host ("Please delete the old binary at: " + $cloudflared_path_old)
    iex $cloudflared_command_version
    Start-Sleep 3
    Exit
}
