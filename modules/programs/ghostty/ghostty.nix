{
  flake.homeModules.ghostty = {
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
        custom-shader-animation = "always";
        custom-shader = ["${./cursor.glsl}"];
        keybind = [
          "ctrl+alt+h=goto_split:left"
          "ctrl+alt+j=goto_split:down"
          "ctrl+alt+k=goto_split:up"
          "ctrl+alt+l=goto_split:right"
          "ctrl+alt+y=select_all"
        ];
      };
    };
  };
}
