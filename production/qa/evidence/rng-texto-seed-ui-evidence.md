# Evidência — RNG: texto da seed na interface (`story-007-texto-da-seed-na-interface`)

- **Data**: 2026-11-18
- **Story**: `production/epics/rng/story-007-texto-da-seed-na-interface.md`
- **GDD**: `design/gdd/rng-com-seed.md` (R8, F9, UI Requirements, AC-22)
- **ADRs**: `docs/architecture/adr-0005-rng-deterministico.md`, `docs/architecture/adr-0012-ui-e-hud.md` (§11)
- **Engine**: Godot 4.7.2

## Artefatos implementados e verificados

1. **Formatador e parse estrito (`src/foundation/rng/texto_da_seed.gd`, `class_name TextoDaSeed`)**:
   - Formata a seed em 8 dígitos hexadecimais maiúsculos com hífen (`XXXX-XXXX`, F9) e compõe o rótulo completo `XXXX-XXXX · vX.Y.Z · cXXXX` (R8), ou `"sem seed"` quando a `FonteDeFluxos` está em `SEM_RUN`.
   - Parse estrito (`interpretar`) sem `String.hex_to_int()`, aceitando 1 a 8 dígitos hex (com hífen apenas na posição 4+4) e recusando entradas inválidas com mensagem que cita o texto digitado.

2. **Controlador de exibição, cópia e edição debug (`src/foundation/rng/controlador_da_seed_na_ui.gd`, `class_name ControladorDaSeedNaUi`)**:
   - Fornece o texto pronto para as telas hospedeiras (pausa, morte, vitória e overlay de debug) sem que a UI acesse `Input` ou a `FonteDeFluxos` diretamente.
   - Copia o rótulo completo para a área de transferência por `Callable` injetado (`DisplayServer.clipboard_set` verificado em `EX-0012 CB`, `production/qa/evidence/experimentos/ex-0012-ui.md`) e registra a confirmação discreta `SEED_COPIADA`.
   - Gerencia o campo de seed do menu de debug (`submeter_campo_debug`): quando a entrada é inválida, **mantém o texto digitado no campo** e expõe a mensagem do parse F9; quando válida, armazena a seed u32 e formata o campo em `XXXX-XXXX`.
   - Calcula e valida o guardrail de largura mínima para as escalas de UI de `85%` a `150%` (`largura_minima_sem_corte_px`, `cabe_sem_corte`).

3. **Suíte de testes unitários (`tests/unit/rng/rotulo_da_seed_test.gd` e `tests/unit/rng/texto_da_seed_test.gd`)**:
   - Verifica exibição em `RUN_ATIVA` (pausa/debug) e `ENCERRADA` (morte/vitória), cópia para a área de transferência, preservação do texto inválido + mensagem no campo de debug, integração com `RoteadorDeFoco` em contexto `texto` e guardrail de escala 85–150%.

4. **Evidências visuais e de engine retidas**:
   - `production/qa/evidence/experimentos/ex-0012-ui.md` (seção **CB — área de transferência** e `ex-0012-e2-final.png`).
   - `production/qa/evidence/integracao-jogavel/pausa.png`, `morte.png`, `resultado-real.png`.

## Cobertura dos Critérios de Aceite

| AC | Descrição | Status | Evidência |
|---|---|---|---|
| **AC-22** | Texto completo da seed (`XXXX-XXXX · vX.Y.Z · cXXXX`) em pausa, morte, vitória e debug; campo de debug inválido mantém texto digitado e mostra mensagem | PASS | `tests/unit/rng/rotulo_da_seed_test.gd`, `tests/unit/rng/texto_da_seed_test.gd` |
| **R8 / UI** | Copiar coloca o texto completo da seed na área de transferência | PASS | `tests/unit/rng/rotulo_da_seed_test.gd`, `ex-0012-ui.md` (CB) |
| **Guardrail** | Escala de UI 85–150% não corta o texto da seed | PASS | `tests/unit/rng/rotulo_da_seed_test.gd` (`cabe_sem_corte`) |

## Sign-off

- **Engine Programmer**: Aprovado e verificado (2026-11-18).
