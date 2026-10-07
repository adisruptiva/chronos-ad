# Changelog

Todas as mudanças notáveis do Chronos AD são documentadas aqui.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento segue [SemVer](https://semver.org/lang/pt-BR/).

## [1.0.0] — 2026-05-14

### Adicionado
- Statusline com bloco direito alinhado à direita: hora primária, hora secundária (opcional), localização, dia da semana, data.
- Detecção automática de largura do terminal via TTY do processo pai (`ps -o tty= -p $PPID` + `stty -f`/`-F`).
- Suporte a macOS (`stty -f`) e Linux (`stty -F`).
- Instalador interativo com 12 perguntas e defaults inteligentes.
- Identidade por diretório opcional via função `identify_cwd()` no config.
- Locale configurável para dia/mês (PT-BR, ES, EN, IT, etc.) com capitalização automática.
- Degradação graciosa em terminais estreitos (<100 cols).
- Margem de segurança de 5 cols pra compensar borda interna do iTerm2 e similares.
- Modo debug opcional via `CLAUDE_STATUSLINE_DEBUG=1` → log em `/tmp/chronos-ad-debug.log`.
- Backup automático de `settings.json` antes de alterar.
- Compatibilidade com config legacy em `~/.config/claude-statusline/`.

### Conhecido
- Não testado em macOS Terminal.app, Warp, Ghostty, Kitty.
- Não testado em Linux (GNOME Terminal, Konsole, xterm).
- Incompatível com Windows PowerShell nativo (use WSL2).
