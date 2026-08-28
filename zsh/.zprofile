# Initialize Homebrew for both Apple Silicon and Intel Macs.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Publisher-native developer CLIs install their launchers here.
export PATH="${HOME}/.local/bin:${PATH}"
