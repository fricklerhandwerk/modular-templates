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
in
{
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
