{ lib
, stdenv
, php
, fetchurl
, unzip
}:

stdenv.mkDerivation rec {
  pname = "XBackBone";
  version = "3.5.0";

  nativeBuildInputs = [
    unzip
  ];

  src = fetchurl {
    url = "https://github.com/SergiX44/XBackBone/releases/download/${version}/release-v${version}.zip";
    sha256 = "17p180yhsgjsm9pa5vkmqfrk71avss33vw2bjb6py90dwknbkipl";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out
    mv * $out
  '';

  meta = with lib; {
    description = "A lightweight file manager with full ShareX, Screencloud support and more";
    homepage = "https://xbackbone.app/";
    license = with licenses; agpl3;
    maintainers = with maintainers; [ kittywitch ];
    platforms = with platforms; unix;
  };
}
