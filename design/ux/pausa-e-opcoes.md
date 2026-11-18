# UX Spec: Pausa e Opções

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Screen / Flow Name**: `MenuDePausa`, `TelaDeOpcoes` (abas Vídeo, Áudio, UI, Acessibilidade, Controles), diálogos `ConfirmarAbandono`, `ResetDePerfil`, avisos `PERFIL_*`
> **Platform Target**: PC — teclado+mouse, gamepad
> **Related GDDs**: `run-e-regioes.md` R6 · `rng-com-seed.md` F9 (formato e locais da seed) · `input-e-controle.md` R8, R10, R11, Edge Cases (Remapeamento) · `save-e-perfil.md` R8, R11, UI Requirements · `hud.md` R12, R13
> **Related ADRs**: ADR-0012 §4, §6, §7, §8, §10, §11 · ADR-0013 §2, §8 (`opcoes.cfg`) · ADR-0001 (`PAUSA`)
> **Related UX**: `hud.md`, `tela-de-bencao.md`, `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`

## 1. Propósito

**Pausa:** parar com segurança, ver a run (bênçãos tomadas, seed) e decidir se continua ou abandona. **Opções:** ajustar o jogo ao corpo e ao equipamento do jogador sem sair da run. O jogo precisa que nenhum clique acidental abandone a run ou apague o perfil.

## 2–4. Posição, entrada e saída

```
Menu principal ──┬── Opções (com "Apagar progresso de pactos")
JOGO / BENCAO ── Pausa ──┬── Continuar
                         ├── Opções (reset desabilitado, motivo visível)
                         ├── Copiar seed
                         └── Abandonar run → Confirmar (só de JOGO)
```

| Entrada | Origem | Notas |
|---|---|---|
| Esc / Start | `JOGO` ou `BENCAO` → `PAUSA` | não abre no hitstop (aperto descartado) nem na Transição |
| Perda de foco da janela | `JOGO` → `PAUSA` | barreira de retorno: o clique que reativa não aciona nada (ADR-0012 §4) |
| "Opções" | Menu principal | inclui reset de perfil |

| Saída | Destino | Efeito |
|---|---|---|
| Continuar / Esc / B | estado anterior (`retomar()`) | Bênção: trava 300 ms, mesma oferta |
| Abandonar → Confirmar | `ENCERRADA(ABANDONO)` → tela de fim | mantém Fragmentos; irreversível |
| Opções → Voltar | Pausa / Menu | cada mudança já gravou em `opcoes.cfg` |

## 5. Layout

```
╔═══════ PAUSA (overlay; HUD a 60% por baixo) ═══════╗
║  ●[Continuar]                 Bênçãos tomadas:       ║
║   [Opções]                    {glifo · nome · raridade} ...  (rolável) ║
║   [Copiar seed]                                     ║
║   [Abandonar run]  (desab. em Bênção: "indisponível durante a oferta") ║
║  3F9A-07C2 · v0.1.0 · c1B4E   (algarismos tabulares, discreto)          ║
╚═════════════════════════════════════════════════════╝
╔═══ OPÇÕES ═══ [Vídeo] [Áudio] [UI] [Acessibilidade] [Controles]  (LB/RB, Q/E) ═══╗
║ Vídeo: modo de janela, resolução, V-Sync, limite de qps                         ║
║ Áudio [audio]: geral, música, efeitos, vozes 0–100%                             ║
║ UI [ui]: escala 85/100/125/150 · número de Vida · Vida colorida · alto contraste· vinheta 0–100% · fonte de leitura ║
║ Acessibilidade [acessibilidade]: tremor de câmera 0–100% · reduzir flashes · redução de movimento · números de dano (lig/reduz/desl) · telégrafo alto · encurtar hitstop ║
║ Controles: dispositivo [Teclado|Gamepad] · lista de ações × 3 binds · zona morta · [Restaurar padrões] ║
║ (só no menu principal) [Apagar progresso de pactos]                             ║
╚════════════════════════════════════════════════════════════════════════════════╝
```

Chaves e donos: tabela do ADR-0013 §8 (nomes provisórios). Vídeo não está no §8: chaves `[video]` propostas aqui (decisão do agente). Bênçãos tomadas só leitura, foco opcional para ler a descrição.

## 6. Estados e erros

| Estado | Gatilho | Mudança |
|---|---|---|
| Pausa em Bênção | aberta de `BENCAO` | Abandonar desabilitado por forma (riscado) e texto |
| Confirmar abandono | Abandonar | diálogo; foco padrão **Cancelar** |
| Seed copiada | Copiar seed | `SEED_COPIADA` discreto 2 s |
| Captura de bind | Enter num bind | "Aperte a nova tecla… (Esc cancela)"; relógio `t_real` |
| Conflito de bind | bind já usado no mesmo contexto | troca automática + `INPUT_CONFLITO_TROCA`; recusa se deixaria ação sem primário |
| Binds corrompidos | carga | padrões + aviso 1× (Input Edge Cases) |
| Falha ao gravar opções | I/O | `OPCOES_FALHA_GRAVAR` 1× por tentativa; sessão segue em memória |
| Reset: 1ª e 2ª confirmação | menu principal | `PERFIL_RESET_CONFIRMAR` duas vezes, Cancelar padrão; backup antes |
| Reset indisponível | em run, ou modo Sem gravação (Save R8) | item desabilitado com motivo visível |
| Avisos `PERFIL_CORROMPIDO`, `PERFIL_VERSAO_FUTURA`, `PERSIST_FALHA_GRAVAR`, `PERFIL_SAIR_SEM_SALVAR` | Save | 1×/sessão, só fora de `JOGO`, navegáveis, `ui_voltar` = Cancelar (ADR-0012 §10) |

## 7. Interação

| Ação | Teclado | Gamepad | Mouse |
|---|---|---|---|
| Navegar | W/S, ↑/↓; A/D ajusta valor | D-pad / analógico; ←/→ ajusta | hover move foco |
| Confirmar | Enter/Espaço/E | A | clique confirma o alvo (política de Menu, Input R9) |
| Voltar | Esc | B | botão Voltar |
| Trocar aba | Q/E | LB/RB | clique na aba |
| Copiar seed (atalho) | C | — (item focável) | clique |

Sliders mudam em passos de 5% (segurar acelera). Clique direito: nada.

## 8–9. Dados e eventos

Lê: `LeituraDaRun.texto_seed()` (formato F9 pronto), bênçãos tomadas, valores do `RepositorioDeOpcoes`, binds do Input, `pode_resetar` do Save. Escreve só por porta: `retomar()`, `PortaDaRun.abandonar()` (persistente: resumo e Fragmentos), `PortaDaAreaDeTransferencia.copiar(texto)`, `RepositorioDeOpcoes.gravar(secao, chave, v)`, binds pelo Input (`input_binds.cfg`), reset pelo Save (perfil; persistente e destrutivo).

## 10. Transições

Pausa: fade 0,15 s (`t_real`); Opções: troca de painel em corte. Redução de movimento: tudo em corte.

## 11–12. Entrada e acessibilidade

Todos os itens alcançáveis por teclado e gamepad; foco preso no menu; Esc volta um nível e nunca sai do jogo. Escala de UI aplica na hora (pré-visualização é a própria tela). Desabilitados lidos por forma + texto do motivo. Alto contraste se aplica à pausa. Desconexão de gamepad em `JOGO` abre a pausa (Input R11).

## 13. Localização

Nomes de opções ≤ 28 caracteres na coluna de rótulo (+40% quebra em 2 linhas: ALTA prioridade nas de Acessibilidade). Seed não é traduzida.

## 14. Critérios de aceite

- [ ] Esc em `JOGO` abre a pausa em ≤ 1 passo; em hitstop o aperto é descartado.
- [ ] Pausa aberta na Bênção: "Abandonar run" riscado com motivo; Continuar volta à mesma oferta com trava de 300 ms.
- [ ] Abandonar exige confirmação com Cancelar em foco; confirmado, a run termina com motivo `abandono` e o saldo de Fragmentos não muda.
- [ ] A seed aparece no formato `XXXX-XXXX · vX.Y.Z · cXXXX`; Copiar seed põe esse texto na área de transferência.
- [ ] Remapear `ataque` para a tecla do `especial` troca os dois e mostra `INPUT_CONFLITO_TROCA`; fechar e reabrir o jogo mantém os binds.
- [ ] Mudar a escala para 150% reposiciona o HUD na hora; reiniciar mantém 150% (`[ui] escala`).
- [ ] "Apagar progresso de pactos" só fica ativo no menu principal, pede duas confirmações e cria `perfil.cfg.reset.bak`.
- [ ] Nenhum aviso `PERFIL_*` aparece durante `JOGO`; todos são dispensáveis com B/Esc.
- [ ] Todo o fluxo é concluído só com gamepad.

## 15. Open Questions

| Questão | Dono | Resolução |
|---|---|---|
| Chaves `[video]` e nome final das chaves `[ui]` | technical-director (ADR-0013) | proposta do agente |
| API de clipboard na 4.7.2 (NEEDS VERIFICATION, ADR-0012 §11) | godot-specialist | antes da story |
