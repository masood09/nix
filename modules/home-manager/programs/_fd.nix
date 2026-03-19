# Fd — fast, user-friendly alternative to find.
{homelabCfg, ...}: {
  programs = {
    fd = {
      inherit (homelabCfg.programs.fd) enable;
    };
  };
}
