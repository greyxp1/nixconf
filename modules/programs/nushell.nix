{
  flake.nixosModules.nushell = {
    pkgs,
    username,
    ...
  }: {
    environment.shells = [pkgs.nushell];
    users.users.${username}.shell = pkgs.nushell;
  };

  flake.homeModules.nushell = {
    config,
    osConfig,
    ...
  }: {
    programs.nushell = {
      enable = true;
      environmentVariables = config.home.sessionVariables;
      settings.show_banner = false;
      shellAliases = {
        rebuild = "nh os switch";
        update = "do { cd ${osConfig.programs.nh.flake}; ^tack update; ^nh os switch }";
        home = "sudo systemctl restart home-manager-${config.home.username}.service";
        clean = "nh clean all --optimise --keep 1";
        codex = "do { cd ${osConfig.programs.nh.flake}; ^codex resume --all }";
      };

      extraConfig = ''
        $env.__skip_prompt_spacing = true
        $env.config.hooks.display_output = { table --icons --index false}

        def --env clear [] {
          ^clear
          print -n "\u{1b}[3J"
          $env.__skip_prompt_spacing = true
        }

        def restore-ssh-key [] {
          mkdir ~/.ssh
          chmod 700 ~/.ssh
          $in | save --force ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          do { ^ssh-add ~/.ssh/id_ed25519 e> /dev/null } | complete | ignore
        }

        def sync-windows-esp [] {
          let win_esp = "/dev/disk/by-partuuid/95bb7bd9-3cd8-4eba-acc5-e395455bbc2e"
          let mnt = (^mktemp -d | str trim)

          ^sudo mount $win_esp $mnt
          if $env.LAST_EXIT_CODE != 0 {
            ^rmdir $mnt
            error make {msg: "Failed to mount the Windows ESP"}
          }

          ^sudo cp -r $"($mnt)/EFI/Microsoft" /boot/EFI/
          let copy_status = $env.LAST_EXIT_CODE

          ^sudo umount $mnt
          let unmount_status = $env.LAST_EXIT_CODE

          if $unmount_status == 0 {
            ^rmdir $mnt
          }

          if $copy_status != 0 {
            error make {msg: "Failed to copy the Windows boot files"}
          }

          if $unmount_status != 0 {
            error make {msg: $"Failed to unmount ($mnt)"}
          }

          print "Windows ESP synced to /boot/EFI/Microsoft"
        }

        $env.config.hooks.pre_prompt = (
          $env.config.hooks.pre_prompt
          | append {||
              if ($env.__skip_prompt_spacing? | default false) {
                hide-env __skip_prompt_spacing
              } else {
                print ""
              }
            }
        )

        $env.config.keybindings ++= [
          {
            name: accept_suggestion_or_complete
            modifier: none
            keycode: tab
            mode: emacs
            event: {
              until: [
                {send: historyhintcomplete}
                {send: menu name: completion_menu}
              ]
            }
          }
          {
            name: clear_scrollback
            modifier: control
            keycode: char_l
            mode: emacs
            event: {
              send: executehostcommand
              cmd: "clear"
            }
          }
          {
            name: completion_down
            modifier: control
            keycode: char_j
            mode: emacs
            event: {
              until: [
                {send: menu name: completion_menu}
                {send: menunext}
              ]
            }
          }
          {
            name: completion_up
            modifier: control
            keycode: char_k
            mode: emacs
            event: {send: menuprevious}
          }
        ]
      '';
    };
  };
}
