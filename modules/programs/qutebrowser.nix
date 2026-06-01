{ ... }: {
  flake.nixosModules.qutebrowser = { lib, ... }: {
    home-manager.users.grey = { ... }: {
      programs.qutebrowser = {
        enable = true;
        searchEngines = { };
        settings = {
          auto_save.session = true;
          tabs.show = "multiple";
          tabs.title.format = "{current_title}";
          window.transparent = true;
          url.default_page = "http://192.168.1.66:4444";
          scrolling.bar = "never";
          statusbar.show = "in-mode";
          fonts.default_size = "11pt";
          colors.webpage.preferred_color_scheme = "dark";
        };

        extraConfig = lib.mkOrder 1501 ''
          # Overrides on top of catppuccin
          c.colors.tabs.bar.bg  = "#80000000"
          c.colors.tabs.even.bg = "#00000000"
          c.colors.tabs.even.fg = "#cdd6f4"
          c.colors.tabs.odd.bg  = "#00000000"
          c.colors.tabs.odd.fg  = "#cdd6f4"

          # Tab position logic
          try:
            try:
              from PyQt6.QtCore import QTimer as _QTimer
            except ImportError:
              from PyQt5.QtCore import QTimer as _QTimer
            from qutebrowser.utils import objreg as _objreg
            from qutebrowser.config import config as _cfg
            def _apply_tab_pos():
              for _wid in list(_objreg.window_registry):
                _tb = _objreg.get('tabbed-browser', scope='window', window=_wid)
                _cfg.instance.set_str('tabs.position', 'top' if _tb.widget.count() <= 5 else 'left', save_yaml=False)
                break
            def _setup():
              for wid in list(_objreg.window_registry):
                _objreg.get('tabbed-browser', scope='window', window=wid).widget.currentChanged.connect(lambda _: _apply_tab_pos())
              _apply_tab_pos()
            _QTimer.singleShot(500, _setup)
          except Exception:
            pass
        '';
      };
    };
  };
}
