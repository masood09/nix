#!/usr/bin/env bash

set -e -u -o pipefail

if [ "$(uname)" == "Darwin" ]; then
  # Display warning and wait for confirmation to proceed
  echo "macOS detected"
  echo -e "\n\033[1;31m**Warning:** This script will prepare system for nix-darwin installation.\033[0m"
  read -n 1 -s -r -p "Press any key to continue or Ctrl+C to abort..."

  # inspo: https://forums.developer.apple.com/forums/thread/698954
  echo -e "\n\033[1mInstalling Xcode...\033[0m"
  if [[ -e /Library/Developer/CommandLineTools/usr/bin/git ]]; then
    echo -e "\033[32mXcode already installed.\033[0m"
  else
    # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
    softwareupdate -i "$PROD" --verbose
    echo -e "\033[32mXcode installed successfully.\033[0m"
  fi

  echo -e "\n\033[1mInstalling Nix...\033[0m"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

  sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
  sudo mv /etc/zprofile /etc/zprofile.before-nix-darwin

  echo -e "\n\033[1mInstalling Doom Emacs...\033[0m"
  mkdir -p $HOME/.config/
  git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs

  # Completed
  echo -e "\n\033[1;32mAll steps completed successfully. nix-darwin is now ready to be installed.\033[0m\n"
  echo -e "To install nix-darwin configuration, run the following commands:\n"
  echo -e "\033[1m. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh\033[0m\n"
  echo -e "\033[1msudo nix run nix-darwin -- switch --flake github:masood09/nix#murderbot\033[0m\n"
  echo -e "Remember to add the new host public key to sops-nix!"
fi
