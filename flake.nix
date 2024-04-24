
{
  description = "A very basic flake";
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    haskellNix.inputs.nixpkgs-unstable.follows = "nixpkgs";
    # nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    nixpkgs.url = "github:NixOs/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
    agda-language-server = {
      # url = "github:agda/agda-language-server";
      url = "github:zmrocze/agda-language-server?ref=c2ae939";
      flake = false;
    };
  };

  outputs = { self, agda-language-server, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
    let
      overlays = [ haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          helloProject =
            final.haskell-nix.project' {
              src = agda-language-server;
              compiler-nix-name = "ghc928";
              shell.tools = {};
            };
        })
      ];
      pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
      flake = pkgs.helloProject.flake {};
    in flake // {
      # Built by `nix build .`
      packages.default = (flake.packages."agda-language-server:exe:als");
      # .overrideAttrs (oldAttrs: oldAttrs // {
      #   # installInputs = [ pkgs.zlib ] ;
      # });
    });
}
