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

main() {
  parse_args "$@"
  if [ "$MODE" = "global" ]; then
    echo "Modo selecionado: global ($HOME/.claude)"
  else
    echo "Modo selecionado: projeto ($PROJECT_DIR/.claude)"
  fi
}

main "$@"
