# run_once_05-env-variables.ps1
# Managed by chezmoi — runs once on first apply.
# Sets user-level environment variables and PATH entries.

# Set CLAUDE_CODE_GIT_BASH_PATH
[Environment]::SetEnvironmentVariable(
    'CLAUDE_CODE_GIT_BASH_PATH',
    'E:\Applications\Scoop\apps\git\current\bin\bash.exe',
    'User'
)

# Add to PATH if not already present
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$additions = @(
    "$env:USERPROFILE\.local\bin"
    'E:\rtk\bin'
)

foreach ($dir in $additions) {
    if ($currentPath -notlike "*$dir*") {
        $currentPath = "$currentPath;$dir"
    }
}

[Environment]::SetEnvironmentVariable('Path', $currentPath, 'User')
