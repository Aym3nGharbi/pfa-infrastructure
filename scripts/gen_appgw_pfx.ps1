param()

# Read input JSON from stdin
$inputJson = [Console]::In.ReadToEnd()
$input = $inputJson | ConvertFrom-Json
$password = $input.password
$dnsName = 'appgw.pfa.local'

# Create a temporary certificate in local store
$cert = New-SelfSignedCertificate -DnsName $dnsName -CertStoreLocation 'Cert:\LocalMachine\My' -NotAfter (Get-Date).AddYears(1) -KeyLength 2048 -KeyExportPolicy Exportable -Type SSLServerAuthentication
if (-not $cert) { Write-Error 'Failed to create self-signed certificate'; exit 1 }

# Export to a temporary PFX
$tmpFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName() + '.pfx')
$securePwd = ConvertTo-SecureString -String $password -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $tmpFile -Password $securePwd -Force

# Read file and convert to base64
$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($tmpFile))
Remove-Item $tmpFile -Force

# Output JSON result
@{ data = $base64 } | ConvertTo-Json -Compress
