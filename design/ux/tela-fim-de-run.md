# UX Spec: Tela de fim de run

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Screen / Flow Name**: `TelaFimDeRun` (variantes `vitoria`, `morte`, `abandono`)
> **Platform Target**: PC — teclado+mouse, gamepad
> **Related GDDs**: `run-e-regioes.md` R4, R5, R6, R7, R7-P, R8, R8-P · `rng-com-seed.md` F9 · `vinculo-e-pactos.md` V17, UI Requirements ("Painel de vínculo na tela final") · `economia-de-fragmentos.md` (saldo) · `hud.md` R12
> **Related ADRs**: ADR-0015 (`ENCERRADA`, `ResumoDaRun` §8, tabela de estados) · ADR-0012 §11 (seed e copiar) · ADR-0001 (`MENU`, `MORTE`)
> **Related UX**: `tela-escolha-de-arma-e-pacto.md` (Nova run), `pausa-e-opcoes.md`, `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`

## 1. Propósito

O jogador quer **entender como a run foi e voltar logo à próxima**. Na morte, ver o que levou consigo (Fragmentos, vínculo) suaviza a perda; na vitória, é a recompensa lida. O jogo precisa mostrar o resumo imutável e oferecer "Nova run" sem atrito.

## 2–4. Entrada e saída

| Entrada | Origem (ADR-0015) | Dados |
|---|---|---|
| Vitória | `camara_limpa` final → `ENCERRADA(VITORIA)` → `MENU`, sem Transição | `ResumoDaRun` |
| Morte | `MORTE` (animação do Combate) → `MENU` | idem |
| Abandono | `PAUSA` → `ENCERRADA(ABANDONO)` → `MENU` | idem |

| Saída | Destino | Efeito |
|---|---|---|
| Nova run (padrão) | Escolha de arma (última arma marcada; com Pactos pede dupla) | reset total R8/R8-P; seed nova |
| Menu principal | Menu | — |
| Copiar seed | fica na tela | área de transferência |

Esc/B não faz nada aqui (não há "voltar" para a run); decisão do agente para evitar sair por engano antes de ler.

## 5. Layout

```
╔═══════════════════ VITÓRIA  /  A BEIRA TE DEVOLVEU  /  RUN ABANDONADA ═══════════════════╗
║  Arma: Besta do Vínculo · Dupla: Vulto Mudo / Espreitador   Desfecho do chefe: Pactuado    ║
║ ┌─ Run ───────────────────────┐   ┌─ Fragmentos ───────────┐   ┌─ Vínculo (só Pactos) ──┐  ║
║ │ Câmaras limpas   7          │   │ Coletados        22    │   │ Vulto   +14  ▓▓▓░ Nv 2 │  ║
║ │ Bênçãos tomadas  4          │   │ Bônus de vitória +15   │   │ Espreit.+10  ▓░░░ Nv 1 │  ║
║ │ Abates           63         │   │ Total da run     37    │   │ "Nível subiu!" (texto) │  ║
║ │ Duração          18:42      │   │ Saldo        1 234     │   │ pacto novo: Soberano   │  ║
║ └─────────────────────────────┘   └────────────────────────┘   └────────────────────────┘  ║
║        ●[Nova run]      [Menu principal]      [Copiar seed]                                ║
║  3F9A-07C2 · v0.1.0 · c1B4E                                                                ║
╚════════════════════════════════════════════════════════════════════════════════════════════╝
```

Os 12 campos de R7/R7-P: motivo (título), seed (rodapé), arma, câmaras limpas, bênçãos tomadas, Fragmentos coletados, bônus de vitória (morte/abandono: "—"), total, abates, duração, `desfecho_chefe` (oculto se `nenhum`), `dupla` (oculta fora de Pactos). Saldo e painel de vínculo são extras (Economia; Vínculo V17), não campos do resumo.

Hierarquia: (1) motivo; (2) Fragmentos e vínculo ganhos (o que fica); (3) números da run; (4) seed. Foco inicial: **Nova run**.

## 6. Estados

| Estado | Gatilho | Mudança |
|---|---|---|
| Vitória | motivo `vitoria` | título em Osso e dourado; bônus visível |
| Morte | `morte` | título em tinta; bônus "—"; tom de consolo |
| Abandono | `abandono` | título neutro; bônus "—" |
| Sem Pactos | Doutrina ≠ `pactos` | painel de vínculo e "Dupla" ocultos; colunas centralizam |
| Pacto feito na run e run perdida | R8-P | vínculo listado ("o pacto fica") |
| Resumo ausente (erro) | `resumo()` nulo | mostra só motivo + Nova run; log de erro com a seed |
| Trava de entrada | abrir | 500 ms por borda de subida, para o ataque segurado não virar "Nova run" |

## 7. Interação

| Ação | Teclado | Gamepad | Mouse |
|---|---|---|---|
| Mover foco | A/D, ←/→ | D-pad, analógico | hover |
| Confirmar | Enter/Espaço/E | A | clique |
| Copiar seed | C | item focável | clique |

## 8–9. Dados e eventos

Lê `run.resumo()` (imutável, montado pela Run), `texto_seed()`, `saldo()` da Economia e pontos/nível da run por espécie do Vínculo. Não escreve: "Nova run" chama `SessaoDeJogo.nova_run()`; "Copiar seed" chama `PortaDaAreaDeTransferencia.copiar`. Telemetria do resumo é da Run.

## 10. Transições

Entrada: fade 0,4 s; os números contam de 0 ao valor em 0,6 s, painéis com 80 ms de defasagem (pulável com Confirmar, que aí só completa a contagem). Redução de movimento: números aparecem prontos, fade ≤ 300 ms.

## 11–12. Entrada e acessibilidade

Três botões, ordem esquerda→direita, sem volta. Foco preso. Hit targets ≥ 280 × 64. Vitória/morte pelo **texto do título**, não pela cor. Barras de vínculo com número de nível ao lado. Contraste ≥ 4,5:1; fonte de leitura e escala de UI valem. Carga: 12 campos agrupados em 3 painéis (≤ 5 por painel).

## 13. Localização

Título de morte é o mais longo: uma linha em H1 com redução até o piso — ALTA prioridade. Duração `mm:ss`; milhar pela `FormatoNumerico`.

## 14. Critérios de aceite

- [ ] A tela aparece em ≤ 500 ms após `run_encerrada` (vitória) ou após o fim do estado Morte.
- [ ] Uma vitória de Lâmina mostra câmaras limpas = 7, bônus +15, sem painel de vínculo nem campo Dupla.
- [ ] Uma morte em run de Pactos com pacto feito mostra o pacto no painel de vínculo e bônus "—".
- [ ] Os 12 campos de R7-P aparecem com valores iguais ao `ResumoDaRun` registrado na telemetria.
- [ ] Segurar Ataque durante a morte e soltar na tela não aciona "Nova run".
- [ ] "Nova run" abre a Escolha de arma com a última arma em foco e seed diferente da anterior.
- [ ] Copiar seed põe na área de transferência exatamente o texto do rodapé.
- [ ] Toda a tela é operável só por gamepad e só por teclado.

## 15. Open Questions

| Questão | Dono | Resolução |
|---|---|---|
| Títulos finais por motivo | writer | provisórios |
| Esc/B sem efeito na tela final | usuário | decisão do agente |
