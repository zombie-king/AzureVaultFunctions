# KeyVault-Rotation-StorageAccountKey-PowerShell

## Key Vault Key Rotation Function

Function regenerate individual key add regenerated key to Key Vault as new version of the same secret.

Functions require following information stored in secret as tags:
- $secret.Tags["ValidityPeriodDays"] - number of days, it defines expiration date for new secret

You can create new secret with above tag. For automated rotation expiry date would also be required - it triggers event 30 days before expiry.

Functions:
- VaultKeyRotation - event triggered function, performs storage account key rotation triggered by Key Vault events. In this setup Near Expiry event is used which is published 30 days before expiration
