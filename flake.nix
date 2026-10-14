
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

        # Pin application versions here.
        canvasVersion = "1.27.1";

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
            # Resolve paths relative to the flake directory.
            export OPENHANDS_ENV_ROOT="$PWD"
            export UV_PROJECT_ENVIRONMENT="$OPENHANDS_ENV_ROOT/.venv"
            export OPENHANDS_NPM_PREFIX="$OPENHANDS_ENV_ROOT/.npm-local"

            export PATH="$UV_PROJECT_ENVIRONMENT/bin:$OPENHANDS_NPM_PREFIX/bin:$PATH"

            # Install OpenHands CLI.
            if [ ! -x "$UV_PROJECT_ENVIRONMENT/bin/openhands" ]; then
              echo "Installing OpenHands CLI..."

              uv venv \
                --python python3.12 \
                "$UV_PROJECT_ENVIRONMENT"

              uv pip install \
                --python "$UV_PROJECT_ENVIRONMENT/bin/python" \
                openhands || echo "WARNING: CLI installation failed"
            fi

            # Install Agent Canvas locally.
            if [ ! -x "$OPENHANDS_NPM_PREFIX/bin/agent-canvas" ]; then
              echo "Installing OpenHands Agent Canvas..."

              mkdir -p "$OPENHANDS_NPM_PREFIX"

              npm install \
                --prefix "$OPENHANDS_NPM_PREFIX" \
                --no-audit \
                --no-fund \
                "@openhands/agent-canvas@${canvasVersion}" \
                || echo "WARNING: Agent Canvas installation failed"
            fi

            # Reuse OpenAI-compatible configuration if available.
            if [ -z "''${LLM_API_KEY:-}" ] && [ -n "''${PURDUE_GENAI_API_KEY:-}" ]; then
              export LLM_API_KEY="$PURDUE_GENAI_API_KEY"
            fi

            echo ""
            echo "======================================"
            echo " OpenHands Development Environment"
            echo "======================================"
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
            echo "  agent-canvas"
            echo "    Modern web UI (http://localhost:8000)"
            echo ""
            echo "  openhands --override-with-envs"
            echo "    OpenHands terminal interface"
            echo ""
            echo "  openhands web --host 127.0.0.1 --port 12000"
            echo "    Terminal-style browser interface"
            echo ""
          '';
        };
      });
}

