{
  network = ./network.nix;

  __functionArgs = { };
  __functor = self: { ... }: {
    imports = with self; [
      network
    ];
  };
}
