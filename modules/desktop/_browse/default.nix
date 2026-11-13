{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  makeWrapper,
  nodejs,
  source,
}: let
  version = (builtins.fromJSON (builtins.readFile "${source}/package.json")).version;
in
  buildNpmPackage {
    pname = "opencode-browse";
    inherit version;
    src = fetchurl {
      url = "https://registry.npmjs.org/@opencode/browse/-/browse-${version}.tgz";
      hash = "sha256-TUb6MjrpUVzTSPlPPIUJ8FzPE7rVI0O3h4KhhRLtqo4=";
    };
    sourceRoot = "package";
    patches = [./release-interception.patch];
    npmDepsHash = "sha256-l0j9TzFaMVjDCtlVNVqzoQ3j2sZeYPdH8Z7iGwn3aSU=";
    nativeBuildInputs = [jq makeWrapper];
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
      ${lib.getExe jq} 'del(.devDependencies)' package.json > package.json.tmp
      mv package.json.tmp package.json
    '';
    npmFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/browse" "$out/bin"
      cp -r dist skills package.json node_modules "$out/lib/browse/"
      install -Dm444 LICENSE "$out/share/licenses/opencode-browse/LICENSE"
      makeWrapper ${lib.getExe nodejs} "$out/bin/browse" \
        --add-flags "$out/lib/browse/dist/cli.mjs" \
        --set OPENCODE_BROWSER_AUTO_UPDATE off \
        --set OPENCODE_BROWSER_UPDATE_CHECK 0
      runHook postInstall
    '';
    meta = {
      description = "Browser automation for MCP clients through a Chromium extension";
      homepage = "https://github.com/anomalyco/browse";
      license = lib.licenses.mit;
      mainProgram = "browse";
      platforms = lib.platforms.linux;
    };
  }
