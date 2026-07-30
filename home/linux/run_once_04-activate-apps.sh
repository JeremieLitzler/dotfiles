if ! grep -q 'carapace' ~/.bashrc; then
    echo "export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional" >> ~/.bashrc
    echo "source <(carapace _carapace)" >> ~/.bashrc
fi

if ! grep -q 'atuin' ~/.bashrc; then
    echo 'eval "$(atuin init bash)"'  >> ~/.bashrc
fi
