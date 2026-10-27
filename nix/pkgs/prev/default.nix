# Prev — macOS Preview-style document and image viewer/editor.
{
  autoPatchelfHook,
  fetchurl,
  fontconfig,
  lib,
  libxkbcommon,
  makeWrapper,
  libgcc,
  stdenvNoCC,
  vulkan-loader,
  wayland,
  ...
}: let
  # renovate: datasource=github-releases depName=scrambletoolsllc/prev versioning=semver
  version = "2.4.0";

  assets = {
    "x86_64-linux" = {
      hash = "sha256-IU6Zh1KUh+2wew5OcwMbt9SHE7Z7ge3zbsOdZXn5N4c=";
      suffix = "x86_64";
    };
    "aarch64-linux" = {
      hash = "sha256-HKXUw2sgXnR70NTMRIVlBooisohrn4sKIIqw4nsZ0k4=";
      suffix = "aarch64";
    };
  };

  asset = assets.${stdenvNoCC.hostPlatform.system};
in
  stdenvNoCC.mkDerivation {
    pname = "prev";
    inherit version;

    src = fetchurl {
      inherit (asset) hash;
      url = "https://github.com/scrambletools/prev/releases/download/v${version}/prev-${version}-${asset.suffix}-linux.tar.gz";
    };

    sourceRoot = ".";

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      fontconfig
      libgcc
      libxkbcommon
      vulkan-loader
      wayland
    ];

    installPhase = ''
      runHook preInstall
      cp -R usr $out
      wrapProgram $out/bin/prev \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        libxkbcommon
        vulkan-loader
        wayland
      ]}
      runHook postInstall
    '';

    meta = {
      description = "Preview-style document and image viewer/editor";
      homepage = "https://prev.run";
      license = lib.licenses.agpl3Only;
      mainProgram = "prev";
      platforms = builtins.attrNames assets;
    };
  }
