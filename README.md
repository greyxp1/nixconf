# Installation

```bash
curl -fsSL https://greyxp1.github.io/nixconf/i | bash
```

# T3 Code

1. Run `t3 connect`, then `systemctl --user restart t3code` on each host. Use the same account.
2. Sign in at [app.t3.codes](https://app.t3.codes).

# Sunshine and Moonlight

1. Run `sudo tailscale up` on both PCs and use the same account.
2. Create the server's Sunshine login at `https://localhost:47990`.
3. On the client, run `moonlight pair <server>.tail1785c.ts.net -keydir ~/.local/share/moonlight`.
4. Open `https://<server>.tail1785c.ts.net:47990` on the client and enter the PIN.
