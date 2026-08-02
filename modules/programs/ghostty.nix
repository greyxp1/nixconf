{inputs, ...}: {
  flake.homeModules.ghostty = {
    programs.ghostty = {
      enable = true;
      settings = {
        background-opacity = 0.8;
        font-size = 14;
        window-padding-x = 8;
        window-padding-y = 8;
        window-padding-color = "extend";
        cursor-style-blink = false;
        confirm-close-surface = false;
        link-url = true;
        link-previews = true;
        clipboard-trim-trailing-spaces = true;
        selection-background = "#0078D7";
        custom-shader-animation = "always";
        custom-shader = ["${inputs.ghostty-cursor-shader}/cursor.glsl"];
        keybind = [
          "ctrl+alt+h=goto_split:left"
          "ctrl+alt+j=goto_split:down"
          "ctrl+alt+k=goto_split:up"
          "ctrl+alt+l=goto_split:right"
        ];
      };
    };
  };
}
