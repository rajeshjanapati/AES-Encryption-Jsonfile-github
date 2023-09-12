$token = $env:TOKEN
$headers = @{Authorization = "Bearer $token"}

# Make the API call to get the data
$appdetailget = Invoke-RestMethod -Uri "https://apigee.googleapis.com/v1/organizations/esi-apigee-x-394004/developers/testexample1@gmail.com/apps/app" -Method 'GET' -Headers $headers

# Specify the fields you want to encrypt
$fieldsToEncrypt = @("consumerKey", "consumerSecret")

# Encryption key
$keyHex = $env:key  # Replace with your encryption key

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Loop through the specified fields and encrypt their values
foreach ($field in $fieldsToEncrypt) {
    # Check if the credentials array exists and has at least one item
    if ($appdetailget.credentials.Count -gt 0) {
        $plaintext = $appdetailget.credentials[0].$field

        # Convert plaintext to bytes (UTF-8 encoding)
        $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

        # Generate a random initialization vector (IV)
        $AES.GenerateIV()
        $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

        # Encrypt the data
        $encryptor = $AES.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)
        $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

        # Store the encrypted value back in the JSON data
        $appdetailget.credentials[0].$field = @{
            "EncryptedValue" = $encryptedBase64
            "IV" = $IVBase64
        }
    }
}

# Convert the modified JSON data back to JSON format with a higher depth value
$encryptedJsonData = $appdetailget | ConvertTo-Json -Depth 10

# Display the modified JSON data
Write-Host $encryptedJsonData

# Define the local file path and file name
$filePath = "jsonfile/encrypted_data.json"

# Write the JSON data to the file
$encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8
