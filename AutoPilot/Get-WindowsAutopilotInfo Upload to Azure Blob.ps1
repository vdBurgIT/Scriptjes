<#
=================================================================================
 Title: Get-WindowsAutopilotInfo Upload to Azure Blob
 Author: vdBurgIT
 Version: 2.2
 Description:
     Dit script verzamelt de Windows Autopilot hardware-ID van het apparaat
     en uploadt deze naar een Azure Blob Storage-container via AzCopy.

 Updates:
     - Prefix voor CSV-bestandsnaam gewijzigd naar "AID_".
     - Downloadt de nieuwste versie van AzCopy via de directe Microsoft-link.

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

# Download de nieuwste versie van AzCopy
$AzCopyUrl = "https://aka.ms/downloadazcopy-v10-windows"
$AzCopyZipPath = "$env:TEMP\AzCopy.zip"
Invoke-WebRequest -Uri $AzCopyUrl -OutFile $AzCopyZipPath -UseBasicParsing

# Uitpakken van het archief
$AzCopyExtractPath = "$env:TEMP\AzCopy"
Expand-Archive -Path $AzCopyZipPath -DestinationPath $AzCopyExtractPath -Force

# Vind AzCopy
$AzCopy = (Get-ChildItem -Path $AzCopyExtractPath -Recurse -File -Filter 'azcopy.exe').FullName

# Controleer of NuGet-provider is geïnstalleerd, zo niet, installeer het
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

# Controleer of het Get-WindowsAutopilotInfo-script is geïnstalleerd, zo niet, installeer het
if (-not (Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    Install-Script Get-WindowsAutopilotInfo -Force
}

# Gebruik de prefix "AID_" als onderdeel van de bestandsnaam
$Filename = "AID_$($env:COMPUTERNAME).csv"

# Locatie van het Autopilot-script
$ScriptLocation = (Get-InstalledScript -Name Get-WindowsAutopilotInfo).InstalledLocation

# Genereer CSV-bestand voor upload
& "$ScriptLocation\Get-WindowsAutoPilotInfo.ps1" -OutputFile "$env:TEMP\$Filename"

# Upload het gegenereerde CSV-bestand naar Azure Blob Storage
& $AzCopy cp "$env:TEMP\$Filename" $env:SasURL --overwrite=true

# Optioneel: Opruimen van tijdelijke bestanden
Remove-Item $AzCopyZipPath -Force
Remove-Item $AzCopyExtractPath -Recurse -Force
Remove-Item "$env:TEMP\$Filename" -Force

# Eind script
