# Load .env file and get GitHubUser and GitHubToken values
$envPath = Join-Path -Path $PSScriptRoot -ChildPath ".env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath
    $GitHubUser = $envContent | Where-Object { $_ -match '^GitHubUser\s*=' }
    $GitHubToken = $envContent | Where-Object { $_ -match '^GitHubToken\s*=' }

    if ($GitHubUser) {
        $GitHubUser = ($GitHubUser -replace '^GitHubUser\s*=\s*', '').Trim()
    } else {
        throw "GitHubUser not found in .env file."
    }

    if ($GitHubToken) {
        $GitHubToken = ($GitHubToken -replace '^GitHubToken\s*=\s*', '').Trim()
    } else {
        throw "GitHubToken not found in .env file."
    }
    Write-Host "--> envContent: $($envContent)"
    Write-Host "--> GitHubUser: $($GitHubUser)"
    Write-Host "--> GitHubToken: $($GitHubUser)"
    
} else {
    throw ".env file not found in script folder."
}


# Set base URL depending on user or org
if ($IsOrg) {
    $url = "https://api.github.com/orgs/$GitHubUser/repos?per_page=100"
} else {
    $url = "https://api.github.com/users/$GitHubUser/repos?per_page=100"
}

# Fix: Properly format the Authorization header
$authString = "${GitHubUser}:${GitHubToken}"
$bytes = [Text.Encoding]::ASCII.GetBytes($authString)
$base64Auth = [Convert]::ToBase64String($bytes)

$headers = @{
    Authorization = "Basic $base64Auth"
    'User-Agent'  = "$GitHubUser"
}

# Fetch repositories
$repos = Invoke-RestMethod -Uri $url -Headers $headers

foreach ($repo in $repos) {
    $repoName = $repo.name
    $cloneUrl = $repo.clone_url

    $safeFolderName = $repoName -replace '[\\/:*?"<>|]', "_"  # Replace invalid folder chars if any
    $folderPath = Join-Path -Path $PWD -ChildPath $safeFolderName
    
    # Create folder with repository name
    if (-not (Test-Path -Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }

    $branchesUrl = "https://api.github.com/repos/$GitHubUser/$repoName/branches"
    $branches = Invoke-RestMethod -Uri $branchesUrl -Headers $headers

    foreach ($branch in $branches) {
        Write-Host "--> Branch: $($branch.name)"
        $branchFolderPath = "$folderPath\"+"$($branch.name)"

        if (-not (Test-Path "$branchFolderPath\.git")) {
            Write-Host "FolderPath: $folderPath"

            Write-Host "BranchPath: $branchFolderPath"
            New-Item -ItemType Directory -Path $branchFolderPath | Out-Null
            git clone --quiet -b $($branch.name) --single-branch $cloneUrl $branchFolderPath
            Write-Host "V - Cloned branch '$($branch.name)' of '$repoName'"
        } else {
            Write-Host "X - Already cloned: $folderPath"
        }
    }
}