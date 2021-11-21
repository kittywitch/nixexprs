{
  foldr = op: nul: list:
    let
      len = builtins.length list;
      fold' = n:
        if n == len
        then nul
        else op (builtins.elemAt list n) (fold' (n + 1));
    in fold' 0;
  composeExtensions =
    f: g: final: prev:
      let fApplied = f final prev;
          prev' = prev // fApplied;
      in fApplied // g final prev';
  composeManyExtensions =
    foldr (x: y: composeExtensions x y) (final: prev: {});

  pkgs = import ./pkgs.nix;
  lib = import ./lib.nix;

  __functor = fp: with fp; composeManyExtensions [
    lib
    pkgs
  ];
}
