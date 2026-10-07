#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Chronos AD · Instalador Interativo
#  v1.0.0 · by ADisruptiva
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/chronos-ad"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DEST="$CONFIG_DIR/statusline.sh"
CONFIG_DEST="$CONFIG_DIR/config.sh"

# ── Cores pra UX (independente da statusline) ─────────────────────────────────
B='\033[1m'; D='\033[2m'; G='\033[0;32m'; Y='\033[0;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'

banner() {
  printf "\n${C}═══════════════════════════════════════════════════════════════${N}\n"
  printf "  ${B}Chronos AD${N} ${D}·${N} ancoragem temporal pro Claude Code\n"
  printf "  ${D}v1.0.0 · by ADisruptiva · MIT License${N}\n"
  printf "${C}═══════════════════════════════════════════════════════════════${N}\n\n"
}

ask() {
  local label="$1" default="$2" varname="$3" answer=""
  if [[ -n "$default" ]]; then
    printf "${B}%s${N} ${D}[%s]${N}: " "$label" "$default"
  else
    printf "${B}%s${N}: " "$label"
  fi
  read -r answer
  if [[ -z "$answer" && -n "$default" ]]; then
    answer="$default"
  fi
  printf -v "$varname" '%s' "$answer"
}

ask_yn() {
  local label="$1" default="$2" varname="$3" answer="" prompt
  if [[ "$default" == "s" ]]; then prompt="[S/n]"; else prompt="[s/N]"; fi
  printf "${B}%s${N} ${D}%s${N}: " "$label" "$prompt"
  read -r answer
  if [[ -z "$answer" ]]; then answer="$default"; fi
  local lower
  lower=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    s|sim|y|yes) printf -v "$varname" '1' ;;
    *)           printf -v "$varname" '0' ;;
  esac
}

# ── 0. Banner + requisitos ────────────────────────────────────────────────────
banner

printf "${B}→ Verificando requisitos...${N}\n"
MISSING=()
for cmd in bash python3 jq awk sed ps stty; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISSING+=("$cmd")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  printf "  ${R}✗ Faltam: %s${N}\n" "${MISSING[*]}"
  printf "    ${Y}Instale antes de prosseguir:${N}\n"
  printf "      macOS:  brew install %s\n" "${MISSING[*]}"
  printf "      Ubuntu: sudo apt install %s\n\n" "${MISSING[*]}"
  exit 1
fi
printf "  ${G}✓ Todos os comandos necessários disponíveis.${N}\n\n"

# ── Defaults inteligentes ─────────────────────────────────────────────────────
SYS_TZ=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || echo "UTC")
SYS_CITY=$(echo "$SYS_TZ" | awk -F/ '{print $NF}' | tr '_' ' ')
SYS_LOCALE_BASE="pt_BR"
if ! locale -a 2>/dev/null | grep -qi "^pt_BR"; then
  SYS_LOCALE_BASE=$(locale 2>/dev/null | grep LC_TIME | head -1 | cut -d= -f2 | tr -d '"' | cut -d. -f1 || echo "en_US")
fi

printf "${B}→ Personalização da Chronos AD ${D}(12 perguntas · Enter aceita o default)${N}\n\n"

# ── 1. Tier ───────────────────────────────────────────────────────────────────
printf "${D}[1/12]${N} "
ask "Seu plano Claude (aparece antes do modelo, vazio = omite)?" "" TIER

# ── 2. Fuso primário ──────────────────────────────────────────────────────────
printf "${D}[2/12]${N} "
ask "Fuso primário (formato IANA, ex: America/Sao_Paulo)?" "$SYS_TZ" PRIMARY_TZ
if [[ ! -f "/usr/share/zoneinfo/$PRIMARY_TZ" ]]; then
  printf "  ${Y}⚠ Aviso: '/usr/share/zoneinfo/$PRIMARY_TZ' não existe — verifique se é válido.${N}\n"
fi

# ── 3. Label primário ─────────────────────────────────────────────────────────
DEFAULT_LABEL=$(echo "$PRIMARY_TZ" | awk -F/ '{print $1}' | cut -c1-2 | tr '[:lower:]' '[:upper:]')
printf "${D}[3/12]${N} "
ask "Rótulo curto do fuso primário (ex: BR, PT, ES)?" "$DEFAULT_LABEL" PRIMARY_TZ_LABEL

# ── 4. Fuso secundário ────────────────────────────────────────────────────────
printf "${D}[4/12]${N} "
ask_yn "Quer mostrar um SEGUNDO fuso (útil entre 2 países)?" "n" HAS_SECONDARY

SECONDARY_TZ=""
SECONDARY_TZ_LABEL=""
if [[ "$HAS_SECONDARY" == "1" ]]; then
  printf "${D}[5/12]${N} "
  ask "Qual fuso secundário (ex: Europe/Rome, America/New_York)?" "Europe/Rome" SECONDARY_TZ

  DEFAULT_SEC_LABEL=$(echo "$SECONDARY_TZ" | awk -F/ '{print $1}' | cut -c1-2 | tr '[:lower:]' '[:upper:]')
  printf "${D}[6/12]${N} "
  ask "Rótulo curto do fuso secundário (ex: IT, NY, JP)?" "$DEFAULT_SEC_LABEL" SECONDARY_TZ_LABEL
else
  printf "${D}[5/12 + 6/12 pulados — sem fuso secundário]${N}\n"
fi

# ── 7. Localização ────────────────────────────────────────────────────────────
printf "${D}[7/12]${N} "
ask "Cidade/região para o ícone 📍?" "$SYS_CITY" LOCATION

# ── 8. Emojis ─────────────────────────────────────────────────────────────────
printf "${D}[8/12]${N} "
ask_yn "Mostrar emojis 🕐 📍 📅 (se sua fonte suportar)?" "s" SHOW_EMOJIS

# ── 9. Data ───────────────────────────────────────────────────────────────────
printf "${D}[9/12]${N} "
ask_yn "Mostrar linha 2 direita (dia da semana + data)?" "s" SHOW_DATE

# ── 10. Idioma ────────────────────────────────────────────────────────────────
printf "${D}[10/12]${N} ${B}Idioma para nome do dia/mês?${N}\n"
printf "        Opções: ${D}pt_BR | es_ES | en_US | it_IT${N}\n"
ask "        Idioma" "$SYS_LOCALE_BASE" LANG_BASE
LANG_TIME="${LANG_BASE}.UTF-8"

# ── 11. Margem direita ────────────────────────────────────────────────────────
printf "${D}[11/12]${N} ${B}Margem direita (cols de respiro antes da parede)?${N}\n"
printf "        ${D}Aumente se vir corte (5 = default · 8+ pra split panes)${N}\n"
ask "        Margem" "5" MARGIN_RIGHT

# ── 12. Cor da identidade ─────────────────────────────────────────────────────
printf "${D}[12/12]${N} ${B}Cor ANSI 256 da identidade default?${N}\n"
printf "        Sugestões: ${D}39 azul · 208 laranja · 220 âmbar · 99 roxo · 250 cinza${N}\n"
ask "        Cor (0-255)" "250" IDENTITY_COLOR

# ── Resumo + confirmação ──────────────────────────────────────────────────────
printf "\n${C}═══════════════════════════════════════════════════════════════${N}\n"
printf "  ${B}Resumo da configuração${N}\n"
printf "${C}═══════════════════════════════════════════════════════════════${N}\n"
printf "  Tier             : %s\n" "${TIER:-(omitido)}"
printf "  Fuso primário    : %s (rótulo: %s)\n" "$PRIMARY_TZ" "$PRIMARY_TZ_LABEL"
if [[ -n "$SECONDARY_TZ" ]]; then
  printf "  Fuso secundário  : %s (rótulo: %s)\n" "$SECONDARY_TZ" "$SECONDARY_TZ_LABEL"
fi
printf "  Localização      : %s\n" "$LOCATION"
printf "  Emojis           : %s\n" "$([[ $SHOW_EMOJIS == 1 ]] && echo sim || echo não)"
printf "  Mostra data      : %s\n" "$([[ $SHOW_DATE == 1 ]] && echo sim || echo não)"
printf "  Idioma data      : %s\n" "$LANG_TIME"
printf "  Margem direita   : %s\n" "$MARGIN_RIGHT"
printf "  Cor identidade   : ANSI 256-%s\n" "$IDENTITY_COLOR"
printf "${C}═══════════════════════════════════════════════════════════════${N}\n\n"

ask_yn "Confirma e instala?" "s" CONFIRM
if [[ "$CONFIRM" != "1" ]]; then
  printf "${Y}Instalação cancelada. Nada foi alterado.${N}\n"
  exit 0
fi

# ── Instalação ────────────────────────────────────────────────────────────────
printf "\n${B}→ Instalando...${N}\n"

mkdir -p "$CONFIG_DIR"
cp "$REPO_DIR/statusline.sh" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"
printf "  ${G}✓${N} Script em %s\n" "$SCRIPT_DEST"

if [[ -f "$CONFIG_DEST" ]]; then
  cp "$CONFIG_DEST" "$CONFIG_DEST.bak-$(date +%Y%m%d-%H%M%S)"
  printf "  ${G}✓${N} Config anterior preservado (backup .bak)\n"
fi

cat > "$CONFIG_DEST" <<EOF
#!/usr/bin/env bash
# Chronos AD · configuração gerada pelo instalador em $(date '+%Y-%m-%d %H:%M:%S')
# Edite manualmente quando quiser · próxima interação no Claude Code usa.

TIER="$TIER"
PRIMARY_TZ="$PRIMARY_TZ"
PRIMARY_TZ_LABEL="$PRIMARY_TZ_LABEL"
SECONDARY_TZ="$SECONDARY_TZ"
SECONDARY_TZ_LABEL="$SECONDARY_TZ_LABEL"
LOCATION="$LOCATION"
SHOW_DATE=$SHOW_DATE
SHOW_EMOJIS=$SHOW_EMOJIS
LANG_TIME="$LANG_TIME"
MARGIN_RIGHT=$MARGIN_RIGHT
IDENTITY_COLOR=$IDENTITY_COLOR
MIN_COLS_FOR_RIGHT_BLOCK=100
EOF
printf "  ${G}✓${N} Config em %s\n" "$CONFIG_DEST"

if [[ ! -f "$SETTINGS" ]]; then
  mkdir -p "$(dirname "$SETTINGS")"
  cat > "$SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "bash $SCRIPT_DEST"
  }
}
EOF
  printf "  ${G}✓${N} %s criado\n" "$SETTINGS"
else
  cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
  tmp=$(mktemp)
  jq --arg cmd "bash $SCRIPT_DEST" \
     '.statusLine = {"type":"command","command":$cmd}' \
     "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  printf "  ${G}✓${N} %s atualizado (backup .bak preservado)\n" "$SETTINGS"
fi

printf "\n${B}→ Preview da sua Chronos AD:${N}\n\n"
TEST_OUT=$(echo '{"cwd":"'"$HOME"'/projeto-exemplo","model":{"display_name":"Opus 4.7 (1M context)"},"context_window":{"used_percentage":15,"context_window_size":1000000},"rate_limits":{"five_hour":{"used_percentage":8},"seven_day":{"used_percentage":12}}}' | COLUMNS=140 bash "$SCRIPT_DEST" 2>&1 || true)
if [[ -n "$TEST_OUT" ]]; then
  echo "$TEST_OUT" | sed 's/^/    /'
else
  printf "    ${R}✗ Script não produziu output. Veja: CLAUDE_STATUSLINE_DEBUG=1${N}\n"
fi

printf "\n${C}═══════════════════════════════════════════════════════════════${N}\n"
printf "  ${G}${B}Instalação concluída.${N}\n\n"
printf "  ${B}Próximos passos:${N}\n"
printf "    1. Feche e reabra o Claude Code\n"
printf "    2. Ajustar config: edite %s\n" "$CONFIG_DEST"
printf "    3. Modo debug: export CLAUDE_STATUSLINE_DEBUG=1\n"
printf "    4. Reconfigurar: bash %s/install.sh\n\n" "$REPO_DIR"
printf "  ${B}Desinstalar:${N}\n"
printf "    rm -rf %s\n" "$CONFIG_DIR"
printf "    edite %s e remova a chave 'statusLine'\n" "$SETTINGS"
printf "${C}═══════════════════════════════════════════════════════════════${N}\n\n"
