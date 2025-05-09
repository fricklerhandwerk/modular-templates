let
  sources = import ./npins;
in
{
  nixpkgs ? sources.nixpkgs,
}:
let
  lib = import "${nixpkgs}/lib";
in
{
  inherit lib;
  nixpkgs =
    {
      system ? builtins.currentSystem,
      config ? { },
      overlays ? [ ],
      ...
    }@nixpkgs-config:
    let
      pkgs = import nixpkgs nixpkgs-config;
      run-tests = pkgs.writeShellApplication {
        name = "run-tests";
        text =
          with pkgs;
          with lib;
          ''
            ${getExe nix-unit} ${toString ./test.nix} "$@"
          '';
      };
      test-loop = pkgs.writeShellApplication {
        name = "test-loop";
        text =
          with pkgs;
          with lib;
          ''
            ${getExe watchexec} -w ${toString ./.} -- ${getExe run-tests}
          '';
      };
    in
    {
      shell = pkgs.mkShellNoCC {
        packages = lib.attrValues {
          inherit (pkgs) npins;
          inherit run-tests test-loop;
        };
        shellHook = ''
          echo "run tests in a loop with '${test-loop.name}'"
        '';
      };
    };
}
