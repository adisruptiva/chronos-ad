# Chronos AD

> Ancoragem temporal e espacial para o [Claude Code](https://claude.com/claude-code).
> Resolve um problema invisível mas pernicioso: o Claude não tem noção nativa de data, dia da semana, hora local nem fuso horário.

```
🏠 Home                                         🕐 11:30 BR / 16:30 IT · 📍 São Paulo/SP/BR
Max 20x · Opus 4.7 (1M ctx) | Ctx: ██░░░░░░░░░░ 15% | 5h: 8% | 7d: 12%        📅 Quinta-feira · 14/Mai
```

---

## A dor que motivou esta ferramenta

42 dias usando Claude Code intensivamente. Mais de 10 horas por dia. Vibe coding na veia.

Em algum momento, percebi que o Claude marcava reuniões em datas erradas. Confundia "ontem" com "hoje". Achava que era segunda quando era quinta. Em projetos longos onde data e fuso importam — lançamentos, eventos, deadlines, dayparting de campanhas — esses pequenos erros se acumulavam silenciosamente até virar problema sério.

A causa raiz: **o Claude Code, em si, não tem ancoragem temporal nativa**. Ele sabe a data de corte do treinamento. Sabe um pouco de fuso. Mas não enxerga o calendário, não vê o dia da semana, não distingue automaticamente entre seu fuso local e o fuso de quem está do outro lado do mundo.

Para um usuário casual, isso não é problema. Para quem usa o Claude Code como ferramenta de produção, 10h por dia, é um buraco invisível que custa tempo, custa retrabalho e custa confiança.

O **Chronos AD** existe para tapar esse buraco. A solução é simples: **mostrar o tempo o tempo todo, na cara, onde o Claude e você possam ver**.

Não é decoração visual. É infraestrutura de contexto.

---

## O que o Chronos AD faz

Coloca duas linhas alinhadas à direita da statusline do Claude Code:

- **Linha 1:** hora primária `[/` hora secundária `] ·` localização
- **Linha 2:** dia da semana `·` data

E mantém intacto o que já estava do lado esquerdo (identidade do diretório, tier, modelo, contexto, limites de uso).

```
🏠 Home                                                    🕐 11:30 BR · 📍 São Paulo
Max 20x · Opus 4.7 | Ctx: ██░░░░░░░░░░ 15% | 5h: 8% | 7d: 12%        📅 Quinta-feira · 14/Mai
```

Com fuso secundário, útil pra quem trabalha entre dois países (ex: dev BR atendendo cliente IT):

```
🚀 cliente-italia                                  🕐 11:30 BR / 16:30 IT · 📍 São Paulo
Pro · Sonnet 4.6 | Ctx: ██░░░░░░░░░░ 18% | 5h: 12% | 7d: 22%         📅 Quinta-feira · 14/Mai
```

---

## Por que isso importa de verdade

| Antes (sem ancoragem) | Depois (com Chronos AD) |
|------------------------|--------------------------|
| Você diz "amanhã" e o Claude marca pra data errada | Claude vê a data atual, "amanhã" vira `15/Mai` corretamente |
| Reuniões cross-fuso viram bagunça de timezone | Hora dos dois fusos sempre visível |
| Em sessão longa, você perde noção do dia da semana | "Quinta-feira" aparece na barra, sem ambiguidade |
| Erros temporais aparecem só depois, quando algo já foi entregue errado | Você corrige antes de fechar a mensagem |
| Ferramenta passiva | Ferramenta que ancora contexto |

---

## Funcionalidades

- **Hora primária e secundária** alinhadas à direita do terminal
- **Localização customizável** (cidade/região no ícone 📍)
- **Dia da semana + data** em qualquer idioma (PT-BR, ES, EN, IT)
- **Detecção automática da largura do terminal** via TTY do processo pai — funciona mesmo quando o Claude Code não passa a largura no JSON de entrada
- **Instalador interativo** com 12 perguntas (Enter aceita defaults inteligentes)
- **Identidade por diretório** opcional — emoji + cor diferentes por projeto
- **Degradação graciosa** em terminais estreitos
- **Semáforo de contexto** — barra de uso muda de amarelo → laranja → vermelho
- **Modo debug** opcional para diagnosticar problemas
- **100% local, zero telemetria, zero dependência de serviço externo**

---

## Instalação rápida

Pré-requisitos: `bash`, `python3`, `jq`, `awk`, `sed`, `ps`, `stty`.

No macOS, instale `jq` se faltar:
```bash
brew install jq
```

No Ubuntu/Debian:
```bash
sudo apt install jq python3
```

Clone e rode o instalador interativo:
```bash
git clone https://github.com/adisruptiva/chronos-ad.git
cd chronos-ad
bash install.sh
```

O instalador faz 12 perguntas (fuso, localização, idioma da data, cor, etc.) com defaults inteligentes — Enter aceita o default. Tudo é gravado em `~/.config/chronos-ad/config.sh` e fica editável depois.

Ao fim, ele atualiza `~/.claude/settings.json` para apontar pra Chronos AD (preserva backup do que estava antes). Feche e reabra o Claude Code e pronto.

---

## Compatibilidade

| Plataforma / Terminal     | Status                | Notas                                                  |
|---------------------------|----------------------|---------------------------------------------------------|
| macOS · iTerm2            | ✅ Testado            | Plataforma de desenvolvimento. Recomendado.            |
| macOS · Terminal.app      | ⚠️ Não testado        | Deve funcionar, mas emojis em macOS pré-Big Sur podem desalinhar |
| macOS · Warp              | ⚠️ Não testado        | ANSI 256-color total, alta probabilidade de funcionar  |
| macOS · Ghostty / Kitty   | ⚠️ Não testado        | Terminais modernos com GPU, alta probabilidade         |
| Linux · GNOME Terminal    | ⚠️ Não testado        | Bug `stty -F` (Linux) vs `-f` (macOS) corrigido        |
| Linux · Konsole / xterm   | ⚠️ Não testado        | Dependente de fonte com suporte a emoji                |
| Windows · WSL2            | ⚠️ Não testado        | Deve funcionar (é Linux por baixo)                     |
| Windows · PowerShell nativo | ❌ Incompatível      | Script é bash. Pode ser portado no futuro.             |

Quem instalar e testar em terminais ainda não validados — por favor abra uma issue dizendo o que viu. Cada relato ajuda a evoluir a matriz acima.

---

## Customização avançada

O arquivo `~/.config/chronos-ad/config.sh` aceita estas variáveis:

| Variável                    | O que faz                                       | Exemplo               |
|-----------------------------|--------------------------------------------------|------------------------|
| `TIER`                      | Texto antes do nome do modelo                   | `"Max 20x"`           |
| `PRIMARY_TZ`                | Fuso primário (IANA)                            | `"America/Sao_Paulo"` |
| `PRIMARY_TZ_LABEL`          | Rótulo curto do fuso primário                   | `"BR"`                |
| `SECONDARY_TZ`              | Fuso secundário                                  | `"Europe/Rome"`       |
| `SECONDARY_TZ_LABEL`        | Rótulo curto do fuso secundário                 | `"IT"`                |
| `LOCATION`                  | Cidade que aparece no 📍                         | `"São Paulo/SP"`      |
| `SHOW_DATE`                 | Mostra linha 2 direita?                          | `1` ou `0`            |
| `SHOW_EMOJIS`               | Usa emojis?                                      | `1` ou `0`            |
| `MARGIN_RIGHT`              | Cols de respiro antes da parede direita         | `5`                   |
| `LANG_TIME`                 | Locale para nome do dia/mês                      | `"pt_BR.UTF-8"`       |
| `IDENTITY_COLOR`            | Cor ANSI 256 da identidade                       | `250`                 |
| `MIN_COLS_FOR_RIGHT_BLOCK`  | Abaixo disso, omite bloco direito               | `100`                 |

Para identidade diferente por diretório (emoji + cor por projeto), descomente a função `identify_cwd()` no `config.sh` e edite os padrões:

```bash
identify_cwd() {
  local cwd="$1"
  if echo "$cwd" | grep -qi "MyProject"; then
    echo "🚀 MyProject|39"
  elif echo "$cwd" | grep -qi "ClientWork"; then
    echo "💼 Trabalho Cliente|208"
  else
    echo "📂 $(basename "$cwd")|$IDENTITY_COLOR"
  fi
}
```

Protocolo: a função retorna `"texto|cor_ansi_256"` (separador pipe). Tabela de cores ANSI 256: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

---

## Problemas comuns e soluções

### A statusline não aparece

1. Confirme o caminho do script em `~/.claude/settings.json`:
   ```bash
   jq '.statusLine' ~/.claude/settings.json
   ```
2. Confirme que o script é executável:
   ```bash
   chmod +x ~/.config/chronos-ad/statusline.sh
   ```
3. Teste manualmente:
   ```bash
   echo '{"cwd":"/tmp","model":{"display_name":"Opus 4.7"}}' | bash ~/.config/chronos-ad/statusline.sh
   ```
4. Ative debug:
   ```bash
   export CLAUDE_STATUSLINE_DEBUG=1
   # rode qualquer comando no Claude Code, depois:
   cat /tmp/chronos-ad-debug.log
   ```

### O bloco direito aparece cortado

Sua janela do terminal tem padding interno que faz o `stty` reportar mais cols do que de fato renderiza. Aumente `MARGIN_RIGHT` no `config.sh`:

```bash
MARGIN_RIGHT=8   # tenta 8, 10, 12 até resolver
```

### O dia da semana aparece em inglês

Seu locale (ex: `pt_BR.UTF-8`) não está instalado.

Verifique:
```bash
locale -a | grep -i pt_br
```

Instale (Ubuntu/Debian):
```bash
sudo locale-gen pt_BR.UTF-8
sudo update-locale
```

No macOS, locales `pt_BR`, `es_ES`, `it_IT`, `en_US` já vêm instalados por padrão.

### Quero voltar para a statusline padrão

```bash
# Remove a chave statusLine do settings (usando jq)
tmp=$(mktemp) && jq 'del(.statusLine)' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
# Opcional: remover instalação
rm -rf ~/.config/chronos-ad
```

Feche e reabra o Claude Code.

---

## Limitações conhecidas

- **Performance:** cada render do statusline gasta ~30–50 ms (Python startup + subprocess). Imperceptível em uso normal, mas em hardware muito antigo ou sob carga extrema pode aparecer.
- **Emojis em terminais antigos:** terminais pré-2020 podem renderizar emojis como 1 coluna em vez de 2, causando desalinhamento visual. Solução: use fonte com suporte a emoji (Fira Code, JetBrains Mono, MesloLGS NF) ou desligue emojis no `config.sh` (`SHOW_EMOJIS=0`).
- **Fuso de viagem:** se você viaja com frequência e quer override temporário do fuso primário, hoje é manual (editar `config.sh`). Suporte automático está no roadmap.
- **Windows PowerShell nativo:** incompatível. Use WSL2 ou aguarde versão portada.

---

## Como funciona por dentro (técnico)

O Claude Code invoca o statusline em um subprocesso sem TTY anexado e sem passar a largura do terminal no JSON de input. Para descobrir a largura real, o Chronos AD usa esta cadeia de fallbacks:

1. `$COLUMNS` (raramente disponível em subprocess)
2. **TTY do processo pai:** `ps -o tty= -p $PPID` → `stty -f /dev/ttysNNN size` (macOS) ou `stty -F` (Linux)
3. `stty size` direto (caso rode interativo)
4. Fallback `120` cols

O alinhamento à direita é calculado em Python para contar corretamente a largura visual de strings com:
- escapes ANSI (cores) — strip via regex
- emojis (double-width em terminais modernos) — detecção via `unicodedata`
- caracteres East Asian Wide

A margem de 5 colunas existe porque o iTerm2 (e similares) reportam a largura da janela inteira via `stty`, mas a área renderizável é ~3-5 colunas menor por padding interno.

A capitalização do dia/mês usa Python pós-locale (`locale -a` retorna `quinta-feira`/`mai` minúsculos; queremos `Quinta-feira`/`Mai`).

---

## Roadmap

- [x] v1.0.0 — primeira release pública (Mai/2026)
- [ ] v1.1 — versão em inglês do README + i18n
- [ ] v1.2 — suporte a fuso de viagem com expiração automática
- [ ] v1.3 — testes automatizados (bats) + CI no GitHub Actions
- [ ] v1.4 — matriz de compatibilidade testada em ≥5 terminais
- [ ] v2.0 — porta para Windows PowerShell nativo

Sugestões e contribuições via issues e PRs.

---

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md). Resumo:

1. Issue antes de PR (alinhamento prévio evita retrabalho)
2. Mantém compatibilidade com bash 3.2+ (default do macOS) e bash 4+/5+ (Linux)
3. PT-BR ou EN são bem-vindos no código e na doc
4. Commits no formato Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)

---

## Origem e créditos

**Origem:** descoberta na [ADisruptiva](https://adisruptiva.com), após 42 dias de uso intenso do Claude Code durante a construção do ecossistema da empresa.

**Conceito:** ancoragem temporal como infraestrutura, não decoração.

**Engenharia:** parceria com Claude (Anthropic), iterando descobertas técnicas em sessão:
- Detecção de largura via TTY do processo pai (`ps -o tty= -p $PPID + stty -f`)
- Margem de segurança de 5 cols (compensa borda interna do iTerm2)
- Diferença `stty -f` (macOS) vs `stty -F` (Linux)

**Licença:** [MIT](LICENSE). Use, modifique, distribua — só preserve a atribuição original.

**Onde encontrar:**
- ADisruptiva — https://adisruptiva.com
- Issues, contribuições — neste repositório

Se o Chronos AD te ajudou, considere:
1. Deixar uma ⭐ no repositório
2. Abrir uma issue contando qual terminal você usa (ajuda a evoluir a matriz de compatibilidade)
3. Compartilhar com outros usuários intensivos do Claude Code

---

*Chronos AD · uma ferramenta pequena pra um problema invisível.*
