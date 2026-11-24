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

install_hooks() {
  local hooks_dir="$HOME/.claude/hooks/pipeline"
  mkdir -p "$hooks_dir"
  cp "$SCRIPT_DIR"/hooks/*.sh "$hooks_dir/"
  chmod +x "$hooks_dir/"*.sh
  echo "Hooks instalados em: $hooks_dir"
}

cleanup_legacy_in_dir() {
  local base_dir="$1"
  local legacy_files=(
    "$base_dir/agents/coder.md"
    "$base_dir/agents/tester.md"
    "$base_dir/agents/simplifier.md"
    "$base_dir/agents/reviewer.md"
    "$base_dir/commands/pipeline-v2.md"
  )

  for file in "${legacy_files[@]}"; do
    if [ -f "$file" ]; then
      rm -f "$file"
      echo "Removido arquivo legado (v1): $file"
    fi
  done
}

install_pipeline_files() {
  local target_dir="$1"
  mkdir -p "$target_dir/commands" "$target_dir/agents"
  cp "$SCRIPT_DIR/pipeline.md" "$target_dir/commands/"
  cp "$SCRIPT_DIR"/agents/*.md "$target_dir/agents/"
  echo "Comando instalado em: $target_dir/commands/pipeline.md"
  echo "Agentes instalados em: $target_dir/agents/"
}

main() {
  parse_args "$@"
  check_dependencies

  local target_dir
  if [ "$MODE" = "global" ]; then
    target_dir="$HOME/.claude"
  else
    target_dir="$PROJECT_DIR/.claude"
  fi

  install_hooks
  install_pipeline_files "$target_dir"

  cleanup_legacy_in_dir "$target_dir"
  if [ "$target_dir" != "$HOME/.claude" ]; then
    cleanup_legacy_in_dir "$HOME/.claude"
  fi

  echo ""
  echo "Instalação concluída. Reinicie o Claude Code para carregar o comando /pipeline e os agentes."
  if [ "$MODE" = "project" ]; then
    echo "Nota: aceite o diálogo de confiança do workspace no Claude Code se usar hooks locais."
  fi
}

main "$@"
