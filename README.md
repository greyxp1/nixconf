# Installation

```bash
curl -fsSL greyxp1.github.io/nixconf/i | bash
```

For AlmaLinux:

```bash
curl -fsSL https://greyxp1.github.io/nixconf/alma | bash
```

# T3 Code

On each host using T3 Connect, run `t3 connect link`, then `systemctl --user restart t3code`.

# Notes

Syncthing keeps `~/Documents/Notes` in sync on every host and the phone.

1. After installing or reinstalling a host, read its ID from a peer's pending devices or with `syncthing device-id --home ~/.config/syncthing`.
2. Set that ID in `devices` in `modules/core/syncthing.nix`, then rebuild every host.
3. On the phone, accept each host Syncthing-Fork offers. For a new phone, also accept the `notes` folder at `/storage/emulated/0/Documents/Notes` and open that folder as an Obsidian vault.

# Notes

Syncthing keeps `~/Documents/Notes` in sync on every host and the phone.

1. After installing or reinstalling a host, read its ID from a peer's pending devices or with `syncthing device-id --home ~/.config/syncthing`.
2. Set that ID in `devices` in `modules/core/syncthing.nix`, then rebuild every host.
3. On the phone, accept each host Syncthing-Fork offers. For a new phone, also accept the `notes` folder at `/storage/emulated/0/Documents/Notes` and open that folder as an Obsidian vault.

# Sunshine and Moonlight

1. Run `sudo tailscale up` on both PCs and use the same account.
2. Create the server's Sunshine login at `https://localhost:47990`.
3. On the client, run `moonlight pair <server>.tail1785c.ts.net -keydir ~/.local/share/moonlight`.
4. Open `https://<server>.tail1785c.ts.net:47990` on the client and enter the PIN.
