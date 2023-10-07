{
  description = "My secrets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      imports = [inputs.devshell.flakeModule inputs.treefmt-nix.flakeModule];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        treefmt = {
          programs.alejandra.enable = true;
          programs.deadnix.enable = true;
          programs.statix.enable = true;
          programs.prettier.enable = true;
          flakeFormatter = true;
          projectRootFile = "flake.nix";
        };
        devshells.default = {
          packages = [config.treefmt.build.wrapper pkgs.fish];
        };
      };
      flake = {
        nixosModules.secrets = import ./modules/secrets;
      };
    };
}
