{
  network = ./network.nix;
  firewall = ./firewall.nix;
  swaylock = ./swaylock.nix;

  __functionArgs = { };
  __functor = self: { ... }: {
    imports = with self; [
      network
      firewall
      swaylock
    ];
  };
}
