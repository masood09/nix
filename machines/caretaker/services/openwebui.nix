{
  services.open-webui = {
    enable = true;

    environment = {
      WEBUI_URL = "https://chatgpt.mantannest.com";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_BASE_URL = "http://murderbot.home.homelab.mantannest.com:11434";
    };
  };
}
