default:
    just --list

user := 'masoodahmed'

deploy machine='': preflight
    @if [ "$(uname)" = "Darwin" ] && [ -z "{{ machine }}" ]; then \
      sudo darwin-rebuild switch --flake .; \
    elif [ -z "{{ machine }}" ]; then \
      nixos-rebuild switch --sudo --flake .; \
    else \
      nixos-rebuild switch --no-reexec --flake ".#{{ machine }}" --sudo --target-host "{{ user }}@{{ machine }}" --build-host "{{ user }}@{{ machine }}"; \
    fi

# Pre-flight checks — run before deploy to catch formatting and lint errors early
preflight:
    @echo "Running pre-flight checks..."
    @nix fmt -- --check .
    @just lint

up:
    nix flake update

lint:
    statix check .

fmt:
    nix fmt

gc age='7d':
    sudo nix-collect-garbage --delete-older-than {{ age }} && nix-collect-garbage --delete-older-than {{ age }}

repair:
    sudo nix-store --verify --check-contents --repair

sops-rotate:
    @if git diff --name-only -- '*.sops.yaml' | grep -q .; then \
      echo "ERROR: uncommitted changes in sops files — commit or stash first"; \
      git diff --name-only -- '*.sops.yaml'; \
      exit 1; \
    fi
    find . -name "*.sops.yaml" -type f ! -name ".sops.yaml" -print0 | xargs -0 -n1 sops --rotate --in-place

sops-update:
    find . -name "*.sops.yaml" -type f ! -name ".sops.yaml" -exec sops updatekeys {} \;

build-iso:
    nix build .#nixosConfigurations.nixiso.config.system.build.isoImage
