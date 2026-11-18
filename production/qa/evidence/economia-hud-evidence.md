# Evidência de QA — Saldo de Fragmentos no HUD e `+N` ao Ganhar (`economia-de-fragmentos/story-007`)

- **Story**: `production/epics/economia-de-fragmentos/story-007-saldo-no-hud-evidencia.md`
- **Épico**: `production/epics/economia-de-fragmentos/EPIC.md`
- **GDD Governante**: `design/gdd/economia-de-fragmentos.md` (`R7`, `AC-EC-10`, `AC-EC-11`, `AC-EC-13`)
- **ADRs Governantes**: `ADR-0002` (Canal de eventos do passo), `ADR-0011` (Pipeline visual e HUD), `ADR-0016` (Persistência de perfil)
- **Data**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE**

---

## 1. Contrato de Leitura e Eventos (`src/gameplay/economia/`)

| Artefato | Responsabilidade | Regra / Critério |
|---|---|---|
| `src/gameplay/economia/leitura_da_conta.gd` (`LeituraDaConta`) | Interface somente-leitura (`saldo() -> int`, `nivel(id: StringName) -> int`) injetada no HUD e no Santuário; não expõe métodos de mutação (`creditar`/`gastar`/`resetar`), garantindo que o HUD nunca altere o saldo (`R7`, `AC-EC-11`). | `R7`, `AC-EC-11` |
| `src/gameplay/economia/conta_de_fragmentos.gd` (`ContaDeFragmentos`) | Emite `EvSaldoMudou(saldo_atual, delta, motivo)` no canal do passo quando `creditar(q, motivo)` altera o saldo (`delta = ganho_efetivo > 0`). Quando `q == 0` ou o saldo já está no teto `99.999` (`ganho_efetivo == 0`), **nenhum** `EvSaldoMudou` é emitido (`AC-EC-04`, `AC-EC-13`). | `R2`, `R7`, `AC-EC-04`, `AC-EC-13` |
| `src/gameplay/economia/ev_saldo_mudou.gd` (`EvSaldoMudou`) | Evento tipado `saldo_mudou(saldo, delta, motivo)` consumido pelo `HudController` para atualizar o contador de Fragmentos e exibir o texto transitório `+N` (1 instância activa por vez, substituída sem empilhar quando chega novo ganho). | `R7`, `AC-EC-10`, `AC-EC-13` |

---

## 2. Verificação Automatizada e Evidência Visual

1. **Testes Unitários de Economia (`tests/unit/economia/`)**:
   - `tests/unit/economia/credito_e_teto_test.gd`: verifica emissão de `EvSaldoMudou` com `delta > 0`, truncamento no teto `99.999` (`delta = 9` quando `99.990 + 25 -> 99.999`) e ausência de evento quando `ganho_efetivo == 0` (`AC-EC-04`, `AC-EC-13`).
   - `tests/unit/economia/fluxo_run_e_hud_test.gd`: verifica que o HUD recebe apenas `LeituraDaConta`, atualiza o saldo exibido ao receber `EvSaldoMudou`, exibe uma única instância transitória `+N` (substituindo a anterior se chegar novo ganho durante a janela) e **não** exibe `+0` quando o crédito efetivo é `0` (`AC-EC-10`, `AC-EC-11`, `AC-EC-13`, `TR-economia-007`).
2. **Evidência Visual Retida**:
   - `production/qa/evidence/arte-ui-lut-evidence.md` e `production/qa/evidence/portas-recompensas-evidence.md`: confirmam a renderização do contador de Fragmentos no canto do HUD de combate e a transição de recompensa de sala/chefe sem sobreposição nem texto `+0`.
