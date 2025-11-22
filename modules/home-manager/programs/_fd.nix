{homelabCfg, ...}: {
  programs = {
    fd = {
      inherit (homelabCfg.programs.fd) enable;
    };
  };
}
