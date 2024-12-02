<#
=================================================================================
 Title: Get-WindowsAutopilotInfo Upload to Azure Blob
 Author: vdBurgIT
 Version: 2.1

 Description:
     Dit script verzamelt de Windows Autopilot hardware-ID van het apparaat
     en uploadt deze naar een Azure Blob Storage-container via AzCopy.

 Updates:
     - Prefix voor CSV-bestandsnaam gewijzigd naar "AID_".
     - Meest recente versie van AzCopy wordt automatisch opgehaald van GitHub.

 Instructies:
     1. Zorg ervoor dat het apparaat internettoegang heeft.
     2. Stel een SAS URL in via de "Environment Vars" in Tactical RMM
        met de sleutel "SasURL".
     3. Het script downloadt en gebruikt de nieuwste AzCopy om het CSV-bestand te uploaden.
     4. Controleer of de SAS URL geldig is en toegang biedt tot de container.

 Environment Variables:
     - SasURL: De volledige SAS URL voor de Azure Blob Storage-container.

=================================================================================
#>

# Begin script

# Controleer of de SAS URL is ingesteld
if (-not $env:SasURL) {
    Write-Error "De SAS URL is niet ingesteld. Controleer de Environment Vars in Tactical RMM."
    exit 1
}

# Functie om de nieuwste AzCopy-release van GitHub op te halen
Function Get-LatestAzCopy {
    $GitHubApiUrl = "https://api.github.com/repos/Azure/azure-storage-azcopy/releases/latest"
    $Headers = @{ "User-Agent" = "PowerShell-Script" }
    $Response = Invoke-RestMethod -Uri $GitHubApiUrl -Headers $Headers -Method Get
    $DownloadUrl = $Response.assets | Where-Object { $_.name -like "*windows.zip" } | Select-Object -ExpandProperty browser_download_url
    if (-not $DownloadUrl) {
        Write-Error "Kan de download-URL voor AzCopy niet ophalen."
        exit 1
    }
    return $DownloadUrl
}

# Download de nieuwste versie van AzCopy
$AzCopyUrl = Get-LatestAzCopy
$AzCopyZipPath = "$env:TEMP\AzCopy.zip"
Invoke-WebRequest -Uri $AzCopyUrl -OutFile $AzCopyZipPath -UseBasicParsing

# Uitpakken van het archief
Expand-Archive -Path $AzCopyZipPath -DestinationPath "$env:TEMP\AzCopy" -Force

# Vind AzCopy
$AzCopy = (Get-ChildItem -Path "$env:TEMP\AzCopy" -Recurse -File -Filter 'azcopy.exe').FullName

# Controleer of NuGet-provider is geïnstalleerd, zo niet, installeer het
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

# Controleer of het Get-WindowsAutopilotInfo-script is geïnstalleerd, zo niet, installeer het
if (-not (Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    Install-Script Get-WindowsAutopilotInfo -Force
}

# Gebruik de nieuwe prefix "AID_" als onderdeel van de bestandsnaam
$Filename = "AID_$($env:COMPUTERNAME).csv"

# Locatie van het Autopilot-script
$scriptlocation = (Get-InstalledScript -Name Get-WindowsAutopilotInfo).InstalledLocation

# Genereer CSV-bestand voor upload
& "$scriptlocation\Get-WindowsAutoPilotInfo.ps1" -OutputFile "$env:TEMP\$Filename"

# Upload het gegenereerde CSV-bestand naar Azure Blob Storage
& $AzCopy cp "$env:TEMP\$Filename" $env:SasURL --overwrite true

# Optioneel: Opruimen van tijdelijke bestanden
Remove-Item $AzCopyZipPath -Force
Remove-Item "$env:TEMP\AzCopy" -Recurse -Force
Remove-Item "$env:TEMP\$Filename" -Force

# Eind script
