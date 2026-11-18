# Requisitos de Acessibilidade — Khaeros

> **Status**: Approved
> **Author**: ux-designer (agente)
> **Last Updated**: 2026-11-18
> **Accessibility Tier Target**: **Standard**, com três itens elevados de Comprehensive/Exemplary e dois desvios documentados (ver "Compromisso deste projeto")
> **Platform(s)**: PC (Windows), teclado/mouse e gamepad
> **External Standards Targeted**:
> - WCAG 2.1 Level AA (contraste de texto e limite de flashes, SC 1.4.3 e 2.3.1), aplicado à UI do jogo
> - Game Accessibility Guidelines (nível básico e intermediário) como checklist de referência
> - AbleGamers CVAA Guidelines: N/A no MVP (sem chat, voz ou mensagens; o co-op online é pós-MVP e reabre esta linha)
> - Xbox Accessibility Guidelines (XAG): Partial (só como referência de design, sem certificação)
> - PlayStation Accessibility: No · Apple/Google: N/A
> **Accessibility Consultant**: None engaged
> **Linked Documents**: `design/gdd/systems-index.md`, `design/ux/interaction-patterns.md`, `design/art/art-bible.md` §4.7, §7.6, §7.7, §7.9, `docs/architecture/adr-0012-ui-e-hud.md`, `docs/architecture/adr-0013-persistencia-do-mvp.md` §8, `docs/architecture/adr-0016-audio-ganchos-e-vozes.md`
> **Template**: Accessibility Requirements

> **Por que este documento existe.** As notas de acessibilidade de cada tela ficam
> nos GDDs e nas specs de UX. Aqui ficam os compromissos do projeto inteiro, a
> matriz por sistema, o plano de testes e o histórico de auditoria. Se uma feature
> conflitar com um compromisso daqui, este documento vence: muda-se a feature, não o
> compromisso, salvo revisão formal aprovada pelo producer.
>
> **Relação com o sistema nº 33 "Acessibilidade e opções" (Vertical Slice).** Este
> documento é o padrão; o GDD nº 33, quando for escrito, é o sistema que implementa
> a tela de opções e decide os nomes finais de chave. Até lá, as chaves do ADR-0013
> §8 valem como provisórias. As pendências que os GDDs empurraram para "o GDD de
> Acessibilidade" (OQ 3 do Feedback, OQ 8 do Pipeline, OQ 3 do Input) estão
> resolvidas aqui como proposta e repetidas em Open Questions.

---

## Accessibility Tier Definition

### Tier Definitions

| Tier | Core Commitment | Typical Effort |
|------|----------------|----------------|
| **Basic** | Texto crítico legível; nada depende só de cor; volumes independentes; sem risco fotossensível. | Baixo |
| **Standard** | Basic + remapeamento completo, legendas com falante, texto ajustável, ao menos um modo de daltonismo, nenhuma entrada cronometrada sem extensão. | Médio |
| **Comprehensive** | Standard + leitor de tela nos menus, áudio mono, assistências de dificuldade, reposicionar HUD, redução de movimento, indicador visual para todo áudio crítico. | Alto |
| **Exemplary** | Comprehensive + legendas totalmente customizáveis, alto contraste, ferramentas de carga cognitiva, alternativa háptica, auditoria externa. | Muito alto |

### This Project's Commitment

**Target Tier**: **Standard**

**Rationale**: Khaeros é um roguelite de ação em tempo real: a barreira principal do
gênero é motora e de tempo de reação (esquivar telégrafos de 0,43 a 0,7 s), seguida de
leitura visual sob multidão. A Art Bible já resolveu boa parte do visual por
construção (forma primeiro, escada de valor L*, teste em cinza e nos 3 simuladores,
§4.7) e definiu 12 opções visuais para o MVP (§7.9), mais remapeamento completo e
menus sem mouse. Isso põe o projeto acima de Basic sem esforço extra, e o
remapeamento já está desenhado (Input R8). Comprehensive exigiria leitor de tela
(AccessKit, com propriedades NOT SOURCEABLE no ADR-0012 E5) e assistências de
dificuldade que mexem no pilar de combate justo; o custo não cabe numa equipe indie
antes da fatia vertical. Cair para Basic jogaria fora o que já está pago nos GDDs.

**Features explicitly in scope (beyond tier baseline)**:
- **Redução de movimento** (Comprehensive): já decidida (Art Bible §7.9 nº 5; ADR-0012 §6; ADR-0013 §8). Barata porque todas as animações de UI passam por `RelogioDeInterface`.
- **Alto contraste da UI** (Exemplary): já decidido (§7.9 nº 10; HUD R13; Tela R14). Custo baixo: troca de tema.
- **Indicador visual para todo som de jogo** (Comprehensive): garantido por construção. Todo som de jogo do MVP acompanha um sinal visual primário; o som nunca é o único canal (ver Auditory).
- **Intensidade do telégrafo** (contorno 4 → 6 px): opção que a Art Bible marcava como "futura" entra no MVP porque o Pipeline já suporta `contorno_telegrafo_alto_px` e o ADR-0013 §8 já reserva a chave.
- **Fonte de leitura Atkinson Hyperlegible Next** (§7.9 nº 12) e **tamanho da mira** (nº 11).

**Features explicitly out of scope (desvios do Standard)**:
- **Modos de daltonismo (filtros)**: substituídos por independência de cor por construção (Art Bible §7.9 "fora do MVP, de propósito"). O requisito do Standard ("ao menos um modo") fica cumprido pelo objetivo que ele protege, não pela forma; o teste é a passagem nos 3 simuladores. Ver Known Intentional Limitations.
- **Extensão de janelas de tempo do combate**: o combate não tem QTE nem ritmo, mas os telégrafos exigem reação. Nenhum multiplicador de velocidade do jogo no MVP. Ver Known Intentional Limitations.

---

## Visual Accessibility

Medidas em 1920 × 1080 a 100% de escala de UI, como no HUD R13.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Escala de UI (§7.9 nº 1) | Standard | HUD, Tela de bênção, pausa, menus, telas finais | Designed (ADR-0012 §8) | Valores 85 / 100 / 125 / 150%; padrão 100% em ≥ 1080p e 125% abaixo. Margem segura de 48 px fora da escala. Layout cabe a 150% em 1280 × 720. Cartas: `s = min(escala_ui, 1824 / largura(n))`. Chave `[ui] escala`. Escala única para HUD e menus no MVP (ver Decisões). |
| Tamanho mínimo de texto — menus e cartas | Standard | Todas as telas | Not Started | **Proposta:** ≥ 22 px de corpo a 100% (≥ 18,7 px a 85%). O "piso de legibilidade" da Tela (Edge Cases) não pode cair abaixo disso. A Art Bible não fixa px de corpo; confirmar com o art-director. |
| Tamanho mínimo de texto — HUD crítico | Standard | Número de Vida, cargas, saldo, prompt | Not Started | **Proposta:** ≥ 20 px a 100%. Elementos não críticos (seed na pausa) podem ser menores, nunca abaixo de 16 px. |
| Legendas (§7.9 nº 2) | Standard | Voz dos Mestres e fala do Campus | N/A no MVP | Não há fala nem diálogo no MVP (Mestres, Diálogo e Campus são Vertical Slice no índice). A opção fica especificada pela Art Bible: ligada por padrão, 24/32/40 px, fundo 0–100% (padrão 75%), falante pelo nome, nunca pela cor. Reabre na fatia vertical. |
| Contraste de texto da UI | Standard | Todo texto | Not Started | ≥ 4,5:1 para corpo, ≥ 3:1 para texto ≥ 24 px ou ≥ 18,7 px negrito (WCAG AA). Osso sobre tinta nos painéis ≥ 92% deve passar com folga; medir nas cores finais. |
| Alto contraste (§7.9 nº 10) | Exemplary (elevado) | HUD, Tela de bênção, Bloco do Pacto, pausa, menus | Designed (HUD R13, Tela R14, ADR-0012 §11) | Painéis 100%, molduras sólidas de 3 px, raridade por contagem de linhas + palavra, osso puro sobre tinta pura; as formas continuam. Chave `[ui] alto_contraste`. Contorno de 3 px nos chevrons da esquiva (Movimento AC1). |
| Independência de cor | Basic | Todo o jogo | Designed por construção | Ver auditoria abaixo. Toda informação lê por forma e valor (Art Bible §4.7). |
| Filtros de daltonismo | Standard | — | Out of scope | Desvio documentado. Substituído pelo teste dos 3 simuladores e cinza em toda captura [V]. |
| Vida colorida (§7.9 nº 9) | — | HUD | Designed (HUD R13) | Opcional, desligada: o osso vira vermelho-tinta. É reforço, nunca o único canal (os segmentos continuam). |
| Número de Vida (§7.9 nº 8) | — | HUD | Designed | Ligado por padrão. Chave `[ui] numero_vida`. |
| Vinheta de Vida baixa (§7.9 nº 6) | — | Camada Pós | Designed (HUD F3; Pipeline) | 0–100%, padrão 100%. Estática na Redução de movimento. Chave `[ui] vinheta`. |
| Reduzir flashes (§7.9 nº 4) | Basic | Impact frame, flash de inimigo, flash da Tela de bênção, disparo de telégrafo | Designed (Pipeline R11/F6; Feedback R7; Tela R14) | O limitador de **3 flashes/s vale sempre** (constante, não é botão). A opção troca o impact frame pelo `reduzido`, baixa o flash de inimigo e tira o flash do traço dourado e da rachadura da Tela. Chave `[acessibilidade] reduzir_flashes`. |
| Limiar de área do flash | Basic | Pipeline | Proposto aqui | Confirma a OQ 8 do Pipeline: flash que cobre ≥ 11% da área da tela conta como "flash geral" para o limite de 3/s. O critério WCAG 2.3.1 mede área em graus do campo visual, que depende do monitor e da distância; 11% fica como valor do projeto, a recalibrar se o accessibility-specialist medir outra coisa. Ver Decisões. |
| Aviso de fotossensibilidade | Basic | 1ª execução | Not Started | Tela de aviso na primeira execução (chave `MENU_AVISO_FOTOSSENSIBILIDADE`), com atalho direto para "Reduzir flashes". Fica nas Opções depois. |
| Tremor de câmera (§7.9 nº 3) | Standard | Cena F5 | Designed | 0–100%, passos de 10, padrão 100%. A 0% sobram hitstop, estrela e flash (Feedback R7). Chave `[acessibilidade] tremor_camera`. |
| Redução de movimento (§7.9 nº 5) | Comprehensive (elevado) | UI, câmera, números, letreiros | Designed (ADR-0012 §6; Feedback R7) | Sem zoom de impacto; transições de UI viram fade ≤ 300 ms; foco da carta a 106% em corte seco (continua, é informação); números e letreiros só com fade; vinheta estática. **O hitstop continua** (é tempo de jogo; quem o encurta é a opção própria). Não muda travas nem foco. Chave `[acessibilidade] reduzir_movimento`. |
| Números de dano (§7.9 nº 7) | — | Pool de números | Designed (ADR-0011 §8) | Ligado / reduzido (só crítico e total) / desligado. Chave `[acessibilidade] numeros_dano`. |
| Intensidade do telégrafo | Standard (elevado) | Todos os telégrafos | Designed (Pipeline `tel_sdf`; Telégrafos UI Req.) | Contorno de 4 → 6 px; forma e valor sempre ligados. Chave `[acessibilidade] telegrafo_alto`. Padrão desligado. |
| Tamanho da mira (§7.9 nº 11) | — | Mira do mouse e do analógico | Not Started | 1× / 1,5× / 2×, padrão 1×. Dono: GDD nº 33 (Input linha 380). |
| Fonte de leitura (§7.9 nº 12) | — | Todo texto de UI | Not Started | Alegreya Sans (padrão) / Atkinson Hyperlegible Next. Trocar a fonte não pode estourar nenhum rótulo a 150% (testar o maior idioma). |
| Brilho/gama | Basic | Global | Out of scope MVP | O jogo é de tinta e papel com escada de L* fixa; um controle de gama quebraria a leitura por valor. Ver Known Intentional Limitations. |

### Color-as-Only-Indicator Audit

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| Telégrafos | Cor por tipo de ataque | Área e momento do perigo | Forma da área, preenchimento que cresce com `p`, contorno 4/6 px, escada de valor (Telégrafos; Art Bible §4.5) | Resolved by design; validar AC-TG-22 |
| Raridade da bênção | Cor do ornamento | Comum / Rara / Lendária | Ornamento + palavra; no alto contraste, contagem de linhas (Tela R14) | Resolved by design |
| Vida do jogador | Osso (vermelho-tinta opcional) | Vida atual | Segmentos + número de Vida (HUD R13) | Resolved by design |
| Fluxo e Selo | Dourado | Fluxo e prontidão do Selo | Nível + entalhe; Em recarga tem precedência e forma própria (HUD R13; Selo) | Resolved by design |
| Cargas da esquiva | Preenchimento | Cargas disponíveis | Preenchido × contorno (HUD R13) | Resolved by design |
| Elite | Tom | Inimigo elite | Coroa + raio × 1,2 (IA; AC-IA-26) | Resolved by design |
| Efeitos de status | Cor do sinal | Qual status está ativo | Forma do sinal (Efeitos de status, linha 554) | Resolved by design |
| Portas e recompensas | Cor do ícone | Tipo de recompensa | Forma do ícone + texto; moldura e posição da porta (Portas; Câmaras) | Resolved by design; validar AC-PR-21, AC-CO-25 |
| Bloco do Pacto | Estado da Maldição | Em campo / reserva / exausta / troca pronta | Silhueta, marca de Saltando, anel de recuperação, Selo cheio (ADR-0012 §10) | Resolved by design |
| Botão desabilitado (trocar ofertas, abandonar na Bênção, reset em Sem gravação) | Esmaecido | Indisponível | Ícone riscado + "0" ou texto do motivo (Art Bible §7.5; ADR-0012 §7, §10) | Resolved by design |

---

## Motor Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Remapeamento completo | Standard | Toda ação da R1 exceto `debug_*`, teclado e gamepad separados | Designed (Input R8; ADR-0006 §6) | Até 3 binds por ação por dispositivo; teclado por direção de `mover`; gamepad com "trocar analógicos"; bind por tecla física; conflito no mesmo contexto troca de lugar (recusa se alguma ação ficar sem primário); Esc e Start não saem de `pausar`; "Restaurar padrão" por dispositivo; `user://input_binds.cfg`. Enter/Esc do contexto Texto são fixos. |
| Troca de dispositivo a qualquer momento | Standard | PC | Designed (Input "dispositivo ativo"; ADR-0012 §9) | O último dispositivo com entrada significativa vira o ativo; os prompts trocam no passo seguinte (AC-HD-18). |
| Menus sem mouse | Standard | Todas as telas do MVP | Designed (Input R9; ADR-0012 §3) | Foco inicial e navegação completa por `ui_*` em menu principal, pausa, bênção, escolha de arma, escolha do pacto, consentimento, morte, vitória, opções/remapeamento, erros do catálogo, avisos e debug. |
| Jogo sem teclado (só gamepad) e sem gamepad (só teclado+mouse) | Standard | Todo o jogo | Designed | Os dois dispositivos são jogáveis por inteiro (Input §Overview). |
| Ações seguradas | Standard | Todas | Designed | O combate do MVP **não tem ação segurada**: Selo e Esquiva são "só no buffer", segurar não repete (Input). Única exceção é cancelar a captura de remapeamento segurando Esc/Start por 1 s, que tem duas alternativas sem segurar (botão "Cancelar" e 5 s sem entrada). |
| Entrada rápida repetida | Standard | Ataque básico | Designed | Nenhuma ação pede > 3 toques/s sustentados por obrigação. **Proposta:** "segurar ataque repete o ataque básico" como opção de conforto, desligada por padrão; precisa do aval do game-designer porque mexe no buffer. Open Question. |
| Zona morta ajustável | Standard | Analógicos | Proposto aqui | Resolve a OQ 3 do Input: zona morta interna 0,05–0,40 em passos de 0,05 (padrão 0,20 = cânone `zm`), por analógico. Corrige drift (Input Edge Cases). |
| Encurtar o hitstop | — | Orquestrador (ADR-0001) | Proposto aqui | Resolve a OQ 3 do Feedback: `hitstop_mult` ∈ {1,0; 0,5; 0,25}, padrão 1,0. Atende jogadores com desconforto ao congelamento e quem perde o ritmo por ele. Não remove o hitstop (o Combate o usa como leitura). Chave `[acessibilidade] hitstop_mult`. |
| Janelas de tempo / velocidade do jogo | Standard | Telégrafos, esquiva | Out of scope MVP | Desvio documentado (ver Known Intentional Limitations). Mitigações no MVP: telégrafo de 6 px, travas de UI generosas, pausa em todo estado de jogo. |
| Travas contra confirmação acidental | Standard | Tela de bênção, consentimento, escolhas | Designed (Tela R6–R9) | 500 ms após assentar, 300 ms após trocar ou voltar da pausa; botão segurado ao abrir não conta; clique fora do foco só move o foco. |
| Mira assistida | Standard | Mira por analógico | Not Started | O Input já usa `intensidade_mira` após a zona morta. Mira assistida configurável fica para o GDD nº 33 decidir; no MVP, só o tamanho da mira. Open Question. |
| Reposicionar HUD | Comprehensive | — | Out of scope | Grupos ancorados nos cantos; a escala cobre o principal. |
| Modo uma mão | — | — | Not committed | O remapeamento com 3 binds permite montar layout de uma mão no teclado; não há modo dedicado. Auditar no playtest motor. |

---

## Cognitive Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Pausar em qualquer estado | Basic | Jogo e Bênção | Designed (ADR-0012 §7) | Pausa abre em `JOGO` e `BENCAO`. Exceções justificadas: (1) durante o hitstop o `pausar` é descartado (Run), mas o hitstop dura ≤ poucos décimos e a perda de foco pausa mesmo assim (ADR-0012 §4); (2) na Transição o pedido é guardado para o 1º passo de Jogo. Perder o foco da janela em `JOGO` pausa. |
| O mundo congela nas telas de decisão | Standard | Bênção, consentimento do pacto, escolha da Maldição-chefe | Designed (estado Bênção do ADR-0001) | Nenhuma decisão de tela acontece com o combate correndo. Sem limite de tempo para escolher. |
| Nada some sozinho com informação acionável | Standard | Avisos e mensagens | Designed | Avisos `PERFIL_*` e `INPUT_*` exigem confirmação (padrão "Aviso único" da biblioteca). Só confirmações discretas (`SEED_COPIADA`, `PERSIST_FALHA_GRAVAR`) somem sozinhas, e ficam ≥ 3 s; nenhuma pede ação. |
| Raridade e preço legíveis antes de confirmar | Standard | Tela de bênção | Designed (Tela R7) | O preço aparece na carta; `preco_revelado` só anima. |
| Causa da morte | Standard | Resumo de morte | Designed (Art Bible §7.5) | Ícone do inimigo + nome do ataque. |
| Persistência de tutorial | Standard | — | Not Started | O MVP não tem tutorial formal. Quando houver (fatia vertical), toda dica dispensada fica recuperável em "Ajuda" na pausa. A pausa já lista as bênçãos ativas com texto completo (Art Bible §7.5). |
| Objetivo claro | Standard | Câmaras | Designed | Objetivo único e visível: limpar a onda; portas abrem com moldura e posição distintas; contagem de inimigos no HUD. |
| Dificuldade granular | Standard | — | Out of scope MVP | O pilar é combate justo e legível; o MVP não tem seletor. Reavaliar com dados de telemetria local (Open Question). |
| Carga cognitiva por sistema | Comprehensive | — | Parcial | Registrada na matriz abaixo para os sistemas de alta carga (Combate + Telégrafos + Pacto). |

---

## Auditory Accessibility

**Contexto.** O som do MVP **não é posicional** (ADR-0016: `AudioStreamPlayer`, sem
espacialização). Consequência para acessibilidade: nenhum som carrega direção, então
não há informação direcional que se perca para quem não ouve ou ouve de um lado só, e
**indicadores de borda de tela para direção não são necessários no MVP**. A regra que
vale é mais forte: **nenhum som de jogo é o único canal de uma informação.** O MVP não
tem fala.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Legendas de fala | Basic | Fala | N/A no MVP | Sem fala no MVP. Ver Visual / Legendas. |
| Volumes independentes | Basic | Barramentos Master, Música, Efeitos, Interface (ADR-0016) | Designed | 0–100%, chave `[audio]`; em 0 o barramento fica mudo. **Proposta:** padrão 80% em todos. Expostos nas Opções e na pausa. |
| Indicador visual para todo som de jogo | Comprehensive (elevado) | Ver auditoria | Designed por construção | Cada linha da auditoria tem sinal visual primário. |
| Áudio mono | Comprehensive | — | Satisfeito por construção | Som não posicional. **Requisito:** os SFX de jogo são importados mono ou centrados, sem pan embutido; assim uma opção mono é desnecessária no MVP. Se o co-op ou o som posicional entrarem, a opção volta a ser exigida. |
| Captions de SFX | Comprehensive | — | Não exigido | Nenhum SFX carrega informação que falte no visual (auditoria abaixo). |
| Compatibilidade com aparelho auditivo | Standard | Tom de aviso do telégrafo, deixa de Vida baixa | Not Started | Nenhum som crítico só acima de 4 kHz; como todo som tem par visual, o risco é de conforto, não de informação. Auditar na fase de asset. |

### Gameplay-Critical SFX Audit

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| Tom de aviso do telégrafo (sobe com `p`) | Perigo se formando e quanto falta | Preenchimento que cresce com `p`; contorno; forma da área (Telégrafos) | Não | Resolved by design |
| Estalo do disparo do telégrafo | Golpe saiu | Fim do preenchimento + rachadura; impact frame (Telégrafos; Feedback) | Não | Resolved by design |
| Deixa de Vida baixa | Vida crítica | Vinheta + moldura partida (HUD); funciona com vinheta a 0% pela moldura | Não | Resolved by design |
| Selo pronto / Fluxo cheio | Pode usar o Selo | Selo cheio e entalhe (HUD R13) | Não | Resolved by design |
| Esquiva sem carga | Ação recusada | Tremor dos chevrons (HUD) | Não | Resolved by design |
| Troca indisponível (Pacto) | Troca recusada | Sacudida do Bloco do Pacto (ADR-0012 §10) | Não | Resolved by design |
| Maldição exausta / pronta | Estado da reserva | Anel de recuperação; preenchimento de 0,25 s | Não | Resolved by design |
| Fase do chefe / subjugado | Mudança de fase | Barra de chefe (fase e estado) + animação | Não | Resolved by design |
| Onda limpa / porta aberta | Pode avançar | Portas se abrem com moldura; contagem de inimigos zera | Não | Resolved by design |
| Confirmação de UI | Escolha registrada | Estado Confirmando da carta / foco | Não | Resolved by design |

---

## Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Steam (PC) | Steam Input | Remapeamento de sistema do gamepad | Not Started | O remapeamento do jogo continua obrigatório (teclado e gamepad). |
| PC (leitor de tela) | AccessKit (Godot 4.5+) / NVDA / Narrador | Nenhuma no MVP | Out of scope | O ADR-0012 mantém o foco de teclado da engine espelhando o `ModeloDeFoco` com `grab_focus()`, o que deixa a base pronta. Propriedades além de `accessibility_live` são **NOT SOURCEABLE** (ADR-0012 E5): nada aqui afirma suporte. |
| Consoles / mobile | — | — | N/A | Fora das plataformas. |

---

## Per-Feature Accessibility Matrix

Sistemas MVP do `systems-index.md` com interface ou leitura pelo jogador. Sistemas
puramente internos (Conteúdo, Modificadores, RNG, Save sem tela, Telemetria sem tela)
não têm linha; a Telemetria aparece pelo aviso e pelas opções.

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| Input e controle | Prompts por dispositivo | Remapeamento, zona morta, sem holds | Conflito de binds explicado | — | Sim (zona morta proposta aqui) | INPUT_ACAO_NOVA "[a confirmar]" no GDD |
| Cena 3/4 e câmera | Tremor, zoom | — | — | — | Sim | Opções 3 e 5 |
| Pipeline visual | Flashes, contraste, telégrafo 6 px | — | — | — | Sim | AC-PV-51 bloqueado até E2 |
| Movimento e esquiva | Chevrons por forma | Esquiva só no buffer | — | — | Sim | Contorno 3 px no alto contraste |
| Combate núcleo | Impact frame, números | Ritmo de reação | Alta (golpe + telégrafo + Selo) | — | Parcial | AC-79 destravado por este doc; hitstop_mult proposto |
| Telégrafos | Forma e valor | Janela 0,43–0,7 s | Multidão (até 9) | Tom com par visual | Parcial | Desvio de tempo documentado |
| Selo e Fluxo | Nível e entalhe | — | Prontidão | — | Sim | Pendente: "número de Fluxo" fora do §7.9 (Selo, nota 2026-11-11) |
| Efeitos de status | Forma do sinal | — | Vários status | — | Sim | |
| IA e elites / Chefes | Coroa, raio, barra de chefe | — | Fases do chefe | — | Sim | |
| Maldições / Vínculo e pactos | Bloco por silhueta | Troca é um toque | Alta (2 aliados + troca) | — | Sim | Consentimento no estado Bênção |
| Câmaras / Portas | Moldura, posição, ícone por forma | — | Objetivo único | — | Sim | |
| Bênçãos / Tela de bênção | Raridade por ornamento e palavra; flash | Travas; teclas 1–3 só movem foco | Preço visível | — | Sim | |
| HUD | Escala, alto contraste, Vida | — | Mínimo por design | Deixa de Vida baixa | Sim | |
| Feedback de combate | Flashes, números, tremor | — | — | — | Sim | Não aplica opções (R7) |
| Save e perfil (avisos) | Texto legível | Navegável sem mouse | Confirmação dupla no reset | — | Sim | |
| Telemetria local | — | — | Aviso único, base legal | — | Parcial | Texto legal pendente (Telemetria OQ 5) |

---

## Accessibility Test Plan

Os critérios são verificáveis e se somam aos AC já escritos nos GDDs (AC-TB-22/33,
AC-PV-51/76, AC-TG-22, AC-IA-26, AC-PR-21, AC-CO-25, AC-79 do Combate). Evidência
[V] vai para `production/qa/evidence/`.

| ID | Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|----|---------|------------|------------|--------------|-------------|--------|
| AR-01 | Escala de UI | Captura | Cada tela do MVP a 85% e 150%, em 1920×1080 e 1280×720 | Nenhum texto cortado ou sobreposto; margem de 48 px constante; grupo inferior do HUD cabe a 150% em 1280×720 | qa-tester | Not Started |
| AR-02 | Tamanho de texto | Medição em captura a 100% | Corpo de menus e cartas; HUD crítico | Corpo ≥ 22 px; HUD crítico ≥ 20 px; nada abaixo de 16 px | ux-designer | Not Started |
| AR-03 | Contraste | Analisador sobre capturas, normal e alto contraste | Todo par texto/fundo | Corpo ≥ 4,5:1; texto grande ≥ 3:1; alto contraste ≥ 7:1 | ux-designer | Not Started |
| AR-04 | Independência de cor | Cinza + 3 simuladores | HUD em combate, Tela de bênção, multidão de telégrafos, portas, elite, Bloco do Pacto | Toda linha da auditoria de cor é distinguível sem cor | ux-designer | Not Started |
| AR-05 | Limite de flashes | Unitário do limitador (lógica) + captura de 10 s no pior caso | Multidão de impactos com e sem "Reduzir flashes" | Nunca > 3 flashes gerais por segundo (área ≥ 11% da tela); com a opção, impact frame `reduzido` e Tela sem flash | qa-tester | Not Started |
| AR-06 | Redução de movimento | Manual + unitário do `RelogioDeInterface` | Todas as transições de UI, zoom, números, vinheta | Sem zoom; toda transição ≤ 300 ms ou corte seco; hitstop presente; travas e foco idênticos ao modo normal | qa-tester | Not Started |
| AR-07 | Tremor 0% | Manual | 3 câmaras de combate | Câmera sem deslocamento de impacto; hitstop, estrela e flash continuam | qa-tester | Not Started |
| AR-08 | Remapeamento | Manual | Remapear todas as ações para não padrão nos dois dispositivos; reiniciar; jogar uma run | Todas as ações funcionam; conflito troca ou recusa com mensagem; Esc/Start não saem de `pausar`; binds persistem | qa-tester | Not Started |
| AR-09 | Só teclado / só gamepad | Manual | Run completa sem tocar no outro dispositivo, incluindo todas as telas e avisos | Run concluída; toda tela tem foco inicial e alcança todo item | qa-tester | Not Started |
| AR-10 | Sem holds obrigatórios | Inspeção do mapa de ações | Lista de ações | Nenhuma ação de jogo exige segurar; cancelar captura tem 2 vias sem segurar | qa-tester | Not Started |
| AR-11 | Pausa | Manual + unitário de estado | Pausar em Jogo, Bênção, consentimento, Transição, hitstop; perder foco da janela | Pausa abre em Jogo e Bênção; hitstop descarta; Transição adia; perda de foco em Jogo pausa | qa-tester | Not Started |
| AR-12 | Som sem par visual | Jogar uma câmara com o Master em 0% | Combate com 6 inimigos, telégrafos, Vida baixa, Selo, troca | Nenhuma informação perdida; testador evita o golpe do Eco na mesma taxa (± 10 p.p.) que com som | producer | Not Started |
| AR-13 | Opções persistem e aplicam ao vivo | Manual | Mudar cada opção no meio da run e reiniciar | Vale a partir do passo seguinte (AC-PV-76); valores voltam após reiniciar; falha de gravação mostra `OPCOES_FALHA_GRAVAR` e a sessão segue | qa-tester | Not Started |
| AR-14 | Fonte Atkinson | Captura | Todas as telas a 150% | Nenhum rótulo estoura | qa-tester | Not Started |
| AR-15 | Playtest motor | Testadores com uma mão ou controle adaptado | Run com remapeamento livre | Registro qualitativo; entrada para a decisão de velocidade do jogo | producer | Not Started |

---

## Known Intentional Limitations

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| Filtros de daltonismo | Standard | Decisão da Art Bible §7.9: independência de cor por construção | Baixo, se AR-04 passar; médio se algum asset futuro furar a regra | AR-04 em toda captura [V]; regra de forma primeiro nos asset specs |
| Velocidade do jogo / janelas de reação maiores | Standard | Mexe no pilar de combate justo e nos números de reação (Telégrafos F6); exige decisão do game-designer | **Alto** para jogadores com reação lenta ou motor reduzido: o jogo pode ficar intransponível | Telégrafo 6 px, pausa ampla, hitstop encurtável; decidir com dados do AR-15 e da telemetria antes da fatia vertical |
| Leitor de tela | Comprehensive | AccessKit com API NOT SOURCEABLE além de `accessibility_live` | Médio para jogadores cegos, que já enfrentam a barreira do gênero | Foco de engine espelhado (base pronta) |
| Reposicionar HUD | Comprehensive | Custo de layout; HUD mínimo nos cantos | Baixo | Escala de UI |
| Brilho/gama | Basic | Quebra a escada de L* que carrega a leitura por valor | Baixo-médio em telas mal calibradas | Escada de valor com margem; reavaliar se playtest reclamar |
| Dificuldade granular | Standard | Pilar de combate legível; sem dados ainda | Médio | Telemetria local; reavaliar na fatia vertical |

---

## Audit History

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| 2026-11-16 | ux-designer (agente) | Revisão de documentos | GDDs MVP, Art Bible §7.9, ADR-0012/0013/0016 | Opções do §7.9 todas com dono e chave; zona morta, hitstop e limiar de flash estavam sem dono e foram propostos aqui; desvio de tempo de reação registrado | Rascunho |
| 2026-11-18 | ux-designer (agente) | Fechamento UX MVP (`/ux-review`) | 8 artefatos de `design/ux/`, Art Bible §7, 26 GDDs MVP | 100% das specs de UX do MVP (incluindo `tela-erros-do-catalogo.md`) e requisitos de acessibilidade revisados e aprovados | Approved |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ | Contraste (1.4.3) e flashes (2.3.1) |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Checklist por categoria e custo |
| Xbox Accessibility Guidelines | https://docs.microsoft.com/gaming/accessibility/guidelines | Referência de design |
| Coblis | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Simulação dos 3 tipos |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | Recrutamento para o AR-15 |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Velocidade do jogo (ex.: 70/85/100%) entra na fatia vertical? | game-designer + usuário | Antes da fatia vertical | Aberta; depende de AR-15 |
| "Segurar ataque repete" como opção de conforto | game-designer | Fatia vertical | Aberta |
| Px de corpo mínimo (22 px proposto) bate com a tipografia da Art Bible? | art-director | Antes da 1ª story de UI | Aberta |
| Escala separada para HUD e menus? | ux-designer + usuário | GDD nº 33 | MVP usa uma só (decisão do agente) |
| Mira assistida no analógico | game-designer | GDD nº 33 | Aberta |
| Tirar "número de Fluxo" das opções (não existe no §7.9) ou pedir ao art-director | art-director | Antes da story do HUD | Aberta (Selo, nota 2026-11-11) |
| `INPUT_ACAO_NOVA` uma vez por sessão "[a confirmar]" no Input | ux-designer | — | Proposta: confirmado, como aviso único na tela de remapeamento (interaction-patterns.md) |

---

## Decisões tomadas pelo agente (a revisar)

1. **Tier Standard**, com redução de movimento, alto contraste e indicador visual para todo som elevados, e dois desvios documentados (sem filtros de daltonismo; sem extensão de tempo de reação).
2. **Intensidade do telégrafo (6 px) entra no MVP**, embora a Art Bible a marcasse como futura, porque Pipeline e ADR-0013 já a suportam.
3. **Zona morta ajustável** 0,05–0,40 (padrão 0,20), resolvendo a OQ 3 do Input.
4. **`hitstop_mult` ∈ {1,0; 0,5; 0,25}**, resolvendo a OQ 3 do Feedback; o hitstop nunca chega a zero.
5. **Limiar de área do flash de 11% mantido** como valor do projeto; OQ 8 do Pipeline dada como confirmada, sujeita a medição do accessibility-specialist.
6. **Mínimos de texto propostos:** 22 px de corpo, 20 px no HUD crítico, 16 px absoluto, a 100% em 1080p.
7. **Áudio mono dispensado no MVP** porque o som não é posicional, com o requisito de SFX mono ou centrados.
8. **Legendas N/A no MVP** (sem fala); o §7.9 nº 2 fica especificado para a fatia vertical.
9. **Volumes com padrão de 80%**, também expostos na pausa.
10. **Aviso de fotossensibilidade na 1ª execução** com atalho para "Reduzir flashes".
11. **Uma escala de UI só** para HUD e menus no MVP.
12. **Brilho/gama fora** para proteger a escada de L*.
