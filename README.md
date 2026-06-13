# backup-remote-repos

PowerShell scripts to clone all branches of every repository from a GitHub or Bitbucket account.

---

## About

Written in PowerShell, this project provides two scripts for bulk-cloning remote repositories. Each script reads credentials from a `.env` file, fetches all repositories for the authenticated user, and clones every branch of each repository into a local folder structure organized by repository name.

- `github/Get-GitHubBranches.ps1` - clones all branches of every repository for a GitHub user via the GitHub REST API.
- `bitbucket/Get-BitBucketBranches.ps1` - clones all branches of every repository across all Bitbucket workspaces via the Bitbucket REST API.

## Usage

1. Create a `.env` file inside the relevant script folder (`github/` or `bitbucket/`).
2. Run the desired script from PowerShell.

Each repository is cloned into a subfolder named after the repository. Each branch gets its own subfolder inside that. Already-cloned branches are skipped.

## Getting Started

### Prerequisites

- PowerShell 5.1 or later
- Git installed and available on the `PATH`
- A GitHub personal access token or a Bitbucket app password

### GitHub

Create `github/.env`:
```
GitHubUser=your_github_username
GitHubToken=your_personal_access_token
```

Run:
```powershell
.\github\Get-GitHubBranches.ps1
```

### Bitbucket

Create `bitbucket/.env`:
```
BitbucketUser=your_bitbucket_username
BitbucketAppPassword=your_app_password
```

Run:
```powershell
.\bitbucket\Get-BitBucketBranches.ps1
```

## Configuration

| Variable | File | Description |
|----------|------|-------------|
| `GitHubUser` | `github/.env` | GitHub username |
| `GitHubToken` | `github/.env` | GitHub personal access token |
| `BitbucketUser` | `bitbucket/.env` | Bitbucket username |
| `BitbucketAppPassword` | `bitbucket/.env` | Bitbucket app password |

The `.env` files are excluded from version control via `.gitignore`.

---

MIT License - see [LICENSE](LICENSE)
