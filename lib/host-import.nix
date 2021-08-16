{ lib }: { hostName, profiles, root }: with lib; filter builtins.pathExists [
  (root + "/depot/hosts/${hostName}/nixos.nix")
  (root + "/depot/trusted/hosts/${hostName}/nixos.nix")
] ++ (if builtins.isAttrs profiles.base then profiles.base.imports
else singleton profiles.base) ++ singleton {
  home-manager.users.kat = {
    imports = filter builtins.pathExists [
      (root + "/depot/hosts/${hostName}/home.nix")
      (root + "/depot/trusted/hosts/${hostName}/home.nix")
    ];
  };
}
