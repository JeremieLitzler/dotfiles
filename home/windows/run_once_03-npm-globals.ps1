# run_once_03-npm-globals.ps1
# Managed by chezmoi — runs once on first apply.
# Installs global npm packages.

# Refresh PATH from registry so scoop shims (npm, node) installed by run_once_01
# are visible — chezmoi inherits the bootstrap session's in-memory PATH, which
# predates scoop writing the shims dir to the user PATH registry key.
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

# Install prettier-plugin-go-template locally in E:\Git\Github
New-Item -ItemType Directory -Force -Path 'E:\Git\Github' | Out-Null
Push-Location 'E:\Git\Github'
if (-not (Test-Path 'node_modules\prettier-plugin-go-template')) {
    npm install prettier-plugin-go-template
}
Pop-Location

# Global installs
npm install -g netlify-cli
npm install -g claude-replay
