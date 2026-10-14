{
  description = "Local AI agent development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          openssl
          libffi
          sqlite
        ];
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Python
            python312
            uv

            # JavaScript
            nodejs_24

            # Development tools
            git
            gcc
            pkg-config
            curl
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libraries;

          shellHook = ''
            export UV_PROJECT_ENVIRONMENT="$PWD/.venv"

            # Install OpenHands if not already installed.
            if [ ! -x "$UV_PROJECT_ENVIRONMENT/bin/openhands" ]; then
              echo "Installing OpenHands CLI..."
              uv venv --python python3.12 "$UV_PROJECT_ENVIRONMENT"
              uv pip install \
                --python "$UV_PROJECT_ENVIRONMENT/bin/python" \
                openhands
            fi

            export PATH="$UV_PROJECT_ENVIRONMENT/bin:$PATH"

            echo ""
            echo "Development environment ready."
            echo ""
            echo "Commands:"
            echo "  openhands --override-with-envs"
            echo "  openhands web --host 127.0.0.1 --port 12000"
            echo ""
          '';
        };
      });
}
