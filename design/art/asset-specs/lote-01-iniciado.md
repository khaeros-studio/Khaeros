# Asset Specs — Lote 1: O Iniciado (Lâmina + Ressonância)

> **Fonte:** `design/art/art-bible.md` §3.3, §4.1/4.2, §5.1–5.5, §5.8, §8.1–8.7, §9.7; `design/gdd/game-concept.md` §6–8; `design/gdd/armas-das-doutrinas.md` (Pulso e Onda); `design/gdd/selo-e-fluxo.md`
> **Gerado:** 2026-11-10 · **Revisão:** lean (art-director, 1 passada por lote); technical-artist não consultado: limites de engine vêm da §8 do Art Bible e não foram revalidados
> **Status:** especificado e revisado (art-director, 8 correções aplicadas). **Ficha L0 aprovada pelo usuário em 2026-11-10: v03** (`assets/art/source/raw/chr_iniciado_lamina_ficha_raw_v03.jpg`, 2752×1536). Folhas de poses ainda não geradas.
> **Os prompts ficam em** `design/art/asset-specs/prompts/`. Ao salvar o bruto do Nano Banana, copie o `.prompt.md` de mesmo nome para `assets/art/source/raw/`, ao lado dele (§8.2).
> **Como gerar:** Gemini web → modelo **3.1 Pro** → ferramenta **Criar imagem** → proporção **16:9** → colar o prompt numa linha só → baixar com **"Baixar no tamanho original"** (sai JPEG 2752×1536; a prévia na tela é só 1376×768). O Flash-Lite reprovou (v01: texto embutido, grade, traço fino).

## 0. Design aprovado (ficha v03) — [PROPOSTA de arte aprovada pelo usuário; CD ainda não assinou]

A v02 passou no checklist técnico, mas o usuário a achou genérica ("quero algo único, que remeta ao universo de Khaeros"). A v03 acrescenta, dentro das regras da §5.2–5.3:
- gola alta e rígida até o queixo; **mantelete** curto sobre os dois ombros, com borda em osso;
- casaco em **4 painéis** que abrem em sino; a ponta de cada painel é o motivo da Doutrina (Lâmina: corte em diagonal; Ressonância: arco com linha dupla);
- fecho frontal com 5 presilhas de osso; cinto largo com fivela de osso, 2 bolsas e um estojo cilíndrico;
- luvas pretas sem dedos; **antebraços enfaixados em osso com respingos de tinta**;
- **emblema da Doutrina nas costas** e no pomo da arma (ícone da §3.3: Lâmina = círculo atravessado por diagonal; Ressonância = anéis concêntricos);
- cabelo prateado em mechas angulosas; botas com caneleira e ponteira em osso.

Tudo é simétrico (espelhamento da §5.8), menos o emblema, cuja diagonal inverte no espelho: aceito. **Correção já nos prompts das folhas:** na v03 o emblema parece o símbolo "Ø"; agora a diagonal é uma pincelada grossa que ultrapassa o círculo dos dois lados. **A conferir:** a v03 tem menos preto sólido que o pedido (~40%); os prompts das folhas reforçam as massas de preto. Os detalhes pequenos (presilhas, faixas) somem a 90 px; o sprite simplifica.

**Decisão do usuário (2026-11-11): o emblema das costas é uma peça separada do rig.** O Gemini desenhou o emblema como "Ø" três vezes, a última na L1 de costas v02. Por isso as folhas de costas saem com as **costas lisas**, e o emblema vira uma peça do rig (§5.8), pintada uma vez à mão no desenho da §3.3 e presa ao osso do tronco. O mesmo vale para a Ressonância (anéis). Isso também resolve a inversão no espelhamento: a peça pode ter uma versão espelhada própria.

## 1. Regras fixas do Iniciado (valem para todas as folhas)

| Item | Regra | Fonte |
|---|---|---|
| Cabelo | prateado claro `#C2C6CC` (L* ≈ 80), a maior massa clara, no topo | §5.2 |
| Casaco | escuro, longo até a panturrilha, barra em sino; tecido `#5C6678` (L* ≈ 43, faixa 40–50), sombras `#2B3240` (L* ≈ 21) | §5.2, §4.2 |
| Acentos | **só osso** `#CFC6B4`; nunca dourado nem magenta; motivo de barra = diagonais (Lâmina) | §5.2 |
| Proporção | ~6 cabeças no sprite; peso um pouco à frente | §5.2 |
| Pele | tom médio quente `#B98A6B` na folha-base (o tom é customizável só no retrato, §5.3); `G − max(R,B) ≤ 62` | §5.3, §8.5 |
| Contraste de valor | escuro com topo claro (inverso do Eco) | §5.2 |
| Traço | contorno externo ~16 px na fonte das folhas de poses (alvo 6 px em 2×), ~40 px nas fichas (corpo maior, ver §4); uniforme; interno 0,5–0,75× | §8.4 |
| Sombra | nenhuma no verde; a mancha de contato é do motor/pós-produção | §5.5, §8.7 |
| Luz | neutra; sem grading regional | §8.3 |

**Tamanho real da fonte:** o Gemini 3.1 Pro entrega **2752×1536** no download em tamanho original, perto dos 2816×1536 previstos. As grades da §3 ficam como estão (na 4×2 a célula tem 688×768; na 6×2, 458×768).
**Conta de escala (§8.4):** corpo-alvo em 2× = 180 px (90 px × 2). Nas folhas de poses o corpo fica com ~480 px na fonte (≥ 270 exigido) → `s ≈ 0,375`, traço na fonte ≈ 6 ÷ 0,375 = **16 px**. É o número que está nos prompts. Se a medida real sair diferente, recalcular `s = 180 ÷ altura_corpo_fonte` e o traço-alvo `6 ÷ s`; `s > 1` = regerar.

## 2. Exportado (todas as poses)

| Campo | Valor |
|---|---|
| Quadro | 160×160 px 1× → **320×320 px** arquivo 2× |
| Formato | PNG-32 RGBA, 8 bits, sRGB, alfa reto, sem metadados (§8.1) |
| Pivô | centro do apoio dos pés; margem transparente ≥ 4 px (§8.1) |
| Traço no arquivo | 6 px (faixa 5–7); variação ≤ 1 px entre poses de uma animação |
| Nome da pose | `chr_iniciado_<arma>_<acao>_<direcao>_<nn>_2x.png`; compartilhadas sem arma: `chr_iniciado_<acao>_<direcao>_<nn>_2x.png` |
| Ações | vocabulário fixo da §8.2: `idle run windup attack recover dash cast hurt death` (mapa abaixo) |
| Direções | **MVP: `frente34` e `costas34`** (decisão a confirmar, ver §6). `lado`, `frente`, `costas34`-espelho e demais ficam para depois do teste do rig |

**Mapa de ações (sem criar token novo na §8.2):**

| Animação | Token `<acao>` | Numeração |
|---|---|---|
| Golpes 1–3 do combo (Lâmina) | `windup` (preparo), `attack` (corte e continuação), `recover` (recuperação) | por golpe: g1 `01–05`, g2 `06–10`, g3 `11–16`, distribuídos entre os três tokens |
| Pulso (Ressonância) | `windup` / `attack` / `recover` | `01–06` |
| Especial (Investida, Onda) | `cast` | `01–10` / `01–08` |
| Selo | `cast` com variante `selo`: `chr_iniciado_selo_cast_<dir>_<nn>_2x.png` | `01–08` |
| Esquiva, corrida, dano, morte | `dash`, `run`, `hurt`, `death` | sequencial |

## 3. Folhas do lote (cada folha = um prompt, 2816×1536 px)

Grade em ordem de leitura. **Quadros-chave por direção:** os totais seguem a §5.8.

| # | Folha (prompt em `prompts/`) | Grade | Poses | Células |
|---|---|---|---|---|
| L0 | `chr_iniciado_lamina_ficha` | 4×1 | frente, lado, costas, detalhes (espada, rosto, barra) | 4 |
| L1 | `…_lamina_idledash_<dir>` | 6×2 | idle 6 (linha 1) + esquiva 6 (linha 2) | 12 |
| L2 | `…_lamina_corrida_<dir>` | 4×2 | corrida 8, arma em pose de carregar | 8 |
| L3 | `…_lamina_combo12_<dir>` | 5×2 | golpe 1 (5) + golpe 2 (5) | 10 |
| L4 | `…_lamina_combo3hurt_<dir>` | 4×2 | golpe 3 (6) + dano (2) | 8 |
| L5 | `…_lamina_especial_<dir>` | 5×2 | Investida: 10, com 1 pose de painel | 10 |
| L6 | `…_lamina_selo_<dir>` | 4×2 | Selo: gesto de mão, 8 | 8 |
| L7 | `…_lamina_morte_<dir>` | 5×2 | morte 10 | 10 |
| R0 | `chr_iniciado_ressonancia_ficha` | 4×1 | Iniciado com o foco (frente34 e costas34), foco isolado, detalhe do orbe | 4 |
| R1 | `…_ressonancia_idlepulso_<dir>` | 6×2 | idle 6 + Pulso 6 | 12 |
| R2 | `…_ressonancia_onda_<dir>` | 4×2 | Onda de Ressonância: 8, com 1 pose de painel | 8 |

`<dir>` = `frente34` ou `costas34`: são 20 prompts no total (L0 e R0 são únicos). **Ordem de geração sugerida:** L0 → aprovar a ficha → L1…L7 em `frente34` → só depois `costas34`, usando a `frente34` aprovada como entrada (mantém o mesmo casaco). R0 → R1, R2 depois que a Lâmina estiver aprovada.

**Animações compartilhadas** (corrida, esquiva, selo, dano, morte) saem **com a Lâmina na mão** por ser a arma do MVP; nas outras armas a peça da arma é trocada no rig (§5.8) e o ajuste de mão fica para o lote de armas.
**Smears, impactos e rastros não estão nestas folhas:** os prompts proíbem rastro, onda ou energia de propósito; são quadros-chave `vfx_` desenhados à parte (§5.8). A inversão de cor do dano (§5.5) e as imagens residuais da esquiva (osso tracejado) são do motor.
**Combo da Ressonância: pendência bloqueante.** A §5.8 pede 3 golpes × 4–6 = 14–18 quadros por arma; R1 só tem o Pulso (6). O conjunto mínimo da Ressonância fica **incompleto** até a aba de Design dizer se o Pulso tem combo; aí entra uma folha R3 com os golpes 2 e 3.
**Entrada de imagem:** as folhas da Lâmina usam a ficha L0; as da Ressonância usam a ficha **R0** (com o foco), nunca a L0, para o modelo não misturar as armas.
**Esquiva (L1):** o pico é pedido em diagonal de ~35°, não na horizontal, para caber na célula de 469 px.

## 4. Fichas (L0, R0): não exportadas

Referência e entrada de imagem para as folhas seguintes (arte própria: permitido pela §9.7 item 3). Dispensam corte; entram em `assets/art/source/raw/` e no master.
**O traço da ficha segue a escala dela:** o corpo ocupa ~85% da célula (~1300 px), então o prompt pede contorno de ~40 px (1300 × 16 ÷ 480). Assim a proporção traço/corpo é a mesma das folhas de poses, que herdam a ficha como entrada.

## 5. Checklist de aceite (§8.7), por folha

**Fundo e recorte**
- [ ] Fundo `#00FF00` chapado; sem gradiente, vinheta, papel ou moldura
- [ ] Sem sombra projetada nem elipse no verde; sem luz verde rebatida na figura
- [ ] Nenhum verde saturado na figura (`G − max(R,B) ≤ 62`)
- [ ] Sem fumaça, brilho, faísca nem rastro sobre verde
- [ ] Sem halo verde a 400% sobre fundo claro e escuro

**Folha e composição**
- [ ] Número de poses = a coluna "Células" (células vazias só com verde)
- [ ] Nenhuma pose toca a borda da célula (margem ≥ 5%); nada cortado, nem a ponta da arma
- [ ] Mesma escala e mesma linha de chão (altura varia ≤ 5%, salvo agachar/saltar/cair de propósito)
- [ ] Mesmo ângulo 3/4 em todas as poses da folha; direção conforme o nome do arquivo
- [ ] Corpo da pose ≥ 270 px na fonte

**Estilo e traço**
- [ ] Quadrinho: contorno preto fechado, cel de 2–3 tons, manchas de preto; sem pixel art, gradiente, 3D, brilho plástico ou foto
- [ ] Traço na faixa 5–7 px em 2× depois da reescala, com `s ≤ 1`, uniforme entre as poses
- [ ] Luz neutra, sem tom de região

**Leitura e cânone**
- [ ] Teste dos 48 px: a silhueta lê (cabelo claro no topo, casaco em sino, diagonal da espada)
- [ ] Silhueta da arma certa: Lâmina = diagonal fina; Ressonância = o orbe passa da cabeça
- [ ] Cabelo prateado; casaco escuro longo; acentos só em osso (nada dourado/magenta)
- [ ] Mesmo rosto, mão da arma (direita) e proporção da ficha
- [ ] Paleta e valor: personagem ≤ L* 82; nada com L* ≥ 88; verifica 8.5
- [ ] Teste de fundo: lê em cinza sobre chão (L* 22–38) e sobre parede texturizada
- [ ] Nenhum texto, número, assinatura ou marca d'água
- [ ] `.prompt.md` ao lado, sem nome de jogo, obra, estúdio ou artista, e sem imagem de terceiros como entrada

Resultados: **Aceita**, **Aceita com retoque** (≤ ~15 min no master) ou **Regerar**.

## 6. Decisões para o usuário

1. **Direções do MVP:** só `frente34` + `costas34` primeiro (recomendado: valida o rig com menos folhas) ou as 5 desenhadas desde já?
2. **Folhas compartilhadas com a Lâmina na mão** (como acima) ou sem arma, com a arma como peça de rig separada?
3. **Rosto e pele:** a folha usa um rosto neutro de pele média como base; as variações de retrato do protótipo viram os presets depois, no retrato (§5.3).

## 7. Ainda não verificado

- Ferramenta de checagem de paleta (§8.5) ainda não existe; a conferência de cor é visual até lá.
- Nenhum bruto foi gerado ainda; os números de traço e de escala só se confirmam na primeira folha real.

## 8. Revisão das imagens geradas (art-director, 2026-11-10)

| Imagem | Veredito | Retoques |
|---|---|---|
| Ficha v03 | Aceita com retoque | Repintar o emblema (lê como "Ø") com uma diagonal grossa que passe do círculo **antes** de usar a ficha nas folhas `costas34`; pomo sem emblema (menor) |
| L1 idle + esquiva | Aceita com retoque | Fumaça cinza acima da esquiva 5 → pintar `#00FF00`; esquiva 4 sem espada (a peça do rig cobre); ponta da espada da esquiva 3 invade a célula vizinha (recorte manual); idle 3 ~5% maior (normalizar) |
| L2 corrida (2ª tentativa) | Aceita com retoque para o rig, **só depois de conferir em 2752×1536** | Usar 1/7, 2/6, 4/8; descartar a 5; no rig, inclinar o tronco para a frente |

**Achado principal: traço fino demais.** O corpo saiu com ~650–700 px na fonte (não os ~480 previstos), então `s ≈ 0,26` e o traço-alvo na fonte seria ~23 px. O contorno real tem ~8–10 px, o que dá ~2–3 px em 2× (faixa 5–7). Saídas: engrossar o contorno no pós (dilatar o alfa em preto, igual em todas as poses; technical-artist) ou pedir o corpo menor na célula nas próximas folhas. Medir com régua antes de fechar.

**Teste dos 48 px:** cabelo e casaco leem; a diagonal da espada some sobre o casaco escuro → fio claro (osso, L* ≤ 82) na peça da espada do rig.

**Identidade:** forte (gola, mantelete, painéis em ponta, braços enfaixados). O que ainda a deixa genérica é o acabamento: pouco preto chapado. Se a L3 vier igual, pedir explicitamente "a face de sombra do casaco em preto chapado".

## 9. Revisão do lote (art-director, 2026-11-12) — revisão única, sem re-review

**Veredito: FECHAR COM RESSALVAS.** Nenhuma folha precisa ser gerada de novo; tudo se resolve no recorte ou no rig. As ressalvas:
1. A Ressonância fica incompleta até a aba de Design definir o combo (R3).
2. A barra da Ressonância precisa ser resolvida antes de exportar qualquer sprite dela.
3. Os retoques abaixo entram no recorte.

**Consistência a ~90 px:** a paleta, o rosto, o cabelo e a mão da arma estão sólidos nas 20 folhas. A escala e o traço variam de uma folha para outra, então o `s` precisa ser calculado por folha. Algumas poses das folhas de costas34 viram de frente: combo12 2, 3, 7 e 8; esquiva 3–4; especial 3; selo 5–6. Elas precisam ser marcadas no rig e testadas a 90 px; se o rosto "pular", troca-se a peça da cabeça pela de costas. **O que mais destoa é a barra:** a corrida, a esquiva, o selo, o dano e a morte saem com a barra da Lâmina, sem linha de osso, enquanto o idle, o Pulso e a Onda da Ressonância têm a linha dupla.

**Retoques antes de exportar, por prioridade:**
1. combo12 frente34, linha 2, pose 4: apagar o "Ø" do mantelete. Conferir também a marca na gola da golpe3dano frente34, pose 3.
2. golpe3dano costas34, pose 3: apagar o arco branco e repintar o mantelete, o cinto e o casaco por baixo. É o retoque mais caro.
3. Apagar os outros VFX:
   - arco da golpe3dano frente34, pose 3;
   - arco da selo frente34, pose 3, e riscos da selo costas34, pose 3;
   - poeira da especial, pose 7, em frente e costas;
   - faíscas da onda frente34, pose 5;
   - mancha cinza da idledash frente34, linha 2, pose 5.
4. Calcular o `s` de cada folha e engrossar o traço da corrida frente34 para 5–7 px.
5. Recortar contornando cada figura, e não pela grade:
   - combo12 frente34;
   - golpe3dano frente34, poses 5 e 8;
   - morte frente34, poses deitadas;
   - pontas de espada na borda em idledash e combo12 costas34.
6. Pintar o orbe da Ressonância uma vez à mão como peça do rig, porque os vãos verdes entre os anéis viram halo. Conferir o olho esverdeado (R0, R1 frente) contra `G − max(R,B) ≤ 62`.
7. Remover o halo verde do JPEG nas bordas finas e conferir a 400% sobre fundo claro e escuro.

**Barra da Ressonância (proposta):** tratar a barra como uma **peça do rig por Doutrina**, pintada à mão uma vez em 3 estados (parada, sino aberto, esvoaçando) e trocada junto com a arma. Isso resolve ao mesmo tempo os arcos que faltam e a barra que muda nas animações compartilhadas. Falta o technical-artist confirmar que o rig consegue trocar ou deformar a peça.

**Lições para os lotes 2–6:**
- Antes do primeiro prompt, listar as peças do rig: tudo que tiver símbolo, motivo ou variante fica fora das folhas.
- Antes de fechar o lote, montar uma prancha com todas as folhas reduzidas a 90 px.
- Pedir os downloads em PNG.
