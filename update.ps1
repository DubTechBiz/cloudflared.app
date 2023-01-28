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
    Version:        1.0
    Creation:       2023-01-28
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

    # Commands used by cloudflared
    [string]$cloudflared_command_update = $cloudflared_path + " update",
    [string]$cloudflared_command_version = $cloudflared_path + " version",

    # Run cloudflared update for us?
    [switch]$cloudflared_run_update = $true
)


# Test for files (Is it found, or does it even need updated?)
If (!(Test-Path -LiteralPath $cloudflared_path -PathType Leaf)) {
    Write-Host ($filename + " not found, exiting.")
    Start-Sleep 3
    Exit
}

Write-Host ("Cloudflared found, getting current version:")
iex $cloudflared_command_version
Write-Host ("")

# Run update command
if ($cloudflared_run_update) {
    iex $cloudflared_command_update
}

# Is there an updated binary?
If (!(Test-Path -LiteralPath $cloudflared_path_new -PathType Leaf)) {
    Write-Host ("New binary not found, exiting.")
    Start-Sleep 3
    Exit
}


# Update found, continuing...

# Is the service currently running?
$running = ((Get-Service -Name $service).Status -eq "Running")

# If so, stop it so we can remove the old binary and move the new one to its place
if ($running) {
    # Stop the service
    Stop-Service $service;
}

# Remove
rm $cloudflared_path

# Move
mv $cloudflared_path_new $cloudflared_path;

# Restart the service if it was running previously
if ($running) {
    # Start back up
    Start-Service $service;
}

Write-Host ("Cloudflared has been updated!")
iex $cloudflared_command_version
Start-Sleep 3
Exit
