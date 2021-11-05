{
  akiflags = import ./akiflags;

  hedgedoc-cli = import ./hedgedoc-cli;

  xbackbone = import ./xbackbone;

  fusionpbx = import ./fusionpbx;
  fusionpbx-apps = import ./fusionpbx-apps;

  fusionpbxWithApps = { symlinkJoin, fusionpbx, ... }: apps: symlinkJoin {
    inherit (fusionpbx) version name;
    paths = [ fusionpbx ] ++ apps;
  };

  yggdrasil-held = import ./yggdrasil;
}
