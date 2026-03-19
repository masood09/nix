# Nightscout (cgm-remote-monitor) — Node.js CGM dashboard built with buildNpmPackage.
{
  lib,
  nodejs,
  pkgs,
  ...
}:
pkgs.buildNpmPackage (finalAttrs: {
  pname = "cgm-remote-monitor";
  version = "15.0.3";

  src = pkgs.fetchFromGitHub {
    owner = "nightscout";
    repo = finalAttrs.pname;
    rev = "${finalAttrs.version}";
    hash = "sha256-bI7RvEz9+7k0ZsZWuW9SrLs2qlUHhmDjOwPlLp83Jzs=";
  };

  npmDepsHash = "sha256-p3Dqj78vzRmTPMgaodGXQgvHFE0jGsmBL0p9n403Y2M=";

  inherit nodejs;

  npmFlags = ["--ignore-scripts"];

  npmBuildScript = "bundle";

  # remove only broken .bin symlinks so noBrokenSymlinks passes
  preFixup = ''
    BIN_DIR="$out/lib/node_modules/nightscout/node_modules/.bin"
    if [ -d "$BIN_DIR" ]; then
      find "$BIN_DIR" -xtype l -print -delete
    fi
  '';

  passthru = {
    inherit nodejs;
  };

  meta = {
    description = "nightscout web monitor";
    homepage = "https://github.com/nightscout/cgm-remote-monitor";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [earldouglas];
  };
})
