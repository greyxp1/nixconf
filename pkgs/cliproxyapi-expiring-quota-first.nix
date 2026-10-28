{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "cliproxyapi-expiring-quota-first";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "stavarengo";
    repo = "CLIProxyAPI-Expiring-Quota-First";
    rev = "9e122a3987fd63caecdb6b5992ab99a863035d2f";
    hash = "sha256-hBZnaoLyLmmivSCS0o+ST9nj9ce5hEYAtA8ASBkwQi0=";
  };

  vendorHash = "sha256-U5O+xl/4dJZd6zs4d8qRZbZrZRIVn4+d46y/KJ7iwTg=";
  env.CGO_ENABLED = 1;

  buildPhase = ''
    runHook preBuild
    go build -trimpath -buildmode=c-shared \
      -ldflags="-s -w -X main.version=${version}" \
      -o expiring-quota-first.so .
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 expiring-quota-first.so \
      $out/lib/cliproxyapi/plugins/expiring-quota-first.so
    runHook postInstall
  '';

  meta = {
    description = "Weekly reset-first scheduler plugin for CLIProxyAPI";
    homepage = "https://github.com/stavarengo/CLIProxyAPI-Expiring-Quota-First";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
  };
}
