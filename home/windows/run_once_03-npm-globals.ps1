# run_once_03-npm-globals.ps1
# Managed by chezmoi — runs once on first apply.
# Installs global npm packages.

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
