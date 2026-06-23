{
  outputs = {self, ...} @ args: let
    tackInputs = (import ./.tack) {overrides = args.tackOverrides or {};};
    inputs = tackInputs // {inherit self;};
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [(inputs.import-tree ./modules)];
      systems = ["x86_64-linux"];
    };
}
