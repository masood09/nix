default:
    just --list

deploy machine='' ip='':
    @if [ "$(uname)" = "Darwin" ] && [ -z "{{ machine }}" ] && [ -z "{{ ip }}" ]; then \
      sudo darwin-rebuild switch --flake .; \
    elif [ -z "{{ machine }}" ] && [ -z "{{ ip }}" ]; then \
      nixos-rebuild switch --use-remote-sudo --flake .; \
    elif [ -z "{{ ip }}" ]; then \
      nixos-rebuild switch --use-remote-sudo --flake ".#{{ machine }}"; \
    else \
      nixos-rebuild switch --fast --flake ".#{{ machine }}" --use-remote-sudo --target-host "masood@{{ ip }}" --build-host "masood@{{ ip }}"; \
    fi

up:
    nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update

lint:
    statix check .

fmt:
    nix --extra-experimental-features nix-command --extra-experimental-features flakes fmt .

gc:
    sudo nix-collect-garbage -d && nix-collect-garbage -d

repair:
    sudo nix-store --verify --check-contents --repair

sops-rotate:
    find . -name "*.sops.yaml" -type f ! -name ".sops.yaml" -print0 | xargs -0 -n1 sops --rotate --in-place

sops-update:
    while IFS= read -r -d '' f; do echo "Updating keys: $f"; sops updatekeys "$f"; done < <(find . -name "*.sops.yaml" -type f ! -name ".sops.yaml" -print0)

build-iso:
    nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#nixosConfigurations.nixiso.config.system.build.isoImage
