#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Chronos AD · ancoragem temporal e espacial para o Claude Code
#  Versão: 1.0.0
#  by ADisruptiva — https://github.com/adisruptiva/chronos-ad
#  Licença: MIT
# ───────────────────────────────────────────────────────────────────────────────
#  Mostra na statusline do Claude Code:
#    Linha 1 esquerda: identidade do diretório atual
#    Linha 1 direita:  hora primária [+ secundária] · localização
#    Linha 2 esquerda: tier · modelo · contexto · 5h · 7d
#    Linha 2 direita:  dia da semana · data
#
#  Configuração: ~/.config/chronos-ad/config.sh (opcional, defaults sensatos)
#  Debug:        export CLAUDE_STATUSLINE_DEBUG=1 → /tmp/chronos-ad-debug.log
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail
export LC_NUMERIC=C

# Modo debug opcional · não afeta output visual
DEBUG_LOG=""
if [[ "${CLAUDE_STATUSLINE_DEBUG:-0}" == "1" ]]; then
  DEBUG_LOG="/tmp/chronos-ad-debug.log"
fi
_debug() {
  [[ -n "$DEBUG_LOG" ]] && echo "[$(date '+%H:%M:%S')] $*" >> "$DEBUG_LOG" 2>/dev/null || true
}

# ── Carrega configuração externa (se existir) ─────────────────────────────────
# Procura em ordem: env override → ~/.config/chronos-ad/ → ~/.config/claude-statusline/ (legacy)
CONFIG_FILE="${CLAUDE_STATUSLINE_CONFIG:-}"
if [[ -z "$CONFIG_FILE" ]]; then
  if [[ -f "$HOME/.config/chronos-ad/config.sh" ]]; then
    CONFIG_FILE="$HOME/.config/chronos-ad/config.sh"
  elif [[ -f "$HOME/.config/claude-statusline/config.sh" ]]; then
    CONFIG_FILE="$HOME/.config/claude-statusline/config.sh"
  fi
fi
if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
  _debug "loading config: $CONFIG_FILE"
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# ── Defaults (sobrescritos pelo config.sh) ────────────────────────────────────
: "${TIER:=}"                                 # ex: "Max 20x" · vazio omite
: "${PRIMARY_TZ:=}"                           # vazio = TZ do sistema
: "${SECONDARY_TZ:=}"                         # vazio = não mostra hora secundária
: "${SECONDARY_TZ_LABEL:=}"                   # ex: "IT" · vazio = derivado do TZ
: "${LOCATION:=}"                             # ex: "São Paulo/SP/BR" · vazio = derivado
: "${SHOW_DATE:=1}"                           # 1 = mostra linha 2 direita · 0 = omite
: "${MARGIN_RIGHT:=5}"                        # cols de respiro antes da parede direita
: "${LANG_TIME:=pt_BR.UTF-8}"                 # locale para formatação de data
: "${MIN_COLS_FOR_RIGHT_BLOCK:=100}"          # abaixo disso, omite bloco direito
: "${IDENTITY_COLOR:=250}"                    # ANSI 256-color default

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
model_raw=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Identidade do diretório atual ─────────────────────────────────────────────
# A função identify_cwd pode ser sobrescrita no config.sh para mapear diretórios
# específicos para emoji + cor customizados. Protocolo: retorna "texto|cor_ansi".
# Default: nome da pasta atual.
if declare -f identify_cwd >/dev/null 2>&1; then
  cwd_out=$(identify_cwd "$cwd")
  identity_text="${cwd_out%|*}"
  identity_color="${cwd_out##*|}"
  # Se não tinha separador (formato antigo), usa default color
  if [[ "$identity_text" == "$identity_color" ]]; then
    identity_color="$IDENTITY_COLOR"
  fi
else
  identity_text="📂 $(basename "$cwd")"
  identity_color="$IDENTITY_COLOR"
fi

reset='\033[0m'
dim='\033[2m'
term_color="\033[38;5;${identity_color}m"
identity=$(printf '%b%s%b' "$term_color" "$identity_text" "$reset")

# ── Encurtar nome do modelo ───────────────────────────────────────────────────
shorten_model() {
  local name="$1"
  local short
  short=$(echo "$name" | sed 's/^[Cc]laude[[:space:]]*//' | sed 's/[[:space:]]*[0-9]\{8\}$//')
  echo "$short"
}
model_label=$(shorten_model "$model_raw")

# ── Barra visual ──────────────────────────────────────────────────────────────
make_bar() {
  local pct="$1"
  local filled
  filled=$(printf '%.0f' "$(echo "$pct * 12 / 100" | bc -l 2>/dev/null || echo 0)")
  local empty=$((12 - filled))
  local bar=""
  local i
  for i in $(seq 1 "$filled"); do bar="${bar}█"; done
  for i in $(seq 1 "$empty");  do bar="${bar}░"; done
  echo "$bar"
}

# ── Semáforo Ctx ──────────────────────────────────────────────────────────────
ctx_color_for() {
  local pct_int="$1"
  if [[ "$pct_int" -gt 90 ]]; then
    printf '\033[0;31m'
  elif [[ "$pct_int" -gt 70 ]]; then
    printf '\033[38;5;208m'
  else
    printf '\033[0;33m'
  fi
}

# ── Construção da linha 2 ─────────────────────────────────────────────────────
parts=()

if [[ -n "$TIER" ]]; then
  parts+=("$(printf '%b%s · %s%b' "$term_color" "$TIER" "$model_label" "$reset")")
else
  parts+=("$(printf '%b%s%b' "$term_color" "$model_label" "$reset")")
fi

if [[ -n "$used_pct" ]]; then
  bar=$(make_bar "$used_pct")
  used_fmt=$(printf '%.0f' "$used_pct")
  ctx_clr=$(ctx_color_for "$used_fmt")
  parts+=("$(printf 'Ctx: %b%s%b %b%s%%%b' "$ctx_clr" "$bar" "$reset" "$dim" "$used_fmt" "$reset")")
fi

if [[ -n "$five_pct" ]]; then
  five_fmt=$(printf '%.0f' "$five_pct")
  parts+=("$(printf '5h: \033[0;35m%s%%\033[0m' "$five_fmt")")
fi

if [[ -n "$week_pct" ]]; then
  week_fmt=$(printf '%.0f' "$week_pct")
  parts+=("$(printf '7d: \033[0;35m%s%%\033[0m' "$week_fmt")")
fi

line2=""
for part in "${parts[@]}"; do
  if [[ -z "$line2" ]]; then
    line2="$part"
  else
    line2="$line2 $(printf '%b|%b' "$dim" "$reset") $part"
  fi
done

# ── Bloco direito (hora + local + data) ───────────────────────────────────────
# Detecção de largura · cadeia de fallbacks robusta
term_cols="${COLUMNS:-}"
case "$term_cols" in
  ''|*[!0-9]*) term_cols="" ;;
esac

# Fallback chave: ler largura do TTY do processo pai (Claude Code)
# Funciona quando o statusline é invocado sem TTY anexado diretamente.
# IMPORTANTE: macOS usa `stty -f`, Linux usa `stty -F`. Tenta ambos.
if [[ -z "$term_cols" ]]; then
  parent_tty=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ' || true)
  _debug "parent_tty=$parent_tty"
  if [[ -n "$parent_tty" && "$parent_tty" != "?"* && -e "/dev/$parent_tty" ]]; then
    # Detecta flag correta de acordo com o OS
    if [[ "$(uname -s)" == "Darwin" ]]; then
      stty_flag="-f"
    else
      stty_flag="-F"
    fi
    term_cols=$( { stty "$stty_flag" "/dev/$parent_tty" size 2>/dev/null || echo ""; } | awk '{print $2}' || true)
    case "$term_cols" in
      ''|*[!0-9]*) term_cols="" ;;
    esac
    _debug "term_cols via parent_tty (stty $stty_flag): $term_cols"
  fi
fi

# Fallback: stty direto (caso rode com TTY anexado)
if [[ -z "$term_cols" ]]; then
  term_cols=$( { stty size 2>/dev/null || echo ""; } | awk '{print $2}' || true)
  case "$term_cols" in
    ''|*[!0-9]*) term_cols="" ;;
  esac
fi

# Fallback final: padrão seguro
if [[ -z "$term_cols" ]] || [[ "$term_cols" -lt 1 ]]; then
  term_cols=120
fi

right_line1=""
right_line2=""

if [[ "$term_cols" -ge "$MIN_COLS_FOR_RIGHT_BLOCK" ]]; then
  # Hora primária
  if [[ -n "$PRIMARY_TZ" ]]; then
    PRIMARY_T=$(TZ="$PRIMARY_TZ" date '+%H:%M' 2>/dev/null || echo "")
    PRIMARY_LABEL="${PRIMARY_TZ_LABEL:-$(echo "$PRIMARY_TZ" | awk -F/ '{print $NF}' | cut -c1-2 | tr 'a-z' 'A-Z')}"
  else
    PRIMARY_T=$(date '+%H:%M' 2>/dev/null || echo "")
    PRIMARY_LABEL=""
  fi

  # Localização (deriva do PRIMARY_TZ se não definida)
  if [[ -z "$LOCATION" ]]; then
    if [[ -n "$PRIMARY_TZ" ]]; then
      LOCATION=$(echo "$PRIMARY_TZ" | awk -F/ '{print $NF}' | tr '_' ' ')
    else
      SYS_TZ=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
      LOCATION=$(echo "$SYS_TZ" | awk -F/ '{print $NF}' | tr '_' ' ')
    fi
  fi

  # Hora secundária (opcional)
  if [[ -n "$SECONDARY_TZ" ]]; then
    SEC_T=$(TZ="$SECONDARY_TZ" date '+%H:%M' 2>/dev/null || echo "")
    SEC_LABEL="${SECONDARY_TZ_LABEL:-$(echo "$SECONDARY_TZ" | awk -F/ '{print $NF}' | cut -c1-2 | tr 'a-z' 'A-Z')}"
  fi

  # Monta linha 1 direita
  if [[ -n "${SEC_T:-}" ]]; then
    if [[ -n "$PRIMARY_LABEL" ]]; then
      right_line1=$(printf '\033[38;5;244m🕐 %s %s / %s %s · 📍 %s\033[0m' "$PRIMARY_T" "$PRIMARY_LABEL" "$SEC_T" "$SEC_LABEL" "$LOCATION")
    else
      right_line1=$(printf '\033[38;5;244m🕐 %s / %s %s · 📍 %s\033[0m' "$PRIMARY_T" "$SEC_T" "$SEC_LABEL" "$LOCATION")
    fi
  else
    if [[ -n "$PRIMARY_LABEL" ]]; then
      right_line1=$(printf '\033[38;5;244m🕐 %s %s · 📍 %s\033[0m' "$PRIMARY_T" "$PRIMARY_LABEL" "$LOCATION")
    else
      right_line1=$(printf '\033[38;5;244m🕐 %s · 📍 %s\033[0m' "$PRIMARY_T" "$LOCATION")
    fi
  fi

  # Linha 2 direita: dia da semana + data
  if [[ "$SHOW_DATE" == "1" ]]; then
    if [[ -n "$PRIMARY_TZ" ]]; then
      WEEKDAY=$(LC_TIME="$LANG_TIME" TZ="$PRIMARY_TZ" date '+%A' 2>/dev/null || echo "")
      DAY_MONTH=$(LC_TIME="$LANG_TIME" TZ="$PRIMARY_TZ" date '+%d/%b' 2>/dev/null || echo "")
    else
      WEEKDAY=$(LC_TIME="$LANG_TIME" date '+%A' 2>/dev/null || echo "")
      DAY_MONTH=$(LC_TIME="$LANG_TIME" date '+%d/%b' 2>/dev/null || echo "")
    fi
    if [[ -n "$WEEKDAY" && -n "$DAY_MONTH" ]]; then
      DATE_CAP=$(python3 -c "
import sys
w, dm = sys.argv[1], sys.argv[2]
w = w[:1].upper() + w[1:]
parts = dm.split('/')
if len(parts) == 2:
    parts[1] = parts[1][:1].upper() + parts[1][1:]
    dm = '/'.join(parts)
print(f'{w} · {dm}')
" "$WEEKDAY" "$DAY_MONTH" 2>/dev/null || echo "$WEEKDAY · $DAY_MONTH")
      right_line2=$(printf '\033[38;5;244m📅 %s\033[0m' "$DATE_CAP")
    fi
  fi
fi

# ── Output (com padding pra alinhamento à direita via Python) ─────────────────
export SL_IDENTITY="$identity"
export SL_LINE2="$line2"
export SL_RIGHT1="$right_line1"
export SL_RIGHT2="$right_line2"
export SL_COLS="$term_cols"
export SL_MARGIN="$MARGIN_RIGHT"

python3 <<'PYEOF'
import os, re, unicodedata

identity = os.environ.get('SL_IDENTITY', '')
line2    = os.environ.get('SL_LINE2', '')
right1   = os.environ.get('SL_RIGHT1', '')
right2   = os.environ.get('SL_RIGHT2', '')
cols     = int(os.environ.get('SL_COLS', '120') or '120')
margin   = int(os.environ.get('SL_MARGIN', '5') or '5')

def vw(s: str) -> int:
    """Largura visual de string com ANSI escapes e emojis."""
    s = re.sub(r'\x1b\[[0-9;]*m', '', s)
    w = 0
    for c in s:
        cp = ord(c)
        if cp in (0xFE0F, 0x200D):
            continue
        if unicodedata.east_asian_width(c) in ('F', 'W'):
            w += 2
        elif cp >= 0x1F000:
            w += 2
        elif unicodedata.category(c) == 'Mn':
            pass
        else:
            w += 1
    return w

def pad_right(left: str, right: str) -> str:
    if not right:
        return left
    space = cols - vw(left) - vw(right) - margin
    if space < 1:
        return left
    return left + (' ' * space) + right

l1 = pad_right(identity, right1)
l2 = pad_right(line2, right2)
print(l1)
print(l2, end='')
PYEOF
