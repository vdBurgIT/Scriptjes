<#
=================================================================================
 Title: Upload Autopilot Hardware ID naar Azure Blob Storage
 Author: vdBurgIT
 Version: 1.2
 Description:
     Dit script verzamelt de Windows Autopilot hardware-ID van het apparaat
     en uploadt deze naar een Azure Blob Storage-container via AzCopy.

 Instructies:
     1. Zorg ervoor dat het apparaat internettoegang heeft.
     2. Stel een SAS URL in via de "Environment Vars" in Tactical RMM
        met de sleutel "SasURL".
     3. Het script downloadt en gebruikt AzCopy om het CSV-bestand te uploaden.
     4. Controleer of de SAS URL geldig is en toegang biedt tot de container.

 Let op:
     - Vereist PowerShell 5.1 of hoger.
     - Het script controleert automatisch op ontbrekende dependencies.
     - Tijdelijke bestanden worden automatisch opgeruimd na uitvoering.

 Environment Variables:
     - SasURL: De volledige SAS URL voor de Azure Blob Storage-container.

=================================================================================
#>

# Begin script

# Download AzCopy
Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile "$env:TEMP\AzCopy.zip" -UseBasicParsing

# Uitpakken van het archief
Expand-Archive -Path "$env:TEMP\AzCopy.zip" -DestinationPath "$env:TEMP\AzCopy" -Force

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

# Gebruik computernaam als onderdeel van de bestandsnaam
$Filename = "AutopilotHWID-$($env:COMPUTERNAME).csv"

# Locatie van het Autopilot-script
$scriptlocation = (Get-InstalledScript -Name Get-WindowsAutopilotInfo).InstalledLocation

# Genereer CSV-bestand voor upload
& "$scriptlocation\Get-WindowsAutoPilotInfo.ps1" -OutputFile "$env:TEMP\$Filename"

# Controleer of de SAS URL is ingesteld
if (-not $env:SasURL) {
    Write-Error "De SAS URL is niet ingesteld. Controleer de Environment Vars in Tactical RMM."
    exit 1
}

# Upload het gegenereerde CSV-bestand naar Azure Blob Storage
& $AzCopy cp "$env:TEMP\$Filename" $env:SasURL --overwrite true

# Optioneel: Opruimen van tijdelijke bestanden
Remove-Item "$env:TEMP\AzCopy.zip" -Force
Remove-Item "$env:TEMP\AzCopy" -Recurse -Force
Remove-Item "$env:TEMP\$Filename" -Force

# Eind script
