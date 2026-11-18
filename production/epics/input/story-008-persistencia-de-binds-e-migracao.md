# Story 008: Arquivo de binds, `.bak` e migração de ação nova

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-006` (persistência atômica), `TR-input-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (com ADR-0013 para o armazém e a gravação atômica)
**ADR Decision Summary**: `user://input_binds.cfg` (ConfigFile, `schema_version = 1`, seções por dispositivo, opção `trocar_analogicos`); ação desconhecida é ignorada, ação ausente recebe o padrão, entrada conhecida inválida torna o arquivo inválido sem mapa parcial; arquivo ruim é preservado byte a byte em `.bak` antes de qualquer substituição.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: MEDIUM
**Engine Notes**: Atomicidade no Windows e falha de gravação são verificação obrigatória do ADR-0013; versão futura não suportada usa padrões em memória e preserva o arquivo sem regravar.

**Control Manifest Rules (this layer)**:
- Required: todo acesso a disco por `ArmazemDeArquivos`; `.cfg` só por `gravar_atomico`; arquivo inválido em `.bak`/`.bak2` sem apagar backup (ADR-0013)
- Forbidden: `FileAccess`/`DirAccess`/`ConfigFile.load/save` fora do `ArmazemUserGodot`; gravar `.cfg` durante um passo em JOGO (ADR-0013)
- Guardrail: avisos `INPUT_*` uma vez por sessão

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-31** Salvar e recarregar → binds iguais; "Restaurar padrão" do gamepad não mexe no teclado; "Trocar analógicos" fica salvo
- [ ] **AC-32** Em pasta temporária: arquivo com lixo → padrões, `INPUT_BINDS_CORROMPIDOS` uma vez por sessão e `.bak` idêntico byte a byte; ação desconhecida → ignorada; ação faltando → recebe o padrão
- [ ] **AC-46** `input_binds.cfg` antigo sem `troca` e com R atribuído ao `especial`: `troca` recebe Tab (primeiro livre), o `especial` mantém R, `INPUT_ACAO_NOVA` aparece uma vez na sessão e `rotulo_acao("troca", teclado)` devolve "Tab"
- [ ] Falha ao preservar o `.bak` impede a sobrescrita, mas a sessão continua com os padrões; falha de gravação vira mensagem própria, sem fingir persistência

---

## Implementation Notes

*Derived from ADR-0006 §6 e ADR-0013:*

Salvar escreve temporário, relê/valida e só então substitui o arquivo válido; se já existir `.bak`, usa nome adicional sem apagá-lo. O repositório de binds usa o `ArmazemDeArquivos` injetado; testes unitários usam `ArmazemEmMemoria` e os testes [I] usam armazém real em raiz temporária, limpa ao fim. Gatilho de gravação só marca pendência; o `Main` grava fora de JOGO. Não serializar `InputEvent`, ids de gamepads conectados nem scripts. O repositório e o armazém são do épico persistencia; aqui entra o formato do arquivo, a validação e a migração.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: regras de remapeamento
- Épico persistencia: `ArmazemDeArquivos`, `gravar_atomico` e o ciclo do `Main`

---

## Files

- `src/foundation/input/repositorio_de_binds.gd`
- `tests/integration/input/binds_persistencia_test.gd`
- `tests/integration/input/binds_corrompidos_test.gd`
- `tests/integration/input/binds_migracao_troca_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/input/binds_persistencia_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/input/story-007-remapeamento-e-rotulos-de-acao.md`; `production/epics/persistencia/` (stories ainda por criar: `ArmazemDeArquivos` e gravação atômica)
- Unlocks: None

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos: `src/foundation/input/repositorio_de_binds.gd` (novo), `tests/integration/input/binds_persistencia_test.gd` (3 casos, armazém real em `user://_testes/…`, limpo ao fim), `tests/integration/input/binds_corrompidos_test.gd` (5 casos), `tests/integration/input/binds_migracao_troca_test.gd` (1 caso). Todos passam (suítes de input: 120 casos, 0 falhas).

Decisões:
- Formato: `[meta] schema_version=1`, `[teclado]`/`[gamepad]` com `chave = [{"tipo","codigo"}]`, `[opcoes] trocar_analogicos`. Só `ConfigFile.parse`/`encode_to_text` em memória; disco só pelo `ArmazemDeArquivos`.
- Arquivo inválido (ilegível, lixo, sem versão, entrada conhecida inválida ou mapa que falha `TransacaoDeRemapeamento.validar`) → padrões, `INPUT_BINDS_CORROMPIDOS` uma vez por instância/sessão e `.bak`/`.bak2`… byte a byte. Falha da cópia → `sem_gravacao()`, `salvar` devolve `ERR_FILE_CANT_WRITE`.
- Versão futura → padrões em memória, arquivo intacto, sem aviso.
- Migração de `troca` (AC-46): segue o GDD (padrão se o primário estiver livre no contexto Jogo; senão o primeiro livre de R, Tab, G, C / LT, D-pad baixo, D-pad esquerda), aviso `INPUT_ACAO_NOVA` uma vez, sem regravar. O ADR-0006 (emenda) diz "sem bind" quando o padrão está ocupado; o GDD é mais específico e foi seguido — divergência a alinhar no ADR.

Pendências:
- Se nenhum candidato estiver livre, a `troca` fica sem bind e a validação recusa o arquivo (vira corrompido): caso não definido no GDD.
- A chave da mensagem de falha de gravação não existe ainda (ADR-0006 §6: "a definir"); `salvar` devolve o `Error` para a UI.
- Ligação no `Main` (carregar na inicialização, salvar fora de JOGO) fora do escopo.
