# Pinned tabs — declaratively managed per profile, keyed by human-readable name.
# Each entry carries a stable UUID in `id` for Zen's internal tracking.
# Positions are 1-indexed within each space.
# "homelab": Personal → proton mail, proton calendar, keep, ittools, mailarchiver
#            Homelab  → router, omada, uptime, grafana, uptime.test, grafana.test, oracle cloud, backblaze
#            Admin    → auth, auth.test
#            Google   → gmail, youtube
# "work":    Personal → proton mail, proton calendar, keep, ittools, passwords
#            Google   → gmail, youtube
# "family":  Personal → keep, ittools
{
  homelabCfg,
  lib,
  ...
}: let
  profile = homelabCfg.programs.zen.containerProfile;
  personalSpace = "572910e1-4468-4832-a869-0b3a93e2f165";
  homelabSpace = "ec287d7f-d910-4860-b400-513f269dee77";
  adminSpace = "2441acc9-79b1-4afb-b582-ee88ce554ec0";
  googleSpace = "a8f3c2e1-5d90-4b2a-9e7f-1c4d8a6b3f9e";
in {
  programs = {
    zen-browser = {
      profiles = {
        default = {
          pinsForce = true;
          pins =
            # Personal space — family profile
            lib.optionalAttrs (profile == "family") {
              "Karakeep" = {
                id = "b2c3d4e5-f6a7-4901-bcde-f12345678901";
                url = "https://keep.mantannest.com";
                container = 2; # Personal container
                workspace = personalSpace;
                position = 1;
              };
              "IT Tools" = {
                id = "c3d4e5f6-a7b8-4012-cdef-123456789012";
                url = "https://ittools.mantannest.com";
                container = 2;
                workspace = personalSpace;
                position = 2;
              };
            }
            # Personal space — homelab + work (shared base)
            // lib.optionalAttrs
            (builtins.elem profile [
              "homelab"
              "work"
            ])
            {
              "Proton Mail" = {
                id = "a1b2c3d4-e5f6-4890-abcd-ef1234567890";
                url = "https://mail.proton.me/";
                container = 2; # Personal container
                workspace = personalSpace;
                position = 1;
              };
              "Proton Calendar" = {
                id = "3825a39a-656b-4625-a226-d20964b39cf3";
                url = "https://calendar.proton.me";
                container = 2;
                workspace = personalSpace;
                position = 2;
              };
              "Karakeep" = {
                id = "b2c3d4e5-f6a7-4901-bcde-f12345678901";
                url = "https://keep.mantannest.com";
                container = 2;
                workspace = personalSpace;
                position = 3;
              };
              "IT Tools" = {
                id = "c3d4e5f6-a7b8-4012-cdef-123456789012";
                url = "https://ittools.mantannest.com";
                container = 2;
                workspace = personalSpace;
                position = 4;
              };
            }
            # Personal space — homelab only
            // lib.optionalAttrs (profile == "homelab") {
              "Mail Archiver" = {
                id = "f6a7b8c9-d0e1-4345-f012-456789012345";
                url = "https://mailarchiver.mantannest.com";
                container = 2;
                workspace = personalSpace;
                position = 5;
              };
            }
            # Personal space — work only
            // lib.optionalAttrs (profile == "work") {
              "Vaultwarden" = {
                id = "f2a3b4c5-d6e7-4901-5678-012345678901";
                url = "https://passwords.mantannest.com";
                container = 2;
                workspace = personalSpace;
                position = 5;
              };
            }
            # Google space — homelab + work
            // lib.optionalAttrs
            (builtins.elem profile [
              "homelab"
              "work"
            ])
            {
              "GMail" = {
                id = "d4e5f6a7-b8c9-4123-def0-234567890123";
                url = "https://mail.google.com";
                container = 5; # Google container
                workspace = googleSpace;
                position = 1;
              };
              "YouTube" = {
                id = "e5f6a7b8-c9d0-4234-ef01-345678901234";
                url = "https://youtube.com";
                container = 5;
                workspace = googleSpace;
                position = 2;
              };
            }
            # Homelab space — homelab only
            // lib.optionalAttrs (profile == "homelab") {
              "UniFi" = {
                id = "a7b8c9d0-e1f2-4456-0123-567890123456";
                url = "https://unifi.ui.com";
                container = 3; # Homelab container
                workspace = homelabSpace;
                position = 1;
              };
              "Omada Controller" = {
                id = "a5ad6de6-e610-44c2-86f5-a8720de88c5f";
                url = "https://omada-host.mgmt.homelab.mantannest.com:8043";
                container = 3;
                workspace = homelabSpace;
                position = 2;
              };
              "Uptime Kuma - Prod" = {
                id = "b8c9d0e1-f2a3-4567-1234-678901234567";
                url = "https://uptime.mantannest.com";
                container = 3;
                workspace = homelabSpace;
                position = 3;
              };
              "Grafana - Prod" = {
                id = "4f7c2d91-8e3a-4b6f-a1d4-92c5e7f8b103";
                url = "https://grafana.mantannest.com";
                container = 3;
                workspace = homelabSpace;
                position = 4;
              };
              "Uptime Kuma - Test" = {
                id = "c9d0e1f2-a3b4-4678-2345-789012345678";
                url = "https://uptime.test.mantannest.com";
                container = 3;
                workspace = homelabSpace;
                position = 5;
              };
              "Grafana - Test" = {
                id = "9a1e6c44-2b7f-4d8a-b5c9-1f3e7a2d6b80";
                url = "https://grafana.test.mantannest.com";
                container = 3;
                workspace = homelabSpace;
                position = 6;
              };
              "Oracle Cloud" = {
                id = "e2c1d9e9-fe41-4bae-aca6-5a42b6526138";
                url = "https://cloud.oracle.com";
                container = 3;
                workspace = homelabSpace;
                position = 7;
              };
              "Backblaze" = {
                id = "4bff4f82-d95a-4985-984c-0893ea38c9f8";
                url = "https://secure.backblaze.com/b2_buckets.htm";
                container = 3;
                workspace = homelabSpace;
                position = 8;
              };
            }
            # Admin space — homelab only
            // lib.optionalAttrs (profile == "homelab") {
              "Authentik - Prod" = {
                id = "d0e1f2a3-b4c5-4789-3456-890123456789";
                url = "https://auth.mantannest.com";
                container = 4; # Admin container
                workspace = adminSpace;
                position = 1;
              };
              "Authentik - Test" = {
                id = "e1f2a3b4-c5d6-4890-4567-901234567890";
                url = "https://auth.test.mantannest.com";
                container = 4;
                workspace = adminSpace;
                position = 2;
              };
            };
        };
      };
    };
  };
}
