{ stdenv, fetchFromGitHub, nodejs, callPackage, nodePackages, libpng, libjpeg, giflib, librsvg, vips, glib, pkg-config }: let
  src = fetchFromGitHub {
    owner = "kittywitch";
    repo = "witchcore";
    sha256 = "08jhcq6277i6vvmm9988w6rgfs36fj0zbc7ba0d9xhd0nr8qzqsz";
    rev = "0fe220b231b93d37faaa07d6098207b878143fe0";
  };

  nodeComposition = callPackage ./node-packages.nix { };

  package = nodeComposition.shell.override {
    inherit src;
    buildInputs = [ libpng libjpeg giflib librsvg ];
    nativeBuildInputs = [ nodePackages.node-pre-gyp nodePackages.node-gyp pkg-config vips glib ];
  };
in stdenv.mkDerivation rec {
  name = "kat-website";
  inherit src;
  inherit (package) nodeDependencies;
  buildInputs = [ nodejs nodePackages.gatsby-cli ];
  buildPhase = ''
    ln -s $nodeDependencies/lib/node-modules
    export PATH="$nodeDependencies/bin:$PATH"
    gatsby build
  '';
  installPhase = ''
    mkdir $out
    cp -r public $out
  '';
}
