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
in
{
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
