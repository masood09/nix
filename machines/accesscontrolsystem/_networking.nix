# Machine networking — DHCP (cloud VM).
{lib, ...}: {
  networking.useDHCP = lib.mkDefault true;
}
