# Desktop modules — hardware support and Niri compositor.
# Each sub-module gates itself on role == "desktop".
{...}: {
  imports = [
    ./_desktop-hardware.nix
    ./_niri.nix
  ];
}
