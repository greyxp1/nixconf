{
  substituters = [
    "https://cache.numtide.com"
    "https://nix-community.cachix.org"
    "https://catppuccin.cachix.org"
    "https://greyxp1.cachix.org"
    # Remove with the temporary upstream Tack pin.
    "https://cache.manic.systems"
  ];
  trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    "greyxp1.cachix.org-1:hUnQC8sjfKykPgkFdcXiuv4xjiISuWnBnPfW2F2df3k="
    # Remove with the temporary upstream Tack pin.
    "cache.manic.systems-1:s6OZanN8Us8vRi0jVivP3qlMn0cYHBjBALKrNe5nH8s="
  ];
}
