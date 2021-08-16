{
  nixlib = import <nixpkgs/lib>;
  pkgs = import ./pkgs.nix;
  lib = import ./lib.nix;

  __functor = fp: with fp; nixlib.composeManyExtensions [
    lib
    pkgs
  ];
}
