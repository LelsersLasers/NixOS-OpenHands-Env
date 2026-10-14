
{
  description = "OpenHands CLI with Purdue GenAI on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

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
            python312
            uv
            git
            gcc
            pkg-config
            curl
            nodejs_24
          ];

          LD_LIBRARY_PATH =
            pkgs.lib.makeLibraryPath libraries;

          shellHook = ''
            export UV_PROJECT_ENVIRONMENT="$PWD/.venv"

            export LLM_MODEL="openai/qwen3.8:27b"
            export LLM_BASE_URL="https://genai.rcac.purdue.edu/api"

            # Use the user's existing API key.
            if [ -n "''${PURDUE_GENAI_API_KEY:-}" ]; then
              export LLM_API_KEY="$PURDUE_GENAI_API_KEY"
            elif [ -n "''${OPENAI_API_KEY:-}" ]; then
              export LLM_API_KEY="$OPENAI_API_KEY"
            fi

            # Keep Python packages in this directory.
            if [ ! -x "$UV_PROJECT_ENVIRONMENT/bin/openhands" ]; then
              echo "Installing OpenHands CLI..."
              uv venv --python python3.12 "$UV_PROJECT_ENVIRONMENT"
              uv pip install --python "$UV_PROJECT_ENVIRONMENT/bin/python" openhands
            fi

            export PATH="$UV_PROJECT_ENVIRONMENT/bin:$PATH"

            echo ""
            echo "OpenHands environment ready."
            echo "Model: $LLM_MODEL"
            echo "Endpoint: $LLM_BASE_URL"
            echo ""
            echo "Commands:"
            echo "  openhands --override-with-envs"
            echo "  openhands web --host 127.0.0.1 --port 12000"
            echo ""

            if [ -z "''${LLM_API_KEY:-}" ]; then
              echo "WARNING: No API key found."
              echo "Set PURDUE_GENAI_API_KEY before starting."
            fi
          '';
        };
      });
}

