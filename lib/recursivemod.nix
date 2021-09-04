{ lib }: { folder, ... }@args: with lib; let
  lister = { base, path, nextRun ? { } }:
    let
      moduleStruct = { config, ... }: {
        options = {
          defaultOnly = mkOption {
            type = types.bool;
            description = "The attrSet returned is the default called with the directory contents";
            default = false;
          };
          excludes = mkOption {
            type = types.listOf types.str;
            description = "Any imports you want excluded";
            default = [ ];
          };
          recursiveInclude = mkOption {
            type = types.bool;
            description = "Recursively default and enable import";
            default = false;
          };
          includeFolders = {
            enable = mkOption {
              type = types.bool;
              description = "Provide the folders within this folder in the functor";
              default = false;
            };
            default = {
              enable = mkOption {
                type = types.bool;
                description = "Instead of recursing, use a specified filename for each folder";
                default = false;
              };
            };
          };
          functor = {
            enable = mkOption {
              type = types.bool;
              description = "Provide a functor for this folder";
              default = false;
            };
            excludes = mkOption {
              description = "Any imports you want excluded from the functor";
              type = types.listOf types.str;
              default = [ ];
            };
            external = mkOption {
              description = "Any other imports you want included into the functor";
              type = types.listOf types.unspecified;
              default = [ ];
            };
            includeFolders = {
              enable = mkOption {
                type = types.bool;
                description = "Provide the folders within this folder in the functor";
                default = false;
              };
              default = {
                enable = mkOption {
                  type = types.bool;
                  description = "Instead of recursing, use a specified filename for each folder";
                  default = false;
                };
                file = mkOption {
                  type = types.nullOr types.str;
                  default = "default";
                };
              };
            };
          };
        };
      };
      dirContents = builtins.readDir path;
      isDir = entry: _: dirContents."${entry}" == "directory";
      hasDefault = entry: _: dirContents ? entry;
      directories = filterAttrs isDir dirContents;
      pather = objects: mapAttrs' (obj: type: nameValuePair (if nixFileMatch obj != null then head (nixFileMatch obj) else obj) (toString (path + "/${obj}"))) objects;
      nixFileMatch = entry: builtins.match "(.*)\\.nix" entry;
      nixFileFilter = entry: _: nixFileMatch entry != null && builtins.length (nixFileMatch entry) > 0;
      nixFiles = pather (filterAttrs nixFileFilter dirContents);
      settingsFiles = (mapAttrsToList (_: n: n) (filterAttrs (n: _: n == "settings") nixFiles));
      settingsMod = evalModules {
        modules = singleton moduleStruct
          ++ lib.optional (length settingsFiles > 0) (head settingsFiles)
          ++ singleton nextRun;
        specialArgs = { inherit lib; } // args;
      };
      settings = settingsMod.config;
      fsettings = settings.functor;
      functor =
        let
          withoutExcludes =
            if fsettings.includeFolders.enable then
              (
                let
                  directorySpans =
                    if fsettings.includeFolders.default.enable then
                      (filterAttrs (name: dir: builtins.pathExists dir) (mapAttrs (name: dir: "${path}/${name}/${fsettings.includeFolders.default.file}.nix") directoryPaths))
                    else
                      attrValues mapAttrs ((name: dir: recurser.${name}) directoryPaths);
                in
                attrValues (filterAttrs (n: _: !elem n fsettings.excludes) (nixFilePaths // directorySpans))
              )
            else attrValues (filterAttrs (n: _: !elem n fsettings.excludes) nixFilePaths);
        in
        if fsettings.enable then {
          __functor = self: { ... }: {
            imports = withoutExcludes ++ fsettings.external;
          };
        } else { };
      nixFilePaths = filterAttrs (n: _: n != "settings") nixFiles;
      directoryPaths = pather directories;
      recurser = (mapAttrs
        (_: fullpath: lister {
          inherit base; path = fullpath;
          nextRun = optionalAttrs settings.recursiveInclude { includeFolders = { enable = true; default.enable = true; }; };
        })
        directoryPaths);
      result =
        if settings.defaultOnly then
          (import (path + "/${fsettings.includeFolders.default.file}.nix") (
            args // {
              inherit lib;
              tree = {
                dirs = recurser;
                defaultDirs =
                  if settings.includeFolders.default.enable then
                    (filterAttrs (name: dir: builtins.pathExists dir) (mapAttrs (name: dir: "${path}/${name}/${fsettings.includeFolders.default.file}.nix") directoryPaths)) else { };
                files = nixFilePaths;
              };
            }
          ))
        else if settings.includeFolders.enable then
          let
            defaultDirs =
              if settings.includeFolders.default.enable then
                (filterAttrs (name: dir: builtins.pathExists dir) (mapAttrs (name: dir: "${path}/${name}/${fsettings.includeFolders.default.file}.nix") directoryPaths)) else { };
            files = nixFilePaths;
          in
          removeAttrs (defaultDirs // files // functor) settings.excludes
        else
          removeAttrs (recurser // nixFilePaths // functor) settings.excludes;
    in
    result;
in
lister { base = folder; path = folder; }
