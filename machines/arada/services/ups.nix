{
  power.ups = {
    enable = true;
    mode = "netserver";

    ups."serverups" = {
      driver = "usbhid-ups";
      port = "auto";
      vendorid = "0764";
      productid = "0601";
      serial = "BHWPS2000214";
      desc = "CyberPower PR1500LCDRT2U";
    };
  };
}
