# Review Log — Input e controle

## Review — 2026-11-05 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 3 | Recommended: 7
Summary: Documento sólido e testável: F1–F5 conferem nos exemplos, o buffer e a ordem de consumo batem com `bufferInput`/`updatePlayer` do cânone (engine.ts) e 0 conflitos com o registro. Os três bloqueantes são lacunas de regra que obrigariam o programador a adivinhar: o que Esc/Start fazem em Tela e Pausa (Esc está em `pausar` e `ui_voltar` no mesmo contexto, contra a própria R8), "segurado" valendo para Esquiva e Selo na R6 (contra a R7 e o cânone) e a falta de um contexto de entrada de texto (campo de seed do debug).
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design (R1/R8/States): Esc em `pausar` e `ui_voltar` no contexto Tela viola a regra de conflito da R8; Pausa aceita "só `ui_*`", então Start não sai da pausa; falta definir Esc/Start na bênção, na Pausa e nos menus.
- [BLOCKING] Detailed Design (R6) + F3 + AC-19: "quer X? = segurado ou no buffer" vale para as quatro ações; segurar Esquiva/Selo repetiria. Cânone (engine.ts `updatePlayer`): Esquiva e Selo leem só o buffer; só Ataque/Especial usam segurado (R7).
- [BLOCKING] Detailed Design (R9/R10): sem contexto de texto; o campo de seed em hex do debug (RNG R8) conflita com `ui_navegar` em WASD (A e D são hex). O mesmo vale para o nome do Iniciado no futuro.
- [RECOMMENDED] States (Remapeando) + UI: a captura engole o clique em "Cancelar" e o botão é inalcançável pelo teclado; falta perda de foco/desconexão durante a captura.
- [RECOMMENDED] Detailed Design (R12) + F2 + AC-05: `zm + ze ≥ 1` é inalcançável com as faixas declaradas (máx. 0,7); Conteúdo V2 é só por campo; AC-05 usa valores já fora da faixa e não testa a soma.
- [RECOMMENDED] Formulas (F3) + R6: definir quando um passo "é de hitstop" (a amostra roda antes do Combate); a justificativa cita o hitstop de 36 passos, que no cânone é `HITSTOP_BOSS_KILL` (fim da luta); o caso real dentro da luta é 6.
- [RECOMMENDED] Detailed Design (R3) + F4: desvios do cânone sem rótulo: teclado vence o analógico (cânone: o analógico sobrescreve) e raio inclusivo ≤ 900 (cânone `d < 900`).
- [RECOMMENDED] Formulas (F5): `L_mouse` em px de tela varia com resolução/DPI; usar px do viewport base (1280×720).
- [RECOMMENDED] Acceptance Criteria (AC-18): "o Selo roda por último" sem resultado verificável; dar o buffer esperado ao fim do passo.
- [RECOMMENDED] Dependencies: Conteúdo não cita Input/`InputTuning`; linha 4 do índice omite IA (contrato) e Save e perfil.
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes (advisory no `standard`); R12 não lista `ze` nem o valor de `L_mouse`; tempos de 1 s/5 s e limiares do gatilho sem faixa segura; conceito §3 ainda diz "gamepad parcial".
Reviewed-Content-Hash: design/gdd/input-e-controle.md 9b7dc63de550e9880df174e86e06ae4e5b9432d6
Reviewed-Content-Hash: design/registry/entities.yaml 2e7e7f09d99ae23fd214b5eef78da6f326821aaa
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 282013685bbe56afa56bba088a2e13f6a7c2eb51
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 0105f1becdf248e5e60ba368c147b13ec0e4ff8c
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 53a18f284ee0e7251a1d40ae5b33218bc34e531a


### Mudança externa — 2026-11-05 (GDD Cena 3/4 e câmera)
- Escala corrigida por decisão do usuário: viewport lógico 1920×1080 (Art Bible §8.6) → `unit_to_px` 1,0 → **1,5** (registro revisado). Foram atualizados só os números dependentes de escala neste GDD; nenhuma regra mudou. Fonte: `design/gdd/cena-3-4-e-camera.md` (R1, R2, F1). Reconferir na próxima revisão.

## Revisão aplicada — 2026-11-06 (decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Esc/Start | Contextos por tela (R1, R10, States): Jogo, Pausa e Bênção usam `pausar` (Esc/Start); Menu e Texto usam `ui_voltar` (Esc/B); na Bênção, Esc/Start abrem a Pausa por cima; Start não faz nada no Menu. Edge case e AC-26 ajustados; AC-35 novo. |
| [BLOCKING] Segurar Esquiva/Selo | R6: Ataque e Especial = segurado ou buffer; Esquiva e Selo = só buffer (cânone `updatePlayer`). Interactions e AC-19 ajustados. |
| [BLOCKING] Contexto de texto | Contexto Texto (R10, States): campo em edição recebe o teclado; só Enter e Esc são ações; gamepad não edita texto no MVP. AC-36 novo. |
| [RECOMMENDED] Dependencies | O GDD de Conteúdo agora cita Input e `InputTuning`. |

Em aberto: as outras 6 recomendadas de 2026-11-05 (captura do remapeamento, `zm + ze`, passo de hitstop, desvios sem rótulo, `L_mouse`, AC-18).

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 3 | Recommended: 10
Summary: Os 3 bloqueantes de 2026-11-05 foram resolvidos: Esc/Start por contexto sem colisão, Esquiva/Selo só buffer (cânone `engine.ts:806/875`) e contexto Texto coerente com a regra de troca. Os 3 novos: o foco duplo da R9/AC-33 contradiz o "um único modelo de foco" do Art Bible §7.6; as teclas da Bênção divergem do §7.6 (confirmar Enter/Espaço/E; 1/2/3 só movem o foco); e a R1 dá 3 binds de teclado à Esquiva contra o limite de 2 da R8. 0 conflitos com o registro.
Prior verdict resolved: Yes
Findings:
- [BLOCKING] Detailed Design (R9) + AC-33: mouse não rouba o foco (foco duplo) × Art Bible §7.6 "passar o mouse move o mesmo foco que o teclado e o gamepad".
- [BLOCKING] Detailed Design (R1/R9) + AC-33: Bênção confirma só com Enter × §7.6 Enter/Espaço/E; 1/2/3 "escolhem" × §7.6 "move o foco, não confirma".
- [BLOCKING] Detailed Design (R1 × R8): Esquiva com 3 binds de teclado (Espaço, Shift, L) × máximo de 2 por ação por dispositivo.
- [RECOMMENDED] Detailed Design (R10 Texto): Enter/Esc físicos ou binds de `ui_aceitar`/`ui_voltar`? Um bind imprimível quebra a digitação (E é hex).
- [RECOMMENDED] Detailed Design (R10 Texto) × RNG: campo de seed "usável por teclado e gamepad"; Enter com seed inválida sai ou não da edição.
- [RECOMMENDED] States + Interactions + Open Questions: Pausa sem perda de foco/desconexão em "Entra quando"; "Provisório" e OQ 6 dizem que Cena 3/4 não tem GDD; força da dependência Suave aqui × Forte na Cena 3/4.
- [RECOMMENDED] Detailed Design (R10 Bênção): trava de 500/300 ms do §7.6 sem referência cruzada.
- [RECOMMENDED] (abertas de 2026-11-05) captura do remapeamento; `zm + ze` inalcançável/AC-05; passo de hitstop e o caso de 36 passos; desvios sem rótulo (teclado vence o analógico, raio inclusivo); `L_mouse` em px de tela; AC-18 sem resultado do Selo.
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes; R12 sem `ze` e valor de `L_mouse`; conceito §3 ainda diz "gamepad parcial"; `tick_rate` sem o Input em `referenced_by`.
Reviewed-Content-Hash: design/gdd/input-e-controle.md e2960ddc1a419a28846d5143f6a8d99f06edc071
Reviewed-Content-Hash: design/registry/entities.yaml 03b431a3014ea0ed34194a06bdc78843376f3fc0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 73aea079f74991c9fe297ee845468040d6907075
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md cc1737d8cc81e6e00548b786a173030331210478
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9

## Revisão aplicada — 2026-11-06, na mesma sessão da re-review (decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Foco duplo × Art Bible §7.6 | R9: um único modelo de foco; o hover chama `grab_focus()` no `mouse_entered` (foco do mouse separado no 4.6+). AC-33 e OQ 2 ajustados. |
| [BLOCKING] Teclas da Bênção × §7.6 | R1: `ui_aceitar` = Enter (Espaço, E) / A; R9: 1/2/3 movem o foco e não confirmam. AC-33 ajustado. |
| [BLOCKING] 3 binds da Esquiva × R8 | R8: até 3 binds por ação por dispositivo (primário + 2 secundários); Shift é um bind só. Recusa do 4º bind (Edge Cases), AC-01 e AC-27 ajustados, tela de remapeamento com 2 secundários. |
| [RECOMMENDED] Texto × remapeamento | R1/R8/R10: no Texto só Enter e Esc **físicos**, fixos e fora do remapeamento; `ui_aceitar` e `ui_voltar` deixam de valer no Texto. AC-36 ampliado. |
| [RECOMMENDED] Texto × RNG | R10: Enter com valor recusado fica em Texto; A do gamepad não entra em edição. OQ 8 nova para alinhar o "usável por gamepad" do RNG. |
| [RECOMMENDED] States e referências | Pausa entra também por perda de foco e gamepad desconectado; "Provisório" e OQ 6 reconhecem a Cena 3/4 (R9/F6); dependência da Cena 3/4 passa a Forte (mira do mouse), também na linha 4 do índice; Cross-References com §7.6 e Cena 3/4. |
| [RECOMMENDED] Trava 500/300 ms | R9 remete ao GDD da Tela de bênção; OQ 9 nova. |

Em aberto (não escolhidas): captura do remapeamento; `zm + ze`/AC-05; passo de hitstop e o caso de 36 passos; desvios sem rótulo (teclado > analógico, raio inclusivo); `L_mouse` em px de tela; AC-18; advisories.

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 2 | Recommended: 8
Summary: 3ª re-review, independente, em sessão separada. Os 3 bloqueantes anteriores foram resolvidos: R9 com foco único e `grab_focus()` no `mouse_entered` (Art Bible §7.6); `ui_aceitar` = Enter/Espaço/E, com 1/2/3 só movendo o foco; R8 com até 3 binds e um mapa padrão que cabe nisso. As recomendadas aplicadas são coerentes entre si: Texto com Enter/Esc físicos, valor recusado fica em Texto (bate com RNG F9 e UI Requirements), A não edita, Pausa com 3 entradas, Cena 3/4 Forte e OQ 8–9. Os 2 bloqueantes novos são de interface: a amostra fechada da R2 não leva o que o lookahead da Cena 3/4 (F2, aprovada) precisa, e o hover que move o foco (R9) tira o campo de edição sem Enter/Esc (R10/States). 0 conflitos com o registro; F1–F5 e o cânone (`input.ts` `KEY_BINDINGS`/`readGamepad`/`computeAim`, `engine.ts` `bufferInput`) conferem.
Prior verdict resolved: Yes
Findings:
- [BLOCKING] Detailed Design (R2/Interactions/Dependencies) + AC-02 × Cena 3/4 F2/R9/Interactions: a Cena precisa da fonte da mira (mouse, analógico ou mira automática, em que a=0), do módulo do analógico direito depois da zona morta e do cursor por quadro de render (|m| até R_mouse). A amostra tem "os 6 campos", com `mirar` unitário, e "os sistemas leem só a amostra". A linha da Cena em Interactions diz "Recebe daqui: —", e a Cena 3/4 não está em downstream. A Cena diz que recebe do Input a "direção da mira (lookahead)".
- [BLOCKING] Detailed Design (R9 × R10 Texto/States): todo controle focável chama `grab_focus()` no `mouse_entered`, sem exceção para o Texto. Com o campo em edição, passar o mouse num controle vizinho tira o foco do campo e sai da edição sem Enter nem Esc. Não está definido se o valor é confirmado, descartado ou mantido em edição. O clique fora do campo também não está definido.
- [RECOMMENDED] Detailed Design (R9) + AC-22/AC-33: os ACs [I] de confirmar na Bênção precisam declarar a trava de 500/300 ms (zerada no teste ou esperar 500 ms depois de assentar), senão falham contra a tela real.
- [RECOMMENDED] Detailed Design (R10 Texto): entrar em edição com E ou Espaço (binds de `ui_aceitar`) pode digitar o próprio caractere ou repeti-lo por auto-repeat do sistema; a regra "segurados ignorados até soltar" só cobre ações.
- [RECOMMENDED] States (Sem foco × Pausa): a perda de foco aparece como entrada da Pausa e como estado próprio que "sai para Pausa"; dizer se Sem foco é uma marca ortogonal ou um estado exclusivo, e se o mundo para durante ele.
- [RECOMMENDED] Detailed Design (R1/R8): "Shift é um bind só e vale pelos dois lados" × bind por tecla física. Falta dizer o que a captura grava ao apertar Shift direito, e se Ctrl/Alt seguem a mesma regra.
- [RECOMMENDED] Open Questions (OQ 2): diz "antes de escrever o AC-33", mas o AC-33 já foi escrito com base nela; trocar por "antes da story das telas" (como a coluna já diz).
- [RECOMMENDED] Dependencies × RNG UI Requirements: o RNG ainda diz que o campo de seed é "usável por teclado e gamepad" (OQ 8 acompanha). Debug-only, sem impacto no jogador.
- [RECOMMENDED] (abertas desde 2026-11-05) captura do remapeamento (clique em "Cancelar", perda de foco/desconexão); `zm + ze ≥ 1` inalcançável com as faixas, e o AC-05 testa valores fora da faixa, não a soma; quando um passo "é de hitstop" (a amostra roda antes do Combate) e o caso de 36 passos (`HITSTOP_BOSS_KILL`, fim de luta); desvios sem rótulo (teclado vence o analógico; raio ≤ contra `d < 900` do cânone); `L_mouse` em px de tela × DPI; AC-18 sem o buffer esperado ao fim do passo.
- [RECOMMENDED] Índice: na linha 4, Depends On não tem IA (contrato) nem Save e perfil; na l. 155, "suave: Conteúdo, Cena 3/4" (Cena 3/4 agora é forte).
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes; R12 sem `ze` (0,05) e sem o valor de `L_mouse` (4); conceito §3 (l. 64) ainda diz "gamepad parcial"; `tick_rate` sem Input em `referenced_by`. Na Cena 3/4 (l. 243), o Input "recebe posição da câmera para o limiar do mouse", mas a F5 do Input mede eventos em px de tela e não precisa dela.
Reviewed-Content-Hash: design/gdd/input-e-controle.md f3add086d1372cd85137edc2614520e4ebd43fac
Reviewed-Content-Hash: design/registry/entities.yaml 03b431a3014ea0ed34194a06bdc78843376f3fc0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 2e7d5907f34b67d15cabf9a6b958168a86444da7
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md cc1737d8cc81e6e00548b786a173030331210478
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9

## Revisão aplicada — 2026-11-06, na mesma sessão da 3ª re-review (decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Amostra sem os dados do lookahead da Cena 3/4 | R2: a amostra passa a ter 8 campos (`fonte_mira` = `mouse`/`analogico`/`automatica`; `intensidade_mira` = módulo do analógico direito depois da F2, 0 fora do analógico). R5: fonte da mira por critério e **consulta de cursor** só de leitura, em px de janela, lida no quadro de render e usada só pela Cena 3/4; é a única exceção a "só a amostra". Interactions e downstream com a Cena 3/4 (Suave); nota de ciclo por contrato. AC-02 com 8 campos; AC-37 novo. |
| [BLOCKING] Hover × contexto Texto | R9: exceção, no Texto o hover não move o foco. R10 Texto: clique fora do campo = Esc (sai sem mudar o valor, e o clique não aciona o controle, porque conta como segurado na troca); clique dentro só move o cursor de texto. States (Texto) ajustado. AC-36 ampliado. |
| [RECOMMENDED] Trava 500/300 ms nos ACs | AC-22 e AC-33 declaram a trava (zerada no teste, ou confirmar depois de 500/300 ms). |

Em aberto (não escolhidas): E/Espaço digitando ao entrar no Texto; Sem foco × Pausa; Shift "um bind só" × tecla física; texto da OQ 2; Depends On e l. 155 do índice; OQ 8 (RNG); as 6 recomendadas de 2026-11-05; advisories. Fora deste GDD: a Cena 3/4 deve listar o Input em "Depende de" (Suave) e tirar "posição da câmera para o limiar do mouse" da linha do Input em Interactions.
- Depois, na mesma sessão (decisão do usuário): a Cena 3/4 lista o Input em "Depende de" (Suave, por contrato) e corrigiu a linha do Input em Interactions; o índice ganhou o ciclo Input ↔ Cena 3/4 em Circular Dependencies e Depends On na linha 5. A nota de ciclo deste GDD foi atualizada.

## Revisão aplicada — 2026-11-06 (a partir de `design/gdd/gdd-cross-review-2026-11-06.md`; decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Tela de erros sem `InputTuning` (S-B1) | R12, "Sem catálogo": em Falhou, só entradas digitais (teclas, cliques, D-pad, botões); analógicos, gatilhos e troca de dispositivo pelo mouse ignorados. O `InputTuning` é re-injetado a cada entrada em Pronto. Dependencies ajustada. AC-38 novo. |
| Raio da mira inclusivo × cânone `d < 900` (C-W10) | Mantido inclusivo, agora declarado como desvio deliberado em R5 e F4. |
| `ze` fora da R12 (C-I4) | R12 lista `zm` 0,2 e `ze` 0,05. |

Em aberto: os achados da 3ª re-review que não eram deste cross-review seguem como estavam no log.

## Review — 2026-11-06 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 0 | Recommended: 9
Summary: 4ª re-review, independente, em sessão nova. As duas últimas revisões aplicadas conferem: a amostra de 8 campos e a consulta de cursor batem com a Cena 3/4 (F2, R9, F6, Interactions, "Depende de"); no Texto o hover não move o foco e o clique fora vale como Esc (R9, R10, States, AC-36); a trava de 500/300 ms está nos AC-22/33; a R12 "Sem catálogo" com o AC-38 resolve o S-B1 e bate com o Conteúdo (Edge Cases › Recarga, UI da tela de erros, AC-51); o raio inclusivo está declarado como desvio em R5 e F4 (cânone `input.ts:181`, `d < 900`, conferido); a R12 lista `ze` 0,05. 0 conflitos com o registro (`unit_to_px` 1,5, `input_buffer_steps` 10, `tick_rate` 60); F1–F5 e AC-15–17 recalculados. Nenhum bloqueante novo; os novos achados são de borda do caso "Sem catálogo" e de terminologia.
Prior verdict resolved: Yes
Findings:
- [RECOMMENDED] Detailed Design (R12 Sem catálogo) × R5/AC-02: "a mira não existe" contradiz "a mira nunca sai com comprimento zero" e "toda amostra tem |mirar| = 1". Dizer o que a amostra leva em Falhou (por exemplo, `mirar` (0, −1), `automatica`, intensidade 0).
- [RECOMMENDED] Detailed Design (R12 Sem catálogo) × R8: um gatilho pode ser remapeado como bind de `ui_aceitar`/`ui_voltar` no gamepad; em Falhou os gatilhos são ignorados, e quem só usa gamepad não aciona Sair. Proibir gatilho como único bind de `ui_*` ou usar os padrões de `ui_*` em Falhou.
- [RECOMMENDED] Detailed Design (R12 Sem catálogo) + Dependencies: depois de uma recarga em debug que termina em Falhou, o Input já tem o `InputTuning` anterior; falta o contrato de descarte (o carregador injeta "sem Tuning" ao entrar em Falhou?). O mesmo vale para o estado do Input durante Carregando/Validando na inicialização.
- [RECOMMENDED] R5 × Edge Cases × F5: "px de janela" (R5, consulta de cursor; Cena F6 usa `m_janela`) × "coordenadas de tela" (Edge Cases, cursor fora da janela) × "px de tela" (F5). Unificar o termo; ligado ao `L_mouse` aberto desde 2026-11-05.
- [RECOMMENDED] (abertas da 3ª re-review) E/Espaço digitando ao entrar no Texto; Sem foco × Pausa; Shift "um bind só" × tecla física; OQ 2 ainda diz "antes de escrever o AC-33"; OQ 8 (RNG l. 617 "usável por teclado e gamepad").
- [RECOMMENDED] (abertas desde 2026-11-05) captura do remapeamento (o clique em "Cancelar" é uma entrada válida do dispositivo teclado/mouse e seria atribuído; perda de foco/desconexão; Start durante a captura do teclado); `zm + ze ≥ 1` inalcançável com as faixas e AC-05 fora da faixa; quando um passo "é de hitstop"; teclado vence o analógico sem rótulo de desvio; `L_mouse` em px de tela × DPI; AC-18 sem o buffer esperado ao fim do passo.
- [RECOMMENDED] Índice: Depends On da linha 4 sem IA (contrato) e Save e perfil; l. 155 ainda diz "suave: Conteúdo, Cena 3/4".
- [RECOMMENDED] Dependencies/Edge Cases (R8): adicionar a `pausar` uma tecla já usada por outra ação do mesmo contexto — como `pausar` nunca troca, é recusa? Com qual mensagem?
- [RECOMMENDED] Edge Cases: gamepad ativo desconectado durante Texto ou Remapeando não está coberto (só Jogo, Bênção e Menu).
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes; R12 sem o valor de `L_mouse` (4); tempos de 1 s/5 s da captura fora do `InputTuning`; conceito §3 (l. 64) "gamepad parcial"; `tick_rate` sem Input em `referenced_by`; States (Menu) não cita a tela de erros do catálogo em "Entra quando"; Interactions (Cena 3/4) não lista `mirar`, que a Cena F2 usa como direção no analógico; F4 ignora d = 0 (o cânone não), sem rótulo; Cross-References do Conteúdo sem Edge Cases › Recarga e a UI da tela de erros.
Nota: o cabeçalho do GDD (Status) foi atualizado depois da leitura e antes do hash; o hash cobre esse cabeçalho e nenhuma outra mudança.
Reviewed-Content-Hash: design/gdd/input-e-controle.md 8dbd90ae9badf66cbb9401c656dc54c289652f08
Reviewed-Content-Hash: design/registry/entities.yaml 03b431a3014ea0ed34194a06bdc78843376f3fc0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md b35f1cdb0bdb61bc91c4795128b4f953cfe987ba
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md da66e0fd85eb512cfa1bb51b2d6d82794d04e263
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-06.md 03a2b0f5830d1e46b0871abbb214bdc5a73185cb
