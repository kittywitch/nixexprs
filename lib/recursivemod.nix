{ lib }: { folder, ... }@args: with lib; let
  lister = base: path:
    let
      dirContents = builtins.readDir path;
      isDir = entry: _: dirContents."${entry}" == "directory";
      hasDefault = entry: _: dirContents ? entry;
      directories = filterAttrs isDir dirContents;
      pather = objects: mapAttrs' (obj: type: nameValuePair (if nixFileMatch obj != null then head (nixFileMatch obj) else obj) (toString (path + "/${obj}"))) objects;
      nixFileMatch = entry: builtins.match "(.*)\\.nix" entry;
      nixFileFilter = entry: _: nixFileMatch entry != null && builtins.length (nixFileMatch entry) > 0;
      nixFiles = pather (filterAttrs nixFileFilter dirContents);
      settingsFiles = (mapAttrsToList (_: n: n) (filterAttrs (n: _: n == "settings") nixFiles));
      functor =
        let
          settings = {
            excludes = [ ];
            external = [ ];
          } // lib.optionalAttrs (length settingsFiles > 0) (import (head settingsFiles) args);
          withoutExcludes = attrValues (filterAttrs (n: _: !elem n settings.excludes) nixFilePaths);
        in
        {
          __functor = self: { ... }: {
            imports = withoutExcludes ++ settings.external;
          };
        };
      nixFilePaths = filterAttrs (n: _: n != "settings") nixFiles;
      directoryPaths = pather directories;
      recurser = (mapAttrs (_: fullpath: lister base fullpath) directoryPaths);
      result = recurser // nixFilePaths // functor;
    in
    result;
in
lister folder folder
