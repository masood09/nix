{
  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        statusline.lualine = {
          enable = true;
          theme = "catppuccin";
        };

        telescope.enable = true;

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
          transparent = false;
        };
      };
    };
  };
}
