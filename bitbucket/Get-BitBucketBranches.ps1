
# Load .env file and get BitbucketUser and BitbucketAppPassword values
$envPath = Join-Path -Path $PSScriptRoot -ChildPath ".env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath

    # BitbucketWorkspace is no longer required for looping all workspaces

    # Get BitbucketUser and BitbucketAppPassword
    $BitbucketUser = $envContent | Where-Object { $_ -match '^BitbucketUser\s*=' }
    $BitbucketAppPassword = $envContent | Where-Object { $_ -match '^BitbucketAppPassword\s*=' }

    if ($BitbucketUser) {
        $BitbucketUser = ($BitbucketUser -replace '^BitbucketUser\s*=\s*', '').Trim()
    } else {
        throw "BitbucketUser not found in .env file."
    }

    if ($BitbucketAppPassword) {
        $BitbucketAppPassword = ($BitbucketAppPassword -replace '^BitbucketAppPassword\s*=\s*', '').Trim()
    } else {
        throw "BitbucketAppPassword not found in .env file."
    }
} else {
    throw ".env file not found in script folder."
}

 # Get all workspaces for the user
 $workspacesUrl = "https://api.bitbucket.org/2.0/workspaces?pagelen=100"

# Properly format the Authorization header
$authString = "${BitbucketUser}:${BitbucketAppPassword}"
$bytes = [Text.Encoding]::ASCII.GetBytes($authString)
$base64Auth = [Convert]::ToBase64String($bytes)

$headers = @{
    Authorization = "Basic $base64Auth"
    'User-Agent'  = "$BitbucketUser"
}

# Fetch repositories

# Fetch all workspaces for the user
$workspacesResponse = Invoke-RestMethod -Uri $workspacesUrl -Headers $headers
$workspaces = $workspacesResponse.values

foreach ($workspace in $workspaces) {
    $BitbucketWorkspace = $workspace.slug
    Write-Host "Processing workspace: $BitbucketWorkspace"
    # Create a folder for the workspace
    $workspaceFolderPath = Join-Path -Path $PWD -ChildPath $BitbucketWorkspace
    if (-not (Test-Path -Path $workspaceFolderPath)) {
        New-Item -ItemType Directory -Path $workspaceFolderPath | Out-Null
    }

    $reposUrl = "https://api.bitbucket.org/2.0/repositories/$($BitbucketWorkspace)?pagelen=100"
    $reposResponse = Invoke-RestMethod -Uri $reposUrl -Headers $headers
    $repos = $reposResponse.values

    foreach ($repo in $repos) {
        $repoName = $repo.name
        $repoSlug = $repo.slug
        $cloneUrl = $repo.links.clone[0].href

        $safeFolderName = $repoName -replace '[\\/:*?"<>|]', "_"  # Replace invalid folder chars if any
        $repoFolderPath = Join-Path -Path $workspaceFolderPath -ChildPath $safeFolderName

        # Create folder with repository name under workspace folder
        if (-not (Test-Path -Path $repoFolderPath)) {
            New-Item -ItemType Directory -Path $repoFolderPath | Out-Null
        }

        $branchesUrl = "https://api.bitbucket.org/2.0/repositories/$BitbucketWorkspace/$repoSlug/refs/branches"
        $branchesResponse = Invoke-RestMethod -Uri $branchesUrl -Headers $headers
        $branches = $branchesResponse.values

        foreach ($branch in $branches) {
            Write-Host "--> Branch: $($branch.name)"
            $branchFolderPath = "$repoFolderPath\"+"$($branch.name)"

            if (-not (Test-Path "$branchFolderPath\.git")) {
                Write-Host "RepoFolderPath: $repoFolderPath"
                Write-Host "BranchPath: $branchFolderPath"
                New-Item -ItemType Directory -Path $branchFolderPath | Out-Null
                git clone --quiet -b $($branch.name) --single-branch $cloneUrl $branchFolderPath
                Write-Host "V - Cloned branch '$($branch.name)' of '$repoName'"
            } else {
                Write-Host "X - Already cloned: $repoFolderPath"
            }
        }
    }
}