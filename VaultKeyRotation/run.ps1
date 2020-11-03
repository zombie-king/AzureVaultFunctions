param($eventGridEvent, $TriggerMetadata)

function GetAlternateCredentialId($keyId) {
    $validCredentialIdsRegEx = 'key[1-2]'
    
    If ($keyId -NotMatch $validCredentialIdsRegEx) {
        throw "Invalid credential id: $keyId. Credential id must follow this pattern: $validCredentialIdsRegEx"
    }
    If ($keyId -eq 'key1') {
        return "key2"
    }
    Else {
        return "key1"
    }
}

$DefaultValidityPeriodDays = "180"
$DefaultCredentialId = "key1"

function RoatateKey($vaultName, $keyName) {
    # Retrieve Key
    $key = Get-AzKeyVaultKey -VaultName $vaultName -Name $keyName
    $version = $key.Version.ToString()
    Write-Host "Key Retrieved. Version: $version"
    
    # Retrieve Key Info
    if ($null -eq $key.Tags) {
        $key.Tags = @{}
    }    
    $validityPeriodDays = $key.Tags["ValidityPeriodDays"]
    if ([string]::IsNullOrWhitespace($validityPeriodDays)) {
        $validityPeriodDays = $DefaultValidityPeriodDays
    }
    $credentialId = $key.Tags["CredentialId"]
    if ([string]::IsNullOrWhitespace($credentialId)) {
        $credentialId = $DefaultCredentialId
    }
    #$providerAddress = $key.Tags["ProviderAddress"]
    
    Write-Host "Key Info Retrieved"
    Write-Host "Validity Period: $validityPeriodDays"
    Write-Host "Credential Id: $credentialId"
    #Write-Host "Provider Address: $providerAddress"

    # Get Credential Id to rotate - alternate credential
    $alternateCredentialId = GetAlternateCredentialId $credentialId
    Write-Host "Alternate credential id: $alternateCredentialId"

    # Add a new key to Key Vault
    $newKeyVersionTags = @{}
    $newKeyVersionTags.ValidityPeriodDays = $validityPeriodDays
    $newKeyVersionTags.CredentialId = $alternateCredentialId
    # $newKeyVersionTags.ProviderAddress = $providerAddress

    $expiryDate = (Get-Date).AddDays([int] $validityPeriodDays).ToUniversalTime()
    $newKey = Add-AzKeyVaultKey -VaultName $vaultName -Name $keyName -Tag $newKeyVersionTags -Expires $expiryDate -Destination Software
    $newVersion = $newKey.Version.ToString()
    Write-Host "New key added to Key Vault. Key Version: $newVersion"
    # $newKey | ConvertTo-Json | Write-Host

    #TODO clean expired keys
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
