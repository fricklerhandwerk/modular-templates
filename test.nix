let
  inherit (import ./. { }) lib;
  eval = modules: (lib.evalModules { inherit modules; }).config;
  base =
    {
      config,
      options,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.example = mkOption {
        type =
          with types;
          submodule (example: {
            options = {
              data = mkOption {
                type = with types; int;
              };
              __toString = mkOption {
                type = with types; functionTo str;
                default = self: toString self.data;
              };
              output = mkOption {
                type = types.str;
                default = toString example.config;
                readOnly = true;
              };
            };
          });
      };
    };
  many-templates =
    {
      config,
      options,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.example = mkOption {
        type =
          with types;
          submodule (example: {
            options = {
              data = mkOption {
                type = with types; int;
              };
              templates = mkOption {
                type = with types; attrsOf (functionTo str);
              };
              outputs = mkOption {
                type = with types; attrsOf str;
                default = lib.mapAttrs (name: template: template example.config) example.config.templates;
                readOnly = true;
              };
            };
          });
      };
      # NOTE: can't set it the type's `default` as that will always be overridden
      config.example.templates.simple = value: toString value.data;
    };
  modular-templates =
    {
      config,
      options,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.example = mkOption {
        type =
          with types;
          submodule (example: {
            options = {
              data = mkOption {
                type = with types; int;
              };
              templates = mkOption {
                type =
                  with types;
                  attrsOf (submoduleWith {
                    modules = [
                      (template: {
                        options.__toString = mkOption {
                          type = with types; functionTo str;
                        };
                        options.__value = mkOption {
                          description = ''
                            all native values of the template, can be used for overriding it
                          '';
                          type = with types; attrs;
                          default = lib.removeAttrs template.config [
                            "__toString"
                            "__value"
                          ];
                        };
                      })
                    ];
                  });
              };
              outputs = mkOption {
                type = with types; attrsOf str;
                default = lib.mapAttrs (name: template: toString template) example.config.templates;
                readOnly = true;
              };
            };
            config.templates.simple = {
              __toString = _: toString example.config.data;
            };
          });
      };
    };
in
{
  test-modular-templates = {
    expr =
      let
        fancy =
          fancy:
          let
            inherit (fancy.lib) mkOption types;
          in
          {
            options = {
              extra-data = mkOption {
                type = types.int;
              };
              nonsense = mkOption {
                type = types.str;
                default = "";
              };
              __toString = mkOption {
                type = with types; functionTo str;
              };
            };
            config.__toString = _: toString fancy.config.extra-data + fancy.config.nonsense;
          };
      in
      (eval [
        modular-templates
        {
          example = value: {
            data = 1;
            templates.fancy = {
              imports = [ fancy ];
              extra-data = value.config.data + 2;
            };
            templates.extra-fancy = extra-fancy: {
              imports = [ fancy ];
              # override an existing template!
              config = value.config.templates.fancy.__value // {
                nonsense = "a";
              };
            };
          };
        }
      ]).example.outputs;
    expected = {
      simple = "1";
      fancy = "3";
      extra-fancy = "3a";
    };
  };
  test-many-templates = {
    expr =
      (eval [
        many-templates
        {
          example = {
            data = 1;
            templates.fancy = self: toString (self.data + 1);
          };
        }
      ]).example.outputs;
    expected = {
      simple = "1";
      fancy = "2";
    };
  };
  test-override-template = {
    expr =
      (eval [
        base
        {
          example = {
            data = 1;
            __toString = self: toString (self.data + 1);
          };
        }
      ]).example.output;
    expected = "2";
  };
  test-simple-template = {
    expr =
      (eval [
        base
        {
          example = {
            data = 1;
          };
        }
      ]).example.output;
    expected = "1";
  };
}
