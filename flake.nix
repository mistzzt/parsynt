{
  description = "Automatic parallel divide-and-conquer programs synthesizer";

  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    nixpkgs.follows = "opam-nix/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    opam-nix,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (opam-nix.lib.${system}) buildDuneProject;

      parsynt =
        (buildDuneProject {} "Parsynt" ./. {
          ocaml-base-compiler = "*";
        })
        .Parsynt;
    in {
      parsynt = parsynt.overrideAttrs (final: prev: {
        preConfigure = ''
          mkdir -p $out
          cp -r $src/src $out

          project_dir_src_path=$PWD/src/utils/Project_dir.ml
          rm $project_dir_src_path || true
          touch $project_dir_src_path
          echo "let base = \"$out\"" >> $project_dir_src_path
          echo "let src = \"$out/src/\"" >> $project_dir_src_path
          echo "let templates = \"$out/src/templates/\"" >> $project_dir_src_path
          echo "let racket = \"${pkgs.racket}/bin/racket\"" >> $project_dir_src_path
          echo "let z3 = \"${pkgs.z3}/bin/z3\"" >> $project_dir_src_path
        '';
      });
      default = self.packages.${system}.parsynt;
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.parsynt];

        packages = with pkgs;
          [
            racket
            z3
            python311
            cvc5

            ocamlformat
            ocaml-lsp
          ]
          ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.CoreServices
          ];

        shellHook = ''
          # opam init -n && eval $(opam env)
          # opam option --global depext=false

          raco pkg install rosette
          raco pkg install src/synthools

          mkdir -p ~/.local/share/racket/8.10/pkgs/rosette/bin/
          ln -s ${pkgs.z3}/bin/z3 ~/.local/share/racket/8.10/pkgs/rosette/bin/z3 || true

          project_dir_src_path=$PWD/src/utils/Project_dir.ml
          rm $project_dir_src_path || true
          touch $project_dir_src_path
          echo "let base = \"$PWD\"" >> $project_dir_src_path
          echo "let src = \"$PWD/src/\"" >> $project_dir_src_path
          echo "let templates = \"$PWD/src/templates/\"" >> $project_dir_src_path
          echo "let racket = \"${pkgs.racket}/bin/racket\"" >> $project_dir_src_path
          echo "let z3 = \"${pkgs.z3}/bin/z3\"" >> $project_dir_src_path
        '';
      };
    });
  };
}
