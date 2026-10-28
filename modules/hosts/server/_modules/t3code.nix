{
  imports = [../../../desktop/t3code.nix];

  # Lets the desktop run heavy agent work here. The tailnet root already serves LiveSync.
  systemd.user.services.t3code.environment = {
    T3CODE_TAILSCALE_SERVE = "true";
    T3CODE_TAILSCALE_SERVE_PORT = "3773";
  };
}
