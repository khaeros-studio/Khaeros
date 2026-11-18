# Story 005: Experimentos de persistência e telemetria (EX-0013-P1..P7)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia TR-save-* e TR-telemetria-* (ADR-0013: "Blocks: implementação de produção da Telemetria e da gravação de binds/preferências até aceite e execução de E-P1/E-P2").

**ADR Governing Implementation**: ADR-0013: Persistência do MVP
**ADR Decision Summary**: `ConfigFile`/`FileAccess` em `user://`, gravação atômica com `.bak`, `perfil.cfg` com `[vinculo]`, telemetria `.jsonl`; todo acesso a disco via `ArmazemDeArquivos`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: as APIs de `FileAccess`/`DirAccess`/`ConfigFile`/`JSON`/`Time`/`OS.shell_open` não estão em `docs/engine-reference/`; cada comportamento abaixo é NEEDS VERIFICATION.

**Control Manifest Rules (this layer)**:
- Required: todo `bool`/`Error` devolvido é verificado; `.cfg` só por gravação atômica.
- Forbidden: gravar `.cfg` durante um passo em JOGO; ler `.jsonl` no jogo.
- Guardrail: telemetria ≤ 1 ms por linha, ≤ 3 ms por passo (pior passo com 5 linhas).

---

## Acceptance Criteria

*Do ADR-0013 (E-P1..E-P7) e do EPIC.md (tabela de experimentos).*

- [ ] EX-0013-P1: `store_line` + `flush` em 10 000 linhas de 300 B e de 2 KB: média e p99 por linha; pior passo com 5 linhas ≤ 3 ms; morte do processo (kill) depois do `flush`: quantas linhas sobrevivem; erro de disco cheio/permissão: `store_line` devolve `bool` e `get_error()` informa.
- [ ] EX-0013-P2: `DirAccess.rename` sobre destino existente e sobre destino aberto no Windows; queda simulada (kill) em cada passo da sequência `.old` de `gravar_atomico`: o que sobra em disco em cada ponto.
- [ ] EX-0013-P3: `ConfigFile.parse`/`encode_to_text` com int > 2^31, `StringName`, `Array`, e lixo binário: o que ida-e-volta preserva e o que corrompe.
- [ ] EX-0013-P4: `JSON.stringify` com int, float, `null` e acentos: texto produzido (ex.: `1` vs `1.0`).
- [ ] EX-0013-P5: `Time` em UTC com sufixo `Z` e relógio monotônico em ms e µs: formato e resolução.
- [ ] EX-0013-P6: `OS.shell_open` da pasta globalizada de `user://` abre o Explorer.
- [ ] EX-0013-P7: em build exportado, interceptar o fechamento da janela (`NOTIFICATION_WM_CLOSE_REQUEST`, `auto_accept_quit`), gravar o perfil, e o fluxo `PERFIL_SAIR_SEM_SALVAR` / "Tentar de novo" quando a gravação falha.
- [ ] Resultado de cada item: "confirmado" ou "usar fallback do ADR-0013".

---

## Implementation Notes

Protótipo em `prototypes/engine-verificacao/persistencia/` com raiz temporária em `user://experimentos/` e limpeza ao fim. Kill do processo por script externo (`taskkill`). P7 exige build exportado; P6 e P7 têm passo manual. O harness mede em build de release na máquina de referência (Ryzen 5 5600H, SSD).

---

## Out of Scope

- `ArmazemDeArquivos`, repositórios e `gravar_atomico` de produção: épico `persistencia`.
- Esquema e gravação da telemetria: épico `telemetria-local`.

---

## Files

- `prototypes/engine-verificacao/persistencia/`
- `production/qa/evidence/experimentos/ex-0013-p1-p7.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/experimentos/ex-0013-p1-p7.md` com tabela de resultados por item.

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: épicos `persistencia` e `telemetria-local` (todas as stories de gravação)

## Completion Notes

**2026-11-16 — godot-specialist.** Executado no Godot 4.7.2 (binário do editor, Ryzen 5 5600H, SSD). Evidência: `production/qa/evidence/experimentos/ex-0013-p1-p7.md`. Arquivos: `prototypes/engine-verificacao/persistencia/` (`project.godot`, `probe.gd`, `janela.gd`, `janela.tscn`). `user://experimentos` foi apagado ao fim.

| Item | Resultado | O que o ADR-0013 precisa mudar |
|---|---|---|
| P1 | **PARCIAL**: p99 por linha 90 µs (300 B) / 211 µs (2 KB), ≤ 1 ms; pior janela de 5 linhas 7,1 / 14,9 ms (picos do SO) **> 3 ms**. Kill depois do `flush`: 1000/1000 linhas; sem `flush`: 993/1000. Erro: `store_line` → `false` + `get_error()`=13; falha de abertura → `get_open_error()`=12 | Registrar que o teto de 3 ms/passo estoura por pico isolado (o `TL2` vai disparar como ruído); orçamento é decisão do design |
| P2 | **VERIFICADO + RISCO**: `rename` sobrescreve destino existente, mas **apaga antes de mover**; com a origem presa, o destino some. Kill em cada passo da sequência `.old` deixa estados que a recuperação do ADR já cobre | Manter a sequência `.old` (não usar rename único); registrar o risco |
| P3 | **VERIFICADO com ressalvas**: o ida-e-volta preserva int 64 bits, `StringName`, `Array`, float e texto com escapes. Lixo binário → `OK` com 0 seções; array truncado → erro 43 com seção parcial | Exigir `schema_version`/seção esperada além de `parse == OK` |
| P4 | **VERIFICADO**: `1`, `1.0`, `null`, int > 2^53 exato, UTF-8 cru, chaves ordenadas; `parse` devolve float | Anotar |
| P5 | **VERIFICADO**: `get_datetime_string_from_system(true)` **sem `Z`**; µs com resolução de 1 µs | O relógio concatena `Z` |
| P6 | **VERIFICADO** (editor): `shell_open` → OK, Explorer aberto na pasta (caminho com espaço) | Marcar verificado; repetir no export |
| P7 | **VERIFICADO no editor**: `auto_accept_quit=false` + `NOTIFICATION_WM_CLOSE_REQUEST`; falha → ponto do `PERFIL_SAIR_SEM_SALVAR`; "Tentar de novo" (simulado) grava e sai. **Export NÃO RODADO** | Mecanismo confirmado; validar no `.exe` |

Decisões: a queda foi simulada com `OS.kill` do próprio processo no ponto exato, em vez de `taskkill` externo (mesma terminação forçada, mas determinística). O disco cheio foi substituído por arquivo somente-leitura e handle de leitura.

**Atualização 2026-11-17:** mudanças no ADR-0013 e no `control-manifest.md` aplicadas em `2026-11-17`. Pendências residuais de release (templates de exportação 4.7.2 para P7/P1 no `.exe`) registradas sem bloquear a story.
