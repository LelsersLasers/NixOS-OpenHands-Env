#!/usr/bin/env bash
set -e

export LLM_MODEL="openai/qwen3.8:27b"
export LLM_BASE_URL="https://genai.rcac.purdue.edu/api"
export LLM_API_KEY="${PURDUE_GENAI_API_KEY:-${OPENAI_API_KEY:-}}"

cd "$(dirname "$0")"
exec nix develop "$@"
