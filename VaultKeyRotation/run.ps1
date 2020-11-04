param($eventGridEvent, $TriggerMetadata)

# By a key rotation we mean creating a new version of the key
function RoatateKey($vaultName, $keyName) {
    # Retrieve Key
    $key = Get-AzKeyVaultKey -VaultName $vaultName -Name $keyName
    $version = $key.Version.ToString()
    Write-Host "Key Retrieved. Version: $version"

    $validityPeriodDays = $key.Tags["ValidityPeriodDays"]
    
    Write-Host "Key Info Retrieved"
    Write-Host "Validity Period: $validityPeriodDays"

    # Add a new key to Key Vault
    $newKeyVersionTags = @{}
    $newKeyVersionTags.ValidityPeriodDays = $validityPeriodDays

    $expiryDate = (Get-Date).AddDays([int] $validityPeriodDays).ToUniversalTime()
    $newKey = Add-AzKeyVaultKey -VaultName $vaultName -Name $keyName -Tag $newKeyVersionTags -Expires $expiryDate -Destination Software
    $newVersion = $newKey.Version.ToString()
    Write-Host "New key added to Key Vault. Key Version: $newVersion"
    # $newKey | ConvertTo-Json | Write-Host

    # TODO clean expired keys - not possible
}

# Make sure to pass hashtables to Out-String so they're logged correctly
$eventGridEvent | ConvertTo-Json | Write-Host

$keyName = $eventGridEvent.subject
$vaultName = $eventGridEvent.data.VaultName
Write-Host "Key Vault Name: $vaultName"
Write-Host "Key Name: $keyName"

# Rotate key
Write-Host "Rotation started."
RoatateKey $vaultName $keyName
Write-Host "Key Rotated Successfully"
