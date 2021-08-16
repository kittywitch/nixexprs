{
  nixpkgs ? import <nixpkgs> { },
  nixlib ? nixpkgs.lib
}: rec {
  modules = import ./modules;
  overlays = import ./overlays;
  pkgs'' = import ./pkgs;
  pkgs' = pkgs''.public // pkgs''.personal;
  pkgs = builtins.mapAttrs (_: pkg: nixpkgs.callPackage pkg { }) pkgs';
  lib = pkgs'.lib;
}
