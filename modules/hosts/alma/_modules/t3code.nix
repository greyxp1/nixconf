{
  lib,
  nixos,
  ...
}: {
  alma.packages = ["at-spi2-core"];
  environment.etc =
    lib.mapAttrs' (name: file:
      # Codex skips symlinked SKILL.md files, which system-manager creates from directories.
        if lib.hasPrefix "codex/skills/" name
        then
          lib.nameValuePair "${name}/SKILL.md" {
            source = "${file.source}/SKILL.md";
            mode = "0444";
          }
        else lib.nameValuePair name {inherit (file) source;})
    (lib.filterAttrs (name: _: lib.hasPrefix "codex/" name || lib.hasPrefix "claude-code/" name) nixos.environment.etc);
}
