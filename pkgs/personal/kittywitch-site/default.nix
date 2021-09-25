{ stdenv, fetchFromGitHub, nodejs, callPackage, nodePackages, libpng, libjpeg, giflib, librsvg, vips, glib, pkg-config }: let
  src = fetchFromGitHub {
    owner = "kittywitch";
    repo = "witchcore";
    sha256 = "0b4nb4kf516d2zsj60blgkj7086jjp4d54h3534644m0d5b4bjyk";
    rev = "c5eb70f292b34def282df18a562032df8c7d571b";
  };

  nodeComposition = callPackage ./node-packages.nix { };

  package = nodeComposition.shell.override {
    inherit src;
    buildInputs = [ libpng libjpeg giflib librsvg vips glib ];
    nativeBuildInputs = [ nodePackages.node-pre-gyp nodePackages.node-gyp pkg-config ];
  };
in stdenv.mkDerivation rec {
  name = "kat-website";
  inherit src;
  inherit (package) nodeDependencies;
  buildInputs = [ nodejs ];
  buildPhase = ''
    HOME=$(pwd)
    mkdir -p .config/gatsby
    mkdir -p .cache
    cp -r $nodeDependencies/lib/node_modules node_modules
    chmod 0777 -R node_modules
    export PATH="$nodeDependencies/bin:$PATH"
    gatsby build
  '';
  installPhase = ''
    mkdir $out
    cp -r public/* $out
  '';
}
