# Epson ET-8550 — direct-IP printing and network scanning.
# The printer lives on the IoT VLAN; DNS is used instead of embedding its
# address so the queue survives an address change.
{pkgs, ...}: let
  printerHost = "epson-et8550.printer.homelab.mantannest.com";
  epsonscan2 = pkgs.epsonscan2.override {
    # Epson's network-scanning and optional image-processing functionality is
    # shipped in the vendor's non-free plugin bundle.
    withNonFreePlugins = true;
  };
in {
  config = {
    environment = {
      etc = {
        # Static eSCL registration keeps SANE scanning working across VLANs
        # when mDNS discovery is not reflected by the router.
        "sane.d/airscan.conf" = {
          text = ''
            [devices]
            "Epson ET-8550" = http://${printerHost}/eSCL
          '';
        };
      };

      systemPackages = [
        pkgs.darktable
        pkgs.argyllcms
        pkgs.displaycal
        epsonscan2
        pkgs.simple-scan
        pkgs.system-config-printer
      ];
    };

    hardware = {
      printers = {
        ensureDefaultPrinter = "et8550-photo";

        ensurePrinters = [
          {
            name = "et8550-photo";
            description = "Epson ET-8550 photo printer";
            deviceUri = "ipp://${printerHost}/ipp/print";
            model = "epson-inkjet-printer-escpr2/Epson-ET-8550_Series-epson-escpr2-en.ppd";
            ppdOptions = {
              # Epson's T-prefixed PageSize values select borderless media;
              # T2L is 5x7 in (13x18 cm).
              PageSize = "T2L";
            };
          }
          {
            name = "et8550-ipp";
            description = "Epson ET-8550 driverless IPP fallback";
            deviceUri = "ipp://${printerHost}/ipp/print";
            model = "everywhere";
          }
        ];
      };

      sane = {
        enable = true;
        extraBackends = [
          pkgs.sane-airscan
          epsonscan2
        ];
      };
    };

    programs = {
      system-config-printer = {
        enable = true;
      };
    };

    services = {
      avahi = {
        enable = true;
      };

      colord = {
        enable = true;
      };

      printing = {
        enable = true;
        drivers = [
          pkgs.epson-escpr2
        ];
      };
    };
  };
}
