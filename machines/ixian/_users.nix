# Local gaming account. masoodahmed remains the shared SSH/admin account.
{config, ...}: {
  config = {
    users = {
      users = {
        voyageonwheels = {
          isNormalUser = true;
          uid = 1001;
          description = "voyageonwheels";

          extraGroups = [
            "audio"
            "input"
            "video"
          ];
        };
      };
    };
  };
}
