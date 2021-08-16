{
  firewall = ./firewall.nix;
  fusionpbx = ./fusionpbx.nix;
  nftables = ./nftables.nix;

  __functionArgs = { };
  __functor = self: { ... }: {
    imports = with self; [
      firewall
      fusionpbx
      nftables
    ];
  };
}
