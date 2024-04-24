
{
  description = "A very basic flake";
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    haskellNix.inputs.nixpkgs-unstable.follows = "nixpkgs";
    # nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    nixpkgs.url = "github:NixOs/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
    agda-language-server = {
      url = "github:agda/agda-language-server";
      # url = "github:zmrocze/agda-language-server?ref=c2ae939";
      flake = false;
    };
  };

  outputs = { self, agda-language-server, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem 
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
      (system:
    let
      overlays = [ haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          helloProject =
            final.haskell-nix.project' {
              src = agda-language-server;
              compiler-nix-name = "ghc928";
              shell.tools = {};
                modules = [{
                  # see https://github.com/IntersectMBO/plutus/blob/b97e8be50470065f37948f62dcaa7d67f71b9a39/nix/agda-project.nix#L14 for explanation
                  # and https://github.com/input-output-hk/haskell.nix/issues/2186 for bug report.
                  packages.Agda.package.buildType = nixpkgs.lib.mkForce "Simple";
                  packages.Agda.components.library.enableSeparateDataOutput = nixpkgs.lib.mkForce true;
                  packages.Agda.components.library.postInstall = ''
                    # Compile the executable using the package DB we've just made, which contains
                    # the main Agda library
                    ghc src/main/Main.hs -package-db=$out/package.conf.d -o agda

                    # Find all the files in $data
                    shopt -s globstar
                    files=($data/**/*.agda)
                    for f in "''${files[@]}" ; do
                      echo "Compiling $f"
                      # This is what the custom setup calls in the end
                      ./agda --no-libraries --local-interfaces $f
                    done
                  '';
                }];
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
