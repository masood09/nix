# Custom Grafana dashboards, generated from Nix attrsets (via builtins.toJSON)
# rather than hand-written JSON: one file per dashboard (fleet.nix, storage.nix),
# sharing panel-building helpers from helpers.nix. The community PostgreSQL
# dashboard (postgresql.json, alongside this directory) is plain JSON,
# provisioned separately in ../default.nix.
{
  lib,
  pkgs,
}: let
  helpers = import ./helpers.nix {inherit lib;};
  fleetOverview = import ./fleet.nix {inherit lib helpers;};
  storageHardware = import ./storage.nix {inherit lib helpers;};
  hostInfo = import ./host-info.nix {inherit lib helpers;};
in {
  fleet = pkgs.writeText "homelab-fleet.json" (builtins.toJSON fleetOverview);
  storage = pkgs.writeText "homelab-storage-hw.json" (builtins.toJSON storageHardware);
  hostInfo = pkgs.writeText "homelab-host-info.json" (builtins.toJSON hostInfo);
}
