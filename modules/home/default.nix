{
  network = ./network.nix;
  firewall = ./firewall.nix;

  __functionArgs = { };
  __functor = self: { ... }: {
    imports = with self; [
      network
      firewall
    ];
  };
}
