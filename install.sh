#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=""
PROJECT_DIR=""

usage() {
  cat <<'EOF'
Uso: ./install.sh [--global | --project <caminho>]

Instala ou atualiza o pipeline-Claude (comando, agentes e hooks).

Opções:
  --global             Instala globalmente em ~/.claude/ (padrão se nenhuma opção for passada)
  --project <caminho>  Instala no projeto em <caminho>/.claude/ (hooks sempre vão para ~/.claude/hooks/pipeline/)
  -h, --help           Exibe esta ajuda
EOF
}

parse_args() {
  if [ $# -eq 0 ]; then
    MODE="global"
    return
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --global)
        if [ -n "$MODE" ] && [ "$MODE" != "global" ]; then
          echo "Erro: --global e --project não podem ser usados juntos." >&2
          exit 1
        fi
        MODE="global"
        shift
        ;;
      --project)
        if [ -n "$MODE" ] && [ "$MODE" != "project" ]; then
          echo "Erro: --global e --project não podem ser usados juntos." >&2
          exit 1
        fi
        if [ $# -lt 2 ] || [ -z "$2" ]; then
          echo "Erro: --project exige um <caminho>." >&2
          exit 1
        fi
        MODE="project"
        PROJECT_DIR="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Erro: opção desconhecida '$1'." >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  if [ "$MODE" = "project" ]; then
    if [ ! -d "$PROJECT_DIR" ]; then
      echo "Erro: diretório do projeto não encontrado: $PROJECT_DIR" >&2
      exit 1
    fi
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
  fi
}

check_dependencies() {
  local missing=0

  if ! command -v git >/dev/null 2>&1; then
    echo "Erro: 'git' não encontrado. Necessário para controle de branch, diff e commits do pipeline." >&2
    missing=1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "Erro: 'python3' não encontrado. Necessário para os hooks em ~/.claude/hooks/pipeline/." >&2
    missing=1
  fi

  if [ "$missing" -ne 0 ]; then
    exit 1
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "Aviso: 'gh' (GitHub CLI) não encontrado. A abertura automática de PRs ficará indisponível." >&2
  fi
}

main() {
  parse_args "$@"
  check_dependencies
  if [ "$MODE" = "global" ]; then
    echo "Modo selecionado: global ($HOME/.claude)"
  else
    echo "Modo selecionado: projeto ($PROJECT_DIR/.claude)"
  fi
}

main "$@"
