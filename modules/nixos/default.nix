{
  fusionpbx = ./fusionpbx.nix;

  __functionArgs = { };
  __functor = self: { ... }: {
    imports = with self; [
      fusionpbx
    ];
  };
}
