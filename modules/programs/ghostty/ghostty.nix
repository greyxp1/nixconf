{...}: {
  flake.nixosModules.ghostty = {...}: {
    home-manager.users.grey = {...}: {
      programs.ghostty = {
        enable = true;
        settings = {
          cursor-style = "bar";
          background-opacity = 0.81;
          font-size = 14;
          window-padding-x = 8;
          window-padding-y = 8;
          window-padding-color = "extend";
          cursor-style-blink = false;
          confirm-close-surface = false;
          link-url = true;
          link-previews = true;
          clipboard-trim-trailing-spaces = true;
          copy-on-select = "clipboard";
          selection-background = "#0078D7";
          custom-shader-animation = "always";
          custom-shader = ["${./cursor.glsl}"];
        };
      };
    };
  };
}
