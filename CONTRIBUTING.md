# Contribuindo com o Chronos AD

Obrigado pelo interesse em melhorar o projeto.

## Antes de mais nada

1. **Abra uma issue antes de um PR grande.** Alinhamento prévio evita retrabalho.
2. **Issues pequenas (typo, fix de doc) podem virar PR direto.**
3. **PT-BR ou EN são bem-vindos** no código, nos commits e na documentação.

## Tipos de contribuição mais úteis

- **Relatos de compatibilidade:** rode o Chronos AD no seu terminal e abra uma issue dizendo qual versão funcionou (ou quebrou). A matriz de compatibilidade do README evolui assim.
- **Bug reports:** sempre inclua a saída de `CLAUDE_STATUSLINE_DEBUG=1` + `uname -a` + nome/versão do terminal + screenshot.
- **Melhorias na detecção de largura:** o cerne técnico do projeto.
- **Localizações novas:** se você usar locale diferente de PT-BR/ES/EN/IT e algo quebrar, abra issue.

## Requisitos técnicos

- Mantenha compatibilidade com **bash 3.2+** (default do macOS) e bash 4+/5+ (Linux).
- Evite features bash-only que não funcionem no `/bin/bash` antigo:
  - ❌ `mapfile` / `readarray`
  - ❌ associative arrays (`declare -A`)
  - ❌ `${var,,}` lower-case (use `tr '[:upper:]' '[:lower:]'`)
- Use `set -euo pipefail` e proteja pipelines com `|| true` quando apropriado.
- Sempre quote variáveis: `"$VAR"`.
- Teste com `bash -n` antes de commitar.

## Estilo de commit

Conventional Commits:

- `feat:` nova funcionalidade
- `fix:` correção de bug
- `docs:` mudança só em documentação
- `style:` formatação, sem mudança de lógica
- `refactor:` mudança de código sem alterar comportamento
- `test:` adição/modificação de testes
- `chore:` task de manutenção, build, etc.

Exemplo:
```
fix: detectar stty -F no Linux além de stty -f (macOS)
```

## Antes de mandar PR

1. Rode o script localmente com diferentes JSONs simulados.
2. Confirme que `bash -n statusline.sh` e `bash -n install.sh` passam.
3. Atualize o CHANGELOG.md em `[Unreleased]` (crie se não existir).
4. Atualize o README se a feature for visível pro usuário.

## Código de conduta

Tratamento respeitoso, debate técnico sobre o trabalho, não sobre a pessoa. Issues com hostilidade serão fechadas sem aviso.

## Licença

Ao contribuir, você concorda que sua contribuição é licenciada sob a [MIT License](LICENSE) — a mesma do projeto.
