{pkgs, ...}: {
  services.caddy = {
    enable = true;
    openFirewall = true;
    globalConfig = ''
      default_bind 192.168.1.2
    '';
    virtualHosts."greyxp1.root.sx" = {
      logFormat = null;
      extraConfig = ''
        encode zstd gzip
        redir /jellyfin /jellyfin/ 308
        handle /jellyfin/* {
          reverse_proxy 127.0.0.1:8097
        }
        handle {
          root * ${pkgs.writeTextDir "index.html" ''
          <!doctype html>
          <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <meta name="theme-color" content="#141414">
              <title>grey</title>
              <style>
                :root { color-scheme: dark; font-family: system-ui, sans-serif; background: #141414; color: #eee; }
                * { box-sizing: border-box; }
                body { margin: 0; }
                main { max-width: 600px; margin: 64px auto; padding: 0 24px; }
                section { padding: 24px 0; }
                section:first-child { padding-top: 0; }
                section + section { border-top: 1px solid #333; }
                .row { display: flex; align-items: center; justify-content: space-between; gap: 16px; }
                h2 { margin: 0; font-size: 18px; font-weight: 550; }
                a { color: inherit; }
                .open, button { background: #eee; color: #141414; padding: 8px 14px; border: 0; border-radius: 6px; text-decoration: none; font: inherit; font-size: 14px; cursor: pointer; }
                button { background: #272727; color: #ddd; }
                .open:hover { background: white; }
                button:hover { background: #353535; }
                a:focus-visible, button:focus-visible, summary:focus-visible { outline: 2px solid #eee; outline-offset: 4px; }
                .address { display: block; margin-top: 8px; color: #aaa; overflow-wrap: anywhere; }
                code { font-family: ui-monospace, monospace; font-size: 13px; }
                details { margin-top: 16px; font-size: 14px; color: #aaa; line-height: 1.6; }
                summary { width: fit-content; cursor: pointer; }
                p { margin: 12px 0 0; }
                .command { display: block; margin-top: 4px; color: #eee; overflow-wrap: anywhere; }
                @media (max-width: 480px) { main { margin-top: 32px; } }
              </style>
            </head>
            <body>
              <main>
                <section aria-labelledby="jellyfin">
                  <div class="row"><h2 id="jellyfin">Jellyfin</h2><a class="open" href="/jellyfin/web/#/login">Open Jellyfin ↗</a></div>
                </section>
                <section aria-labelledby="minecraft">
                  <div class="row"><h2 id="minecraft">Minecraft</h2><button type="button" data-copy="greyxp1.root.sx" aria-label="Copy Minecraft address">Copy address</button></div>
                  <code class="address">greyxp1.root.sx</code>
                  <details>
                    <summary>How to join</summary>
                    <p>Use the shared password:<code class="command">/login PASSWORD</code></p>
                  </details>
                </section>
                <section aria-labelledby="palworld">
                  <div class="row"><h2 id="palworld">Palworld</h2><button type="button" data-copy="greyxp1.root.sx:8211" aria-label="Copy Palworld address">Copy address</button></div>
                  <code class="address">greyxp1.root.sx:8211</code>
                </section>
              </main>
              <script>
                window.addEventListener('pageshow', () => {
                  const link = document.querySelector('.open')
                  link.hash = '/login'
                  try {
                    const servers = JSON.parse(localStorage.getItem('jellyfin_credentials') || '{}').Servers || []
                    const signedIn = localStorage.getItem('enableAutoLogin') !== 'false' &&
                      servers.some(server => server.ManualAddress === `''${location.origin}/jellyfin` && server.AccessToken)
                    if (signedIn) link.hash = '/home'
                  } catch {}
                })

                document.querySelectorAll('[data-copy]').forEach(button => {
                  button.addEventListener('click', async () => {
                    try {
                      await navigator.clipboard.writeText(button.dataset.copy)
                      button.textContent = 'Copied'
                    } catch {
                      button.textContent = 'Select the address below'
                    }
                    setTimeout(() => { button.textContent = 'Copy address' }, 2000)
                  })
                })
              </script>
            </body>
          </html>
        ''}
          file_server
        }
      '';
    };
  };

  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/caddy";
      user = "caddy";
      group = "caddy";
    }
  ];
  systemd.services.caddy = {
    requires = ["preservation.target"];
    after = ["preservation.target" "network-online.target"];
    wants = ["network-online.target"];
    unitConfig.RequiresMountsFor = ["/var/lib/caddy"];
  };

  networking.firewall.allowedUDPPorts = [8211];
}
