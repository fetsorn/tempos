{
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };

  outputs = { self, nixpkgs }:
    let
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key:
                let
                  appendSystem = key: system: ret: { ${system} = ret.${key}; };
                in attrs // {
                  ${key} = (attrs.${key} or { })
                    // (appendSystem key system ret);
                };
            in builtins.foldl' op attrs (builtins.attrNames ret);
        in builtins.foldl' op { } systems;
      defaultSystems = [ "x86_64-linux" "aarch64-darwin" ];
    in eachSystem defaultSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };
        extempore = pkgs.stdenv.mkDerivation rec {
          pname = "extempore";
          version = "0.8.9";
          src = pkgs.fetchurl {
            url =
              "https://github.com/digego/${pname}/releases/download/v${version}/${pname}-v${version}-macos-11.0.zip";
            sha256 = "sha256-3PIGjYlf4rDKJxB/DBwDWFN9nEGIq9EczSS9xppmcqc=";
          };

          buildInputs = [ pkgs.unzip pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out
            cp -R * $out/
            makeWrapper $out/${pname} $out/bin/${pname} --add-flags "--sharedir $out"
          '';

          meta = {
            description =
              "A programming environment for cyberphysical programming";
            homepage = "https://extemporelang.github.io";
            maintainers = [ ];
            platforms = pkgs.lib.platforms.darwin;
          };
        };
        lambdamusic = (with pkgs;
          stdenv.mkDerivation rec {
            pname = "extempore-extensions";
            version = "v1.1";

            src = fetchFromGitHub {
              owner = "lambdamusic";
              repo = pname;
              rev = "e8fc50a";
              sha256 = "sha256-o9b1AaC27vBJsIx0ZzGQd5mXO/9dOfyZHWhQqA232lg=";
            };

            buildPhase = ''
              true
            '';
            installPhase = ''
              cp -r $src $out;
              substituteInPlace $out/LOAD_ALL.xtm --replace "/Users/michele.pasin/Dropbox/code/extempore/src/xtm-extensions/init/" "/Users/fetsorn/mm/codes/extempore-extensions/init/";
            '';

            meta = with lib; {
              description =
                " Michele Pasin's custom extensions to the Extempore programming environment";
              homepage = "https://github.com/lambdamusic/extempore-extensions";
              license = licenses.mit;
              platforms = platforms.darwin;
            };
          });
        preload = pkgs.writeScriptBin "extempore-preload" ''
          ${extempore}/bin/extempore --run ${lambdamusic}/LOAD_ALL.xtm
        '';
      in {
        packages = { inherit lambdamusic; };
        devShell = with pkgs;
          mkShell {
            buildInputs = [ extempore ];

            # Decorative prompt override so we know when we're in a dev shell
            shellHook = ''
              export PS1="[dev] $PS1"
            '';
          };
        defaultApp = {
          program = "${preload}/bin/${preload.name}";
          type = "app";
        };
      });
}
