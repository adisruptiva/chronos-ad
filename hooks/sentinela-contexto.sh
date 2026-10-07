#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Chronos AD · sentinela de contexto (hook UserPromptSubmit, opcional)
#  Versão: 1.1.0
#  by ADisruptiva — https://github.com/adisruptiva/chronos-ad
#  Licença: MIT
# ───────────────────────────────────────────────────────────────────────────────
#  Avisa o Claude UMA vez por faixa, por sessão:
#    contexto ≥ 70% · contexto > 85% · janela de 5 horas > 85% · semana > 80%
#  Fora dessas faixas, não diz nada: silêncio é o estado normal.
#
#  Lê o que a statusline grava quando CONTEXT_SENTINEL=1 no config.sh, em
#  ~/.config/chronos-ad/state/ctx/<session_id>.json.
#
#  Contrato: sai sempre com 0. Qualquer falha interna = silêncio, nunca bloqueio.
#  Sem `set -e` de propósito: o contrato exige tolerância a falha.
# ═══════════════════════════════════════════════════════════════════════════════

# Locale com vírgula decimal quebra aritmética com "75.4"; o corte abaixo não
# depende de locale, mas o resto do script fica previsível assim.
export LC_NUMERIC=C

STATE_DIR="$HOME/.config/chronos-ad/state/ctx"

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9_-')
[[ -n "$session_id" ]] || exit 0

STATE="$STATE_DIR/${session_id}.json"
[[ -f "$STATE" ]] || exit 0

# Frescor: dado com mais de 2 h é de outro momento da sessão, então silêncio.
if [[ "$(uname -s)" == "Darwin" ]]; then
  mtime=$(stat -f %m "$STATE" 2>/dev/null) || exit 0
else
  mtime=$(stat -c %Y "$STATE" 2>/dev/null) || exit 0
fi
now=$(date +%s)
(( now - mtime <= 7200 )) || exit 0

ctx=$(jq -r '.ctx // empty' "$STATE" 2>/dev/null)
five=$(jq -r '.five_hour // empty' "$STATE" 2>/dev/null)
week=$(jq -r '.seven_day // empty' "$STATE" 2>/dev/null)

# Inteiro por corte de texto ("79.3" → 79); vazio ou null → -1, que não dispara.
to_int() {
  local v="${1%%.*}"
  case "$v" in
    ''|null|*[!0-9]*) echo "-1" ;;
    *) echo "$v" ;;
  esac
}
ctx_i=$(to_int "$ctx"); five_i=$(to_int "$five"); week_i=$(to_int "$week")

MARK="$STATE_DIR/avisos-${session_id}"
ja_avisado() { grep -qx "$1" "$MARK" 2>/dev/null; }
marca() { echo "$1" >> "$MARK" 2>/dev/null || true; }

msgs=()

# Contexto: a faixa alta tem precedência; disparada a alta, a baixa não fala mais.
if (( ctx_i > 85 )); then
  if ! ja_avisado ctx85; then
    msgs+=("Contexto acima de 85%. Registre agora o estado do trabalho (o que foi feito, o que falta), antes que a compactação automática decida por você.")
    marca ctx85; marca ctx70
  fi
elif (( ctx_i >= 70 )); then
  if ! ja_avisado ctx70; then
    msgs+=("Contexto acima de 70%. Evite começar leitura longa; se for necessária, delegue a um subagente.")
    marca ctx70
  fi
fi

# Limites de uso: mesma régua, gatilhos próprios.
if (( week_i > 80 )) && ! ja_avisado wk80; then
  msgs+=("Limite semanal acima de 80%. Considere um modelo mais leve para tarefas simples.")
  marca wk80
fi
if (( five_i > 85 )) && ! ja_avisado fh85; then
  msgs+=("Janela de 5 horas acima de 85%. Trabalho pesado pode ser interrompido.")
  marca fh85
fi

(( ${#msgs[@]} > 0 )) || exit 0

echo "## ⏳ Chronos AD · sentinela de contexto"
for m in "${msgs[@]}"; do
  echo "- $m"
done
echo "_Aviso único por faixa nesta sessão._"
exit 0
