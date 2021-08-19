{ fetchgit, stdenv, lib, bundler, ruby, bundlerEnv }:

stdenv.mkDerivation rec {
  pname = "kat-website";
  version = "0.1";

  src = fetchgit {
    rev = "28bb172dd56a6ced301a7b96bc0bf8f1fce7e0d6";
    url = "https://github.com/kittywitch/website";
    sha256 = "0092xzksar7d2lqaqbrbycwxk965kyyqsj0dgl0kaqdvipjrb809";
  };

  jekyll_env = bundlerEnv rec {
    name = "jekyll_env";
    inherit ruby;
    gemfile = "${src}/Gemfile";
    lockfile = "${src}/Gemfile.lock";
    gemset = ./gemset.nix;
  };

  buildInputs = [ bundler ruby jekyll_env ];

  installPhase = ''
    mkdir $out
    ${jekyll_env}/bin/jekyll build -d $out
  '';
}

