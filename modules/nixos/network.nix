{ config, lib, tf, pkgs, ... }:

with lib;

let
  cfg = config.network;
in
{
  options.network = {
    enable = mkEnableOption "Use kat's network module?";
    addresses = mkOption {
      type = with types; attrsOf (submodule ({ name, options, config, ... }: {
        options = {
          enable = mkEnableOption "Is the system a part of the ${name} network?" // {
            default = config.ipv4.enable || config.ipv6.enable;
          };
          ipv4 = {
            enable = mkOption {
              type = types.bool;
              default = options.ipv4.address.isDefined;
            };
            address = mkOption {
              type = types.str;
            };
          };
          ipv6 = {
            enable = mkOption {
              type = types.bool;
              default = options.ipv6.address.isDefined;
            };
            address = mkOption {
              type = types.str;
            };
          };
          prefix = mkOption {
            type = types.nullOr types.str;
          };
          subdomain = mkOption {
            type = types.nullOr types.str;
          };
          domain = mkOption {
            type = types.nullOr types.str;
            default = "${config.subdomain}.${cfg.dns.domain}";
          };
          out = {
            identifierList = mkOption {
              type = types.listOf types.str;
              default = if config.enable then singleton config.domain ++ config.out.addressList else [ ];
            };
            addressList = mkOption {
              type = types.listOf types.str;
              default = if config.enable then concatMap (i: optional i.enable i.address) [ config.ipv4 config.ipv6 ] else [ ];
            };
          };
        };
      }));
    };
    extraCerts = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };
    privateGateway = mkOption {
      type = types.str;
      default = "192.168.1.254";
    };
    tf = {
      enable = mkEnableOption "Was the system provisioned by terraform?";
      ipv4_attr = mkOption {
        type = types.str;
        default = "ipv4_address";
      };
      ipv6_attr = mkOption {
        type = types.str;
        default = "ipv6_address";
      };
    };
    dns = {
      enable = mkEnableOption "Do you want DNS to be semi-managed through this module?";
      isRoot = mkEnableOption "Is this system supposed to be the @ for the domain?";
      email = mkOption {
        type = types.nullOr types.str;
      };
      tld = mkOption {
        type = types.nullOr types.str;
      };
      domain = mkOption {
        type = types.nullOr types.str;
      };
    };
  };

  config =
    let
      networks = cfg.addresses;
      networksWithDomains = filterAttrs (_: v: v.subdomain != null && v.enable) networks;
    in
    mkIf cfg.enable {
      lib.kw.virtualHostGen = args: virtualHostGen ({ inherit config; } // args);

      network = {
        dns = mkIf cfg.dns.enable {
          domain = builtins.substring 0 ((builtins.stringLength cfg.dns.tld) - 1) cfg.dns.tld;
        };
        addresses = {
          private = mkIf cfg.dns.enable {
            prefix = "int";
            subdomain = "${config.networking.hostName}.${cfg.addresses.private.prefix}";
          };
          public = mkMerge [
            (mkIf cfg.tf.enable {
              ipv4.address = mkIf (cfg.tf.ipv4_attr != null) (tf.resources."${config.networking.hostName}".refAttr config.network.tf.ipv4_attr);
              ipv6.address = mkIf (cfg.tf.ipv6_attr != null) (tf.resources."${config.networking.hostName}".refAttr config.network.tf.ipv6_attr);
            })
            (mkIf cfg.dns.enable {
              subdomain = "${config.networking.hostName}";
            })
          ];
          yggdrasil = mkIf cfg.yggdrasil.enable {
            ipv6.address = cfg.yggdrasil.address;
            prefix = "ygg";
            subdomain = "${config.networking.hostName}.${cfg.addresses.yggdrasil.prefix}";
          };
        };
      };

      services.yggdrasil.package = pkgs.yggdrasil-held;

      networking = mkIf cfg.addresses.private.enable {
        inherit (config.network.dns) domain;
        defaultGateway = cfg.privateGateway;
      };

      deploy.tf.dns.records =
        let
          recordsV4 = mapAttrs'
            (n: v:
              nameValuePair "node_${n}_${config.networking.hostName}_v4" {
                enable = v.ipv4.enable;
                tld = cfg.dns.tld;
                domain = v.subdomain;
                a.address = v.ipv4.address;
              })
            networksWithDomains;
          recordsV6 = mapAttrs'
            (n: v:
              nameValuePair "node_${n}_${config.networking.hostName}_v6" {
                enable = v.ipv6.enable;
                tld = cfg.dns.tld;
                domain = v.subdomain;
                aaaa.address = v.ipv6.address;
              })
            networksWithDomains;
        in
        mkMerge (map (record: mkIf cfg.dns.enable record) [
          recordsV4
          recordsV6
          (mkIf cfg.dns.isRoot {
            "node_root_${config.networking.hostName}_v4" = {
              enable = cfg.addresses.public.enable;
              tld = cfg.dns.tld;
              domain = "@";
              a.address = cfg.addresses.public.ipv4.address;
            };
            "node_root_${config.networking.hostName}_v6" = {
              enable = cfg.addresses.public.enable;
              tld = cfg.dns.tld;
              domain = "@";
              aaaa.address = cfg.addresses.public.ipv6.address;
            };
          })
        ]);

      security.acme.certs = mkMerge (map (cert: mkIf cfg.dns.enable cert) [
        (mkIf config.services.nginx.enable (mapAttrs'
          (n: v:
            nameValuePair "${n}_${config.networking.hostName}" {
              inherit (v) domain;
              dnsProvider = "rfc2136";
              credentialsFile = config.secrets.files.dns_creds.path;
              group = mkDefault "nginx";
            })
          networksWithDomains))
        (mapAttrs'
          (n: v:
            nameValuePair "${n}" {
              domain = v;
              dnsProvider = "rfc2136";
              credentialsFile = config.secrets.files.dns_creds.path;
              group = mkDefault "nginx";
            })
          cfg.extraCerts)
      ]);

      services.nginx.virtualHosts = mkMerge (map (host: mkIf cfg.dns.enable host) [
        (mkIf config.services.nginx.enable (mapAttrs'
          (n: v:
            nameValuePair v.domain {
              useACMEHost = "${n}_${config.networking.hostName}";
              forceSSL = true;
            })
          networksWithDomains))
        (mapAttrs'
          (n: v:
            nameValuePair v {
              useACMEHost = "${n}";
              forceSSL = true;
            })
          cfg.extraCerts)
      ]);

      _module.args = { inherit (config.lib) kw; };
    };
}
