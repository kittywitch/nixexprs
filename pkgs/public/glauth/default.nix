{ lib, fetchFromGitHub, buildGoModule, go-bindata }:

buildGoModule rec {
  pname = "glauth";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "glauth";
    repo = pname;
    rev = "v${version}";
    hash = "0000000000000000000000000000000000000000000000000000";
  };

  vendorSha256 = "0000000000000000000000000000000000000000000000000000";

  nativeBuildInputs = [ go-bindata ];

  buildFlagsArray = [ "-ldflags=-X main.LastGitTag=v${version} -X main.GitTagIsCommit=1" ];

  preBuild = "go-bindata -pkg=assets -o=pkg/assets/bindata.go assets";

  postBuild = ''
    make plugins
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
