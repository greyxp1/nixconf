{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../_custom-modules/fzf.nix
    ../_custom-modules/direnv.nix
    ../_custom-modules/zoxide.nix
  ];
  environment.systemPackages = [
    inputs.neo-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.fishPlugins.hydro.overrideAttrs {src = inputs.hydro;})
    pkgs.util-linux
  ];

  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish = {
    enable = true;
    useBabelfish = true;

    shellAliases = {
      ls = "nls";
      clean = "nh clean all --optimise --keep 1";
      rebuild = "nh os switch";
    };

    interactiveShellInit = ''
      set -g fish_greeting
      set -g fish_color_command blue
      set -g fish_color_param green
      set -g fish_cursor_default line
      fish_vi_cursor
      set -g hydro_symbol_start '  '
      set -g hydro_color_start 769ff0
    '';

    shellFunctions = {
      fish_user_key_bindings.body = ''
        bind ctrl-l 'clear; commandline -f repaint'
        bind tab 'commandline --showing-suggestion; and commandline -f accept-autosuggestion; or commandline -f complete'
        bind ctrl-j 'commandline --paging-mode; and commandline -f down-line; or commandline -f complete'
        bind ctrl-k 'commandline --paging-mode; and commandline -f up-line'
      '';

      update.body = ''
        set -l previous_dir $PWD
        cd /home/grey/Projects/nixconf; or return
        begin
          set -lx GH_TOKEN (gh auth token --hostname github.com)
          and tack update
          and rebuild
        end
        set -l update_status $status
        cd "$previous_dir"
        return $update_status
      '';

      restore-ssh-key.body = ''
        mkdir -p ~/.ssh; and chmod 700 ~/.ssh; or return
        echo 'Paste your SSH private key, then press Ctrl+D:'
        cat > ~/.ssh/id_ed25519
        chmod 600 ~/.ssh/id_ed25519
        ssh-add ~/.ssh/id_ed25519
      '';
    };
  };
}
