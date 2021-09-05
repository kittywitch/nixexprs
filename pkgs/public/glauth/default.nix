{ lib, git, fetchFromGitHub, buildGoModule, go-bindata }:

buildGoModule rec {
  pname = "glauth";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "glauth";
    repo = pname;
    rev = "v${version}";
    sha256 = "0g4a3rp7wlihn332x30hyvqb5izpcd7334fmghhvbv0pi4p7x9bf";
  };

  vendorSha256 = "0ljxpscs70w1zi1dhg0lhc31161380pfwwqrr32pyxvxc48mjj25";

  nativeBuildInputs = [ go-bindata ];
  buildInputs = [ git ];

  ldflags = [ "-X main.LastGitTag=v${version}" "-X main.GitTagIsCommit=1" ];

  preBuild = "go-bindata -pkg=assets -o=pkg/assets/bindata.go assets";

  postBuild = ''
    go build -ldflags "''${ldflags[*]}" -buildmode=plugin -o $out/bin/sqlite.so pkg/plugins/sqlite.go pkg/plugins/basesqlhandler.go
    go build -ldflags "''${ldflags[*]}" -buildmode=plugin -o $out/bin/postgres.so pkg/plugins/postgres.go pkg/plugins/basesqlhandler.go
    go build -ldflags "''${ldflags[*]}" -buildmode=plugin -o $out/bin/mysql.so pkg/plugins/mysql.go pkg/plugins/basesqlhandler.go
  '';

  doCheck = false;

  meta = with lib; {
    description = "A lightweight LDAP server for development, home use, or CI";
    inherit (src.meta) homepage;
    license = licenses.mit;
    maintainers = [ maintainers.kittywitch ];
    platforms = platforms.unix;
  };
}
