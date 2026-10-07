#!/usr/bin/env bash
# Exemplo de configuração para claude-code-statusline.
#
# COMO USAR:
#   1. Copie este arquivo para ~/.config/claude-statusline/config.sh
#      mkdir -p ~/.config/claude-statusline
#      cp config.example.sh ~/.config/claude-statusline/config.sh
#   2. Edite os valores abaixo de acordo com suas preferências.
#   3. Não precisa reiniciar nada — a próxima interação no Claude Code já usa.
#
# Tudo abaixo é opcional. Se você não definir, defaults sensatos são usados.

# Tier do seu plano Claude (aparece antes do nome do modelo).
# Exemplos: "Max 20x", "Pro", "Team". Deixe vazio para omitir.
TIER=""

# Fuso primário (formato IANA: America/Sao_Paulo, Europe/Madrid, etc.)
# Se vazio, usa o fuso do sistema.
# Para ver a lista: ls /usr/share/zoneinfo/
PRIMARY_TZ=""

# Rótulo curto da hora primária (ex: "BR", "ES", "JP").
# Se vazio, é derivado automaticamente do nome do fuso.
PRIMARY_TZ_LABEL=""

# Fuso secundário (opcional). Útil se você trabalha entre dois países.
# Exemplos: "Europe/Rome", "America/New_York", "Asia/Tokyo".
# Vazio = não mostra hora secundária.
SECONDARY_TZ=""

# Rótulo curto da hora secundária (ex: "IT", "NY", "JP").
SECONDARY_TZ_LABEL=""

# Cidade/região que aparece no ícone 📍 (ex: "Lisboa/PT", "São Paulo/SP/BR").
# Se vazio, deriva do PRIMARY_TZ ou do fuso do sistema.
LOCATION=""

# Mostra linha 2 direita (dia da semana + data)? 1 = sim, 0 = não.
SHOW_DATE=1

# Cols de respiro antes da parede direita do terminal.
# Aumente se ainda vir corte no canto direito (ex: split panes, scrollbars).
MARGIN_RIGHT=5

# Locale para nome do dia/mês na linha 2 direita.
# Exemplos: "pt_BR.UTF-8", "es_ES.UTF-8", "en_US.UTF-8", "it_IT.UTF-8".
# Verifique disponíveis: locale -a
LANG_TIME="pt_BR.UTF-8"

# Em terminais mais estreitos que isso, o bloco direito é omitido
# (evita quebra de linha feia).
MIN_COLS_FOR_RIGHT_BLOCK=100

# Cor ANSI 256 da identidade (linha 1 esquerda + tier/modelo na linha 2).
# Tabela: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
# Exemplos: 250 (cinza), 39 (azul), 208 (laranja), 220 (âmbar), 99 (roxo)
IDENTITY_COLOR=250

# ─────────────────────────────────────────────────────────────────────────────
# MÓDULOS OPCIONAIS (desligados por padrão)
# ─────────────────────────────────────────────────────────────────────────────

# Identificação da janela na linha 1 (ex: "📂 projeto · ⧉ w1t2 · a1b2c3d4").
# Útil quando várias janelas do Claude Code trabalham juntas. 1 = mostra.
SHOW_WINDOW_ID=0

# Partes da identificação, na ordem em que aparecem:
#   pos  posição da aba no iTerm2 (w1t2); fora do iTerm2, o TTY
#   tty  terminal do sistema (ttys012 no macOS, pts/3 no Linux)
#   pid  PID do shell de login da aba (macOS)
#   sid  início do session_id do Claude Code (8 caracteres)
WINDOW_ID_PARTS="pos sid"

# Sentinela de contexto: a statusline grava o consumo por sessão e o hook
# hooks/sentinela-contexto.sh avisa o Claude uma vez por faixa (70% e 85% de
# contexto, 85% da janela de 5 h, 80% da semana). O instalador registra o hook.
CONTEXT_SENTINEL=0

# ─────────────────────────────────────────────────────────────────────────────
# AVANÇADO: customizar identidade por diretório
#
# Descomente e edite a função abaixo para mostrar emoji + cor diferentes
# dependendo do diretório atual (cwd). Útil para múltiplos projetos.
#
# Protocolo: a função retorna "texto|cor_ansi_256" (separador pipe).
# O texto pode conter espaços. A cor é um número ANSI 256-color.
# ─────────────────────────────────────────────────────────────────────────────
#
# identify_cwd() {
#   local cwd="$1"
#   if echo "$cwd" | grep -qi "MyProject"; then
#     echo "🚀 MyProject|39"
#   elif echo "$cwd" | grep -qi "ClientWork"; then
#     echo "💼 Trabalho Cliente|208"
#   elif echo "$cwd" | grep -qi "Personal"; then
#     echo "🏠 Pessoal|250"
#   else
#     echo "📂 $(basename "$cwd")|$IDENTITY_COLOR"
#   fi
# }
