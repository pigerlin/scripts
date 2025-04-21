# Base64 encoded string containing IP address data
$WinRMIPList = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\SafeClientList" -Name "WSManSafeClientList").WSManSafeClientList
$base64String = [System.Convert]::ToBase64String($WinRMIPList)
# Decode the Base64 string into a byte array
try {
    $value = [System.Convert]::FromBase64String($base64String)
} catch {
    Write-Error "Failed to decode Base64 string: $_"
    exit 1
}
# Define the size of each IP address entry (16 bytes for IPv6 or padded IPv4)
$chunkSize = 16
# Calculate the number of entries/chunks
$numChunks = [Math]::Floor($value.Length / $chunkSize)
# Loop through the byte array in chunks of $chunkSize
for ($i = 0; $i -lt $numChunks; $i++) {
    $entryNumber = $i + 1
    try {
        # Calculate the start and end index for the current chunk in the byte array
        $startIndex = $chunkSize * $i
        $endIndex = $startIndex + $chunkSize - 1
        # Extract the 16-byte chunk for the current entry
        $addrBytes = $value[$startIndex..$endIndex]
        # Assume the first 4 bytes is a IPv4 address
        $isIPv4 = $true
        # Check bytes at index 8 through 15 (the last 8 bytes of the 16-byte chunk)
        for ($k = 8; $k -lt $chunkSize; $k++) {
            # If any byte in the last 8 is not zero, it's not the IPv4 pattern we expect
            if ($addrBytes[$k] -ne 0) {
                $isIPv4 = $false
                break
            }
        }
        if ($isIPv4) {
            # If it ends in 8 nulls, take the first 4 bytes
            $ipBytesToParse = $addrBytes[0..3]
            # The [System.Net.IPAddress] constructor correctly interprets a 4-byte array as IPv4
            $ipAddress = [System.Net.IPAddress]::new($ipBytesToParse)
        } else {
            # Otherwise, use the full 16-byte chunk
            $ipBytesToParse = $addrBytes
            # The [System.Net.IPAddress] constructor interprets a 16-byte array as IPv6
            $ipAddress = [System.Net.IPAddress]::new($ipBytesToParse)
        }
        Write-Host "Entry$($entryNumber): $($ipAddress.IPAddressToString)"
    } catch {
        Write-Error "Error processing Entry$($entryNumber): $_"
    }
}
