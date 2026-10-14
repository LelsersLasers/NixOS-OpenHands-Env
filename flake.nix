
{
  description = "OpenHands Agent Canvas on NixOS";

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

        canvasVersion = "1.27.1";
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python312
            uv
            nodejs_24
            git
            gcc
            pkg-config
            curl
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libraries;

          shellHook = ''
            export OPENHANDS_ENV_ROOT="$PWD"
            export OPENHANDS_NPM_PREFIX="$OPENHANDS_ENV_ROOT/.npm-local"

            export PATH="$OPENHANDS_NPM_PREFIX/bin:$PATH"

            # Install Canvas independently of the Python CLI.
            if [ ! -x "$OPENHANDS_NPM_PREFIX/bin/agent-canvas" ]; then
              echo "Installing OpenHands Agent Canvas..."

              mkdir -p "$OPENHANDS_NPM_PREFIX"

              npm install \
                --prefix "$OPENHANDS_NPM_PREFIX" \
                --no-audit \
                --no-fund \
                "@openhands/agent-canvas@${canvasVersion}"

              if [ ! -x "$OPENHANDS_NPM_PREFIX/bin/agent-canvas" ]; then
                echo "ERROR: Agent Canvas executable not found."
                echo "Check npm installation output."
                return 1
              fi
            fi

            if [ -z "''${LLM_API_KEY:-}" ] &&
               [ -n "''${PURDUE_GENAI_API_KEY:-}" ]; then
              export LLM_API_KEY="$PURDUE_GENAI_API_KEY"
            fi

            echo ""
            echo "OpenHands Agent Canvas environment ready."
            echo ""

            echo "LLM Configuration:"
            echo "  Model:    ''${LLM_MODEL:-<unset>}"
            echo "  Base URL: ''${LLM_BASE_URL:-<unset>}"

            if [ -n "''${LLM_API_KEY:-}" ]; then
              echo "  API Key:  ******** (set)"
            else
              echo "  API Key:  <unset>"
            fi

            echo ""
            echo "Available commands:"
            echo ""
            echo "Run:"
            echo "  agent-canvas"
            echo ""
            echo "UI: http://localhost:8000"
          '';
        };
      });
}

