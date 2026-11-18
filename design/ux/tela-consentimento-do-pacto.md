# UX Spec: Tela de consentimento do pacto (e Pactuar / Exorcizar)

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Screen / Flow Name**: `TelaDeConsentimento` (variantes `encontro` e `chefe`)
> **Platform Target**: PC — teclado+mouse, gamepad
> **Related GDDs**: `vinculo-e-pactos.md` V9, V10, V11, V13, V15, V18, UI Requirements · `chefes.md` R9, R9b · `hud.md` R10, R12
> **Related ADRs**: ADR-0012 §10 (`PortaDoPacto`) · ADR-0001 (`BENCAO` abriga as duas telas) · ADR-0013 (ponto seguro)
> **Related UX**: `tela-de-bencao.md` (mesma máquina de foco e travas), `hud.md`, `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`

## 1. Propósito

O jogador acabou de proteger uma Maldição acuada (ou subjugou o chefe) e quer **decidir, sem pressa, se cria o vínculo** — sabendo o que ganha e o que deixa. É "o único instante da run sem pressa: um gesto, não um saque" (Vínculo, Game Feel). O jogo precisa de uma escolha que grava no mesmo passo (V9).

## 2–4. Contexto, entrada e saída

Voluntário: o jogador vai até a acuada `Aguardando` ou o chefe `Subjugado` e aperta **Interagir** (prompt do HUD R10). Se a Bênção abrir na limpeza, ela vem antes (V9).

| Entrada | Origem | Dados |
|---|---|---|
| Interagir na acuada | `JOGO` → `BENCAO` | espécie, raridade, memória desta vez, caso V10/V11/V13 |
| Interagir no chefe ajoelhado | `JOGO` → `BENCAO` | caso V18 (3/4/5), destinatários dos pontos, `+6` |
| Continuar da pausa | `PAUSA` → `BENCAO` | trava 300 ms |

| Saída | Destino | Efeito (irreversível) |
|---|---|---|
| Oferecer / Reafirmar / Ela voltará / Deixá-la ir | `tela_fechada` → `JOGO`; `pacto_resolvido` abre as portas | `pacto_registrado` → Save grava no fim do passo |
| Pactuar / Exorcizar | `tela_fechada` → `JOGO` → `camara_limpa(4)` → vitória | `chefe_escolhido`; R9b (crédito +6 só no Exorcizar) |
| Esc / Start | Pausa por cima ("Abandonar run" desabilitado) | nada |

Sem tempo limite; não se dispensa sem escolher (a acuada espera; sair por uma porta é impossível até resolver, V9).

## 5. Layout

```
╔════════════════ (mundo congelado; a Maldição ao centro, em silhueta de Osso) ═══════════════╗
║                          ESPREITADOR DA FENDA                                                ║
║                          Raro ◇◇  (palavra + ornamento)                                      ║
║        ┌───────────────────────────────────────────────────────┐                             ║
║        │ "memória revelada nesta vez" (2–4 linhas)             │                             ║
║        └───────────────────────────────────────────────────────┘                             ║
║  encontro:  [●Oferecer o vínculo]     [Deixá-la ir]       | ou [●Ela voltará]  (V13)         ║
║             [●Reafirmar o vínculo (+6)] [Deixá-la ir]     (V11)                              ║
║  chefe:     [●Pactuar · 0 Fragmentos · +10 vínculo → Vulto, Espreitador] [Exorcizar · +6 ◆]  ║
║             "O vínculo já está inteiro" quando V18.5 sem ganho                               ║
╚══════════════════════════════════════════════════════════════════════════════════════════════╝
```

**Foco inicial:** o botão da esquerda (o gesto do vínculo). Decisão: no chefe com "vínculo já inteiro", o foco vai a Exorcizar (a escolha racional que a própria tela anuncia). Preço e ganho ficam **no rótulo do botão**, à vista antes de confirmar (P2).

## 6. Estados

| Estado | Gatilho | Mudança |
|---|---|---|
| Consentir | V10, contagem atingida | 2 botões |
| Ainda não confia | V13 (Raro/Épico 1ª vez) | 1 botão "Ela voltará"; texto da amarra de Osso |
| Reafirmar | V11 | 2 botões, "+6" no rótulo |
| Chefe novo / reafirmado / fardo repartido / inteiro | V18.3–5 | rótulo de Pactuar muda; destinatários listados |
| Travada | abrir/voltar da pausa | 500 / 300 ms, borda de subida (Tela R7) |
| Falha de gravação | Save | escolha vale na run; `PERSIST_FALHA_GRAVAR` discreto depois de fechar |

## 7. Interação

| Ação | Teclado | Gamepad | Mouse |
|---|---|---|---|
| Mover foco | A/D, ←/→ | D-pad, analógico | mover sobre o botão |
| Confirmar | Enter/Espaço/E | A (Sul) | clique (só no botão já em foco, como a Tela R6) |
| Pausa | Esc | Start | — |

Sem atalho numérico; Voltar (B) não fecha (decisão obrigatória) e só treme a tela 80 ms. Não dá a volta.

## 8–9. Dados e eventos

Lê do Vínculo (consulta): espécie, raridade, caso, memória, destinatários. Chama `PortaDoPacto.oferecer()` / `deixar()` / `voltara()` e, no chefe, a escolha `pactuar|exorcizar`; `notificar_tela_fechada()`. Persistente: `pacto_registrado` (perfil).

## 10. Transições

Entrada: mundo esmaece em 0,25 s, nome e memória aparecem em 0,3 s, botões em seguida (≤ 0,6 s total). Confirmar: botão escolhido acende, a silhueta dissolve em luz de Osso (Pactuar/Oferecer) ou em tinta (Exorcizar/Deixar), ≤ 0,6 s. Redução de movimento: fade ≤ 300 ms.

## 11–12. Entrada e acessibilidade

Completo em teclado, gamepad e mouse; foco preso; Esc abre pausa. Botões ≥ 320 × 64 px. Raridade por palavra e ornamento; ganho e preço em texto (não só ícone ◆). Foco: anel ≥ 4 px + escala 106%. Memória em fonte de leitura, contraste ≥ 4,5:1 sobre placa ≥ 92%.

## 13. Localização

Rótulos dos botões do chefe são os mais longos (~45 caracteres): 2 linhas permitidas, altura fixa — ALTA prioridade. Números por `tr().format`.

## 14. Critérios de aceite

- [ ] Interagir abre a tela em ≤ 1 passo e o mundo para (estado `BENCAO`); fios e prompt do HUD somem.
- [ ] Espécie Rara na 1ª vez mostra só "Ela voltará"; Comum mostra "Oferecer o vínculo" e "Deixá-la ir".
- [ ] Confirmar "Oferecer" grava o perfil no mesmo passo (fechar o jogo logo após e reabrir: pacto presente).
- [ ] No chefe, "Exorcizar" credita exatamente +6 e "Pactuar" 0; uma segunda confirmação não credita de novo.
- [ ] B/Esc nunca resolvem a escolha; Esc abre a pausa sem "Abandonar run" ativo.
- [ ] Os rótulos mostram preço e ganho antes do confirmar, legíveis em tons de cinza.
- [ ] Toda a tela é concluída só com teclado e só com gamepad.

## 15. Open Questions

| Questão | Dono | Resolução |
|---|---|---|
| ADR-0001 aceitar `BENCAO` com duas telas (pendência do ADR-0012) | technical-director | assumido |
| Foco inicial em Exorcizar no caso "inteiro" | usuário | decisão do agente |
