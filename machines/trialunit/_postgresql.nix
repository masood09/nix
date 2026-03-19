# PostgreSQL auth — imports shared DB/user definitions for this machine.
{...}: {
  imports = [
    ../../modules/services/postgresql/_auth.nix
  ];
}
