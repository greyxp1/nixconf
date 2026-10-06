{
  flake.wrappers.foot = {wlib, ...}: {
    imports = [wlib.wrapperModules.foot];
    settings = {
      main = {
        font = "JetBrains Mono:size=14";
        dpi-aware = "yes";
        pad = "8x8";
      };
      cursor = {
        style = "beam";
        blink = "no";
      };
      scrollback.lines = 10000;
      colors-dark.alpha = 0.8;
    };
  };
}
