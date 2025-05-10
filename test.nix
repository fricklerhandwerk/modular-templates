let
  inherit (import ./. { }) lib;

  inherit (lib) mkOption types;

  eval = modules: (lib.evalModules { inherit modules; }).config;

  container =
    {
      config,
      options,
      lib,
      ...
    }:
    {
      options.example = mkOption {
        description = "some arbitrary business logic data type";
        type =
          with types;
          submodule (example: {
            options = {
              data = mkOption {
                description = "sample data";
                type = with types; int;
              };
              templates = mkOption {
                description = "templates for rendering the business data to a string";
                type =
                  with types;
                  attrsOf (submoduleWith {
                    modules = [ template-interface ];
                  });
              };
              outputs = mkOption {
                description = "renderings based on configured templates";
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

  template-interface = template: {
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
  };

  fancy-template = fancy: {
    options = {
      custom-data = mkOption {
        description = "template-specific parameters";
        type = types.int;
      };
      nonsense = mkOption {
        description = "more template-specific parameters";
        type = types.str;
        default = "";
      };
      __toString = mkOption {
        description = "templates can in principle be used and rendered standalone";
        type = with types; functionTo str;
      };
    };
    config.__toString = _: toString fancy.config.custom-data + fancy.config.nonsense;
  };
in
{
  test-modular-templates = {
    expr =
      (eval [
        container
        {
          example = value: {
            data = 1;
            templates.fancy = {
              imports = [ fancy-template ];
              custom-data = value.config.data + 1;
            };
            templates.extra-fancy = extra-fancy: {
              imports = [ fancy-template ];
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
      fancy = "2";
      extra-fancy = "2a";
    };
  };
}
