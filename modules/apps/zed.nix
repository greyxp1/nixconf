{ ... }:
{
  flake.nixosModules.zed =
    { ... }:
    {
      home-manager.users.grey =
        { pkgs, ... }:
        {
          programs.zed-editor = {
            enable = true;

            extensions = [
              "html"
              "git-firefly"
              "nix"
              "kdl"
              "toml"
            ];

            userSettings = {
              session.trust_all_worktrees = true;
              collaboration_panel.button = false;
              window_decorations = "server";
              project_panel.dock = "left";
              git_panel.dock = "left";
              buffer_font_family = "JetBrainsMono Nerd Font";

              telemetry = {
                diagnostics = false;
                metrics = false;
              };

              agent = {
                sidebar_side = "right";
                dock = "right";
              };
            };
          };

          home.packages = with pkgs; [
            nil
            nixd
          ];
        };
    };
}
