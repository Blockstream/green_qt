param(
    [string]$Registry = ($env:GAR -split "/")[0]
)

$ErrorActionPreference = "Stop"

foreach ($name in @("GAR", "GITLAB_OIDC_TOKEN", "WIF_PROJECT_NUMBER", "WIF_POOL_ID", "WIF_PROVIDER_ID", "WIF_SERVICE_ACCOUNT_EMAIL")) {
    if (-not [Environment]::GetEnvironmentVariable($name)) {
        throw "Required CI variable $name is not set"
    }
}

$audience = "//iam.googleapis.com/projects/$($env:WIF_PROJECT_NUMBER)/locations/global/workloadIdentityPools/$($env:WIF_POOL_ID)/providers/$($env:WIF_PROVIDER_ID)"
$stsResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "https://sts.googleapis.com/v1/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        audience           = $audience
        grant_type         = "urn:ietf:params:oauth:grant-type:token-exchange"
        requested_token_type = "urn:ietf:params:oauth:token-type:access_token"
        scope              = "https://www.googleapis.com/auth/cloud-platform"
        subject_token_type = "urn:ietf:params:oauth:token-type:jwt"
        subject_token      = $env:GITLAB_OIDC_TOKEN
    }

$serviceAccount = [Uri]::EscapeDataString($env:WIF_SERVICE_ACCOUNT_EMAIL)
$accessTokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${serviceAccount}:generateAccessToken" `
    -ContentType "application/json" `
    -Headers @{
        Authorization = "Bearer $($stsResponse.access_token)"
    } `
    -Body (@{
        scope    = @("https://www.googleapis.com/auth/cloud-platform")
        lifetime = "3600s"
    } | ConvertTo-Json)

$accessTokenResponse.accessToken | docker login -u oauth2accesstoken --password-stdin $Registry
if ($LASTEXITCODE -ne 0) {
    throw "Docker login to $Registry failed with exit code $LASTEXITCODE"
}
