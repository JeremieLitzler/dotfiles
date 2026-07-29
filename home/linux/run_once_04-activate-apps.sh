if ! grep -q 'carapace' ~/.bashrc; then
    echo "export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional" >> ~/.bashrc
    echo "source <(carapace _carapace)" >> bashrc
fi

if ! grep -q 'atuin' ~/.bashrc; then
    eval "$(atuin init bash)"
fi
