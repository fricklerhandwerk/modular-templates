let
  inherit (import ./. { }) lib;
  eval = modules: lib.evalModules { inherit modules; };
in
{
}
