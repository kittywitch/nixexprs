{
  dino-omemo = { dino, ... }: dino.overrideAttrs (
    { patches ? [ ], ... }: {
      patches = patches ++ [
        ./dino/0001-add-an-option-to-enable-omemo-by-default-in-new-conv.patch
      ];
    }
    );

    akiflags = import ./akiflags;

    libreelec-dvb-firmware = import ./libreelec-dvb-firmware/default.nix;
    fusionpbx = import ./fusionpbx;
    fusionpbx-apps = import ./fusionpbx-apps;

    fusionpbxWithApps = { symlinkJoin, fusionpbx, ... }: apps: symlinkJoin {
      inherit (fusionpbx) version name;
      paths = [ fusionpbx ] ++ apps;
    };
  }
