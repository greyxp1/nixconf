root: let
  collect = relative: let
    entries = builtins.readDir (root + relative);
  in
    builtins.concatMap (name: let
      subpath = "${relative}/${name}";
      type = entries.${name};
    in
      if builtins.match ".*/_.*" subpath != null
      then []
      else if type == "directory"
      then collect subpath
      else if type == "regular" && builtins.match ".*\\.nix" subpath != null
      then [(root + subpath)]
      else []) (builtins.attrNames entries);
in {
  imports = collect "";
}
