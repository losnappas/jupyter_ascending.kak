{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    systems.url = "github:nix-systems/default";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = import inputs.systems;
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {

          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          devenv.shells.default = {
            # https://devenv.sh/reference/options/
            languages.nix.enable = true;
            languages.python = {
              enable = true;
              venv.enable = true;
              venv.requirements = ./requirements.txt;
            };

            packages =
              with pkgs.python312Packages;
              [
                python-lsp-server
                pyls-isort
                python-lsp-ruff
                distutils
              ]
              ++ [
                pkgs.just
              ];

            enterShell = ''
              export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
            '';

          };

          formatter = pkgs.nixfmt-rfc-style;

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.default = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
            pname = "jupyter-ascending-kak";
            version = "1.0.0";
            src = ./rc;
          };
        };
      flake = {
        # Does this make any sense, quite a lot of work -_-...
        hmModules = {
          jupyter-ascending-kak =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            with lib;
            let
              cfg = config.programs.kakoune.jupyter-ascending;
            in
            {
              options.programs.kakoune.jupyter-ascending = {
                enable = mkEnableOption "jupyter-ascending-kak";
              };
              config = mkIf cfg.enable {
                programs.kakoune.plugins = [
                  (self.packages.${pkgs.stdenv.hostPlatform.system}.default)
                ];
              };
            };
        };
      };
    };
}
