# Custom Grafana dashboards, generated from Nix attrsets (via builtins.toJSON)
# rather than hand-written JSON: one file per dashboard (fleet.nix, storage.nix),
# sharing panel-building helpers from helpers.nix. Community dashboards
# (node-exporter-full.json, postgresql.json, alongside this directory) are
# plain JSON, provisioned separately in ../default.nix.
{
  lib,
  pkgs,
}: let
  helpers = import ./helpers.nix {inherit lib;};
  fleetOverview = import ./fleet.nix {inherit lib helpers;};
  storageHardware = import ./storage.nix {inherit lib helpers;};
in {
  fleet = pkgs.writeText "homelab-fleet.json" (builtins.toJSON fleetOverview);
  storage = pkgs.writeText "homelab-storage-hw.json" (builtins.toJSON storageHardware);
}
