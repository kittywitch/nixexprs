self: super: let
  pkgs'' = import ../pkgs;
  pkgs' = pkgs''.public // pkgs''.personal // pkgs''.overrides;
  pkgs = builtins.mapAttrs (_: pkg: self.callPackage pkg { }) pkgs';
in pkgs
