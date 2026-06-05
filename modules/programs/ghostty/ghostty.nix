{...}: {
  flake.nixosModules.ghostty = {...}: {
    home-manager.users.grey = {...}: {
      programs.ghostty = {
        enable = true;
        settings = {
          background-opacity = 0.9;
          font-size = 13;
          #window-padding-x = 7;
          #window-padding-y = 7;
          window-padding-balance = true;
          window-padding-color = "extend";
          cursor-style-blink = false;
          confirm-close-surface = false;
          link-url = true;
          link-previews = true;
          clipboard-trim-trailing-spaces = true;
          custom-shader-animation = "always";
          custom-shader = [
            "${./shaders/cursor.glsl}"
          ];
        };
      };
    };
  };
}
