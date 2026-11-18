# Requirements Traceability Index

> Last Updated: 2026-11-17
> Fonte: /architecture-review full de 2026-11-16 e fechamento de experimentos EX-0001..0016 em 2026-11-17 (relatório [architecture-review-2026-11-16.md](architecture-review-2026-11-16.md)); anterior: [architecture-review-2026-11-15.md](architecture-review-2026-11-15.md)
> IDs estáveis: [tr-registry.yaml](tr-registry.yaml). Esta matriz é gerada do registro; o status vem da revisão.

## Coverage Summary

| Status | Count | % |
|---|---|---|
| ✅ Covered (Accepted) | 400 | 100% |
| 🟡 Covered (Proposed) | 0 | 0% |
| ⚠️ Partial | 0 | 0% |
| ❌ Gap | 0 | 0% |
| **Total** | **400** | **100%** |

TR-conteudo-015 promovido a ✅ Covered (Accepted) (2026-11-17): PC de referência fixado no ADR-0004 (`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`) e medição concluída em `EX-0004-NV` (`160,8 ms` em texto no editor e `86,2 ms` em binário no `.pck`, ambos `≤ 250 ms`). Placar final: **400/400 ✅ Covered (Accepted) (100%), 0 🟡, 0 ⚠️, 0 ❌**.

## Traceability Matrix

| TR-ID | GDD | Requisito | Origem | Domínio | ADR(s) | Status |
|---|---|---|---|---|---|---|
| TR-conteudo-001 | conteudo-orientado-a-dados | Tipos de definição como Resource, com formato, campos e unidades por tipo | R1 | Dados | ADR-0004 | ✅ |
| TR-conteudo-002 | conteudo-orientado-a-dados | Ids snake_case únicos por tipo, nunca renomeados nem reaproveitados (append-only) | R2 | Dados/persistência | ADR-0004 | ✅ |
| TR-conteudo-003 | conteudo-orientado-a-dados | Definição só de leitura em execução; cópia mutável por duplicate_deep | R3 | Dados | ADR-0004, ADR-0003 | ✅ |
| TR-conteudo-004 | conteudo-orientado-a-dados | Manifesto único explícito, sem varredura em execução; teste de órfãos em CI | R4 | Dados/CI | ADR-0004 | ✅ |
| TR-conteudo-005 | conteudo-orientado-a-dados | Layout de assets/data/; cópia canônica em CSV excluída do export | R5 | Dados/build | ADR-0004 | ✅ |
| TR-conteudo-006 | conteudo-orientado-a-dados | Unidades do Godot; TICK_RATE 60 conferido na carga; F7 segundos para passos | R6 | Dados/tempo | ADR-0004, ADR-0001 | ✅ |
| TR-conteudo-007 | conteudo-orientado-a-dados | Definições guardam chaves de tradução, nunca texto; V6 confere a tabela | R7 | Dados/localização | ADR-0004, ADR-0012 | ✅ |
| TR-conteudo-008 | conteudo-orientado-a-dados | Dado só aponta para chaves registradas pelos donos; registro ausente é erro V4 | R8 | Dados/comunicação | ADR-0004 | ✅ |
| TR-conteudo-009 | conteudo-orientado-a-dados | Carga síncrona antes do menu, coleta todos os erros e bloqueia a run igual em debug e release | R9 | Dados/plataforma | ADR-0004 | ✅ |
| TR-conteudo-010 | conteudo-orientado-a-dados | Consulta por injeção (obter, existe, listar, filtrar) com relator de erros injetado | R10 | Dados/DI | ADR-0004 | ✅ |
| TR-conteudo-011 | conteudo-orientado-a-dados | Impressão SHA-256 sobre serialização canônica na ordem do manifesto | R12 | Determinismo | ADR-0004 | ✅ |
| TR-conteudo-012 | conteudo-orientado-a-dados | Estados de carga e recarga só em debug e fora de run, com revogação e reinjeção | R9 | Dados/ciclo de vida | ADR-0004, ADR-0001 | ✅ |
| TR-conteudo-013 | conteudo-orientado-a-dados | Lista canônica copiada só de leitura do cânone | R11 | Dados | ADR-0004 | ✅ |
| TR-conteudo-014 | conteudo-orientado-a-dados | Script de importação F1-F6 em tools/content-import/ com teste de paridade | F1-F6 | Pipeline de dados | ADR-0004 | ✅ |
| TR-conteudo-015 | conteudo-orientado-a-dados | Orçamento de carga: mediana até 250 ms e validação até 30 ms no PC de referência fixado (Ryzen 5 5600H, 16 GB RAM, SSD NVMe, RTX 3050 Laptop, Windows 11; medido 160,8 ms texto / 86,2 ms .pck) | AC-38 | Desempenho | ADR-0004 | ✅ |
| TR-conteudo-016 | conteudo-orientado-a-dados | Tipos CurseDef, BossPatternDef em EnemyDef.padroes, MaldicoesTuning, VinculoTuning e ChefesTuning | R1-P, OQ 9 | Pactos | ADR-0004, ADR-0017 | ✅ |
| TR-conteudo-017 | conteudo-orientado-a-dados | Mesmo id em CurseDef e EnemyDef com unicidade por tipo; ids de espécie são chave do perfil e nunca mudam | R2-P | Pactos | ADR-0004, ADR-0013 | ✅ |
| TR-conteudo-018 | conteudo-orientado-a-dados | Validação ampliada V4, V5, V8 e códigos ML, VP e CH com ML7 e ML8 na 2ª passada | R9-P | Pactos | ADR-0004, ADR-0017 | ✅ |
| TR-conteudo-019 | conteudo-orientado-a-dados | Ordem estável do manifesto de CurseDef para o sorteio do Vínculo | R10-P | Pactos | ADR-0004, ADR-0005 | ✅ |
| TR-rng-001 | rng-com-seed | Fonte única; APIs aleatórias da engine proibidas no código de jogo, com lint de CI | R1 | Determinismo/CI | ADR-0005 | ✅ |
| TR-rng-002 | rng-com-seed | Seed u32 sorteada ao criar a run; --seed só em debug; fixa durante a run | R2 | Determinismo | ADR-0005 | ✅ |
| TR-rng-003 | rng-com-seed | Fluxos derivados por finalidade, região e profundidade; lista fechada de finalidades | R3 | Determinismo | ADR-0005 | ✅ |
| TR-rng-004 | rng-com-seed | Sorteios iteram na ordem do manifesto, nunca Dictionary, hash ou árvore | R4 | Determinismo | ADR-0005, ADR-0004 | ✅ |
| TR-rng-005 | rng-com-seed | Consumo fixo nas finalidades de estrutura, independente do combate | R4b | Determinismo | ADR-0005 | ✅ |
| TR-rng-006 | rng-com-seed | Operações com consumo definido; erros não consomem e vão ao relator | R5 | Determinismo | ADR-0005 | ✅ |
| TR-rng-007 | rng-com-seed | Gerador próprio mulberry32, estável entre versões e SO, com paridade com o cânone | R6 | Determinismo/plataforma | ADR-0005 | ✅ |
| TR-rng-008 | rng-com-seed | Contrato de reprodução com seis elementos, incluindo a impressão do catálogo | R7 | Determinismo | ADR-0005, ADR-0004 | ✅ |
| TR-rng-009 | rng-com-seed | Fonte de fluxos injetada, sem singleton global | R9 | DI | ADR-0005 | ✅ |
| TR-rng-010 | rng-com-seed | Máscara u32 na fronteira e na leitura de save; save no meio da run fora do MVP | AC-10 | Persistência | ADR-0005, ADR-0013 | ✅ |
| TR-rng-011 | rng-com-seed | RNG cosmético só em src/presentation/, sem acesso à fonte de fluxos | R1 | Arquitetura de camadas | ADR-0005 | ✅ |
| TR-rng-012 | rng-com-seed | Texto da seed na pausa, morte, vitória e debug, com copiar e campo de seed no debug | R8 | UI/plataforma | ADR-0005, ADR-0012 | ✅ |
| TR-rng-013 | rng-com-seed | Finalidade 9 pactos com chave (pactos, região, 0) e consumo fixo de 4 reais, só em runs de Pactos | R3-P | Pactos | ADR-0005, ADR-0015 | ✅ |
| TR-rng-014 | rng-com-seed | Com Pactos a seed nasce em dupla_confirmada; telas anteriores não pedem fluxo | R2-P | Pactos | ADR-0005, ADR-0015 | ✅ |
| TR-rng-015 | rng-com-seed | Estado inicial ampliado com dupla e perfil de vínculo lido do perfil salvo | R7-P | Pactos | ADR-0005, ADR-0013 | ✅ |
| TR-input-001 | input-e-controle | Lista fechada de ações StringName; nenhuma tecla no código de jogo | R1 | Entrada | ADR-0006 | ✅ |
| TR-input-002 | input-e-controle | Amostra única por passo de física, antes de qualquer sistema de jogo | R2 | Entrada/ordem do passo | ADR-0006, ADR-0001 | ✅ |
| TR-input-003 | input-e-controle | Dois dispositivos simultâneos; dispositivo ativo é o último com entrada significativa | R3 | Entrada/plataforma | ADR-0006 | ✅ |
| TR-input-004 | input-e-controle | Movimento em 8 direções normalizadas; zona morta radial e reescala | R4 | Entrada | ADR-0006 | ✅ |
| TR-input-005 | input-e-controle | Mira do mouse via conversão tela para mundo da Cena; mira do analógico | R5 | Entrada/comunicação | ADR-0006, ADR-0007 | ✅ |
| TR-input-006 | input-e-controle | Remapeamento por dispositivo, persistido versionado e atômico | R8 | Persistência | ADR-0006, ADR-0013 | ✅ |
| TR-input-007 | input-e-controle | Buffer de comandos em passos inteiros que atravessa o hitstop; segurar repete | R6 | Entrada/tempo | ADR-0006 | ✅ |
| TR-input-008 | input-e-controle | Perda de foco da janela ou desconexão do gamepad pausa e solta os botões | R11 | Plataforma/estados | ADR-0001, ADR-0006, ADR-0012 | ✅ |
| TR-input-009 | input-e-controle | Telas sem mouse com foco inicial e um único modelo de foco | R9 | UI/entrada | ADR-0006, ADR-0012 | ✅ |
| TR-input-010 | input-e-controle | Contextos de entrada com roteamento e barreira de retorno | R10 | Entrada/estados | ADR-0006, ADR-0012 | ✅ |
| TR-input-011 | input-e-controle | Provedor de amostras injetado; testes roteirizados sem dispositivo | R13 | DI | ADR-0006 | ✅ |
| TR-input-012 | input-e-controle | Valores de tuning vêm do catálogo validado (InputTuning) | R12 | Dados de tuning | ADR-0004, ADR-0006 | ✅ |
| TR-input-013 | input-e-controle | Ação troca no buffer com contador único; consumo Movimento, Combate, Selo, Maldições | R1a, R6, F3 | Pactos | ADR-0006, ADR-0017 | ✅ |
| TR-input-014 | input-e-controle | Campo ponto_mira (vec2 de mundo ou vazio) na amostra de 9 campos | R1b, R2 | Pactos | ADR-0006 | ✅ |
| TR-input-015 | input-e-controle | Arquivo de binds antigo sem a ação nova recebe INPUT_ACAO_NOVA e bind livre | Edge Cases, OQ 13 | Pactos | ADR-0006, ADR-0013 | ✅ |
| TR-cena-001 | cena-3-4-e-camera | Viewport lógico 1920x1080, stretch canvas_items e keep_height, com pillarbox | R1 | Engine/plataforma | ADR-0007 | ✅ |
| TR-cena-002 | cena-3-4-e-camera | 1 unidade = 1,5 px, convertida só na importação | R2 | Dados | ADR-0007 | ✅ |
| TR-cena-003 | cena-3-4-e-camera | Plano de jogo = tela; pé e altura visual separados | R3 | Engine | ADR-0007 | ✅ |
| TR-cena-004 | cena-3-4-e-camera | Lista canônica de camadas de render | R4 | Render | ADR-0007, ADR-0011 | ✅ |
| TR-cena-005 | cena-3-4-e-camera | Y-sort pelo y do pé com ordenação total e parallax manual | R5 | Render | ADR-0007 | ✅ |
| TR-cena-006 | cena-3-4-e-camera | Câmara de 1920x1080 a 2880x1620 e limites da câmera | R6 | Engine | ADR-0007 | ✅ |
| TR-cena-007 | cena-3-4-e-camera | Câmera segue com lookahead e suavização, interpolada sobre o passo fixo | R7 | Engine/tempo | ADR-0007 | ✅ |
| TR-cena-008 | cena-3-4-e-camera | Impulsos de câmera na apresentação, com remetente único e um por passo | R8 | Comunicação | ADR-0007, ADR-0002 | ✅ |
| TR-cena-009 | cena-3-4-e-camera | Relógio da câmera é t_apres, injetado | R12 | Tempo | ADR-0001, ADR-0007 | ✅ |
| TR-cena-010 | cena-3-4-e-camera | Conversão tela para mundo pela câmera base, sem chute, tremor nem zoom | R9 | Comunicação/entrada | ADR-0007, ADR-0006 | ✅ |
| TR-cena-011 | cena-3-4-e-camera | Corte da câmera no quadro da metade do wipe, na Transição | R10 | Estados/tempo | ADR-0001, ADR-0007 | ✅ |
| TR-cena-012 | cena-3-4-e-camera | Valores de tuning vêm do catálogo validado (CameraTuning) | R11 | Dados de tuning | ADR-0004, ADR-0007 | ✅ |
| TR-cena-013 | cena-3-4-e-camera | Câmera, impulsos e relógio injetados; testes com câmera falsa | R12 | DI | ADR-0007 | ✅ |
| TR-modificadores-001 | modificadores-e-atributos | Portador por combatente; atributos derivados separados dos recursos | R1 | Estrutura de dados | ADR-0009, ADR-0003 | ✅ |
| TR-modificadores-002 | modificadores-e-atributos | Lista fechada de atributos com piso e teto; estrutura do modificador | R2 | Estrutura de dados | ADR-0009 | ✅ |
| TR-modificadores-003 | modificadores-e-atributos | Estado de portador independente por instância; definição do catálogo intacta | R11 | Estrutura de dados | ADR-0003, ADR-0009 | ✅ |
| TR-modificadores-004 | modificadores-e-atributos | Condicionais avaliados no uso, com contexto passado por quem consulta | R4 | Comunicação | ADR-0009 | ✅ |
| TR-modificadores-005 | modificadores-e-atributos | Tabela fechada das 21 chaves de tipo de efeito, entregue ao validador | R5 | Dados/registro | ADR-0009, ADR-0004 | ✅ |
| TR-modificadores-006 | modificadores-e-atributos | Remover uma fonte remove todos os seus modificadores e gatilhos | R6 | Estrutura de dados | ADR-0009 | ✅ |
| TR-modificadores-007 | modificadores-e-atributos | Recálculo imediato, sem esperar quadro | R7 | Tempo/consistência | ADR-0009 | ✅ |
| TR-modificadores-008 | modificadores-e-atributos | Ordem canônica, float até o fim e arredondamento determinístico | F1 | Determinismo | ADR-0009 | ✅ |
| TR-modificadores-009 | modificadores-e-atributos | Atributo x recurso com notificação de valor antigo e novo | R9 | Comunicação | ADR-0009 | ✅ |
| TR-modificadores-010 | modificadores-e-atributos | Elite e profundidade aplicadas como fontes no spawn | R10 | Comunicação | ADR-0009 | ✅ |
| TR-modificadores-011 | modificadores-e-atributos | Semântica dos gatilhos com executor único | R13 | Comunicação | ADR-0009 | ✅ |
| TR-modificadores-012 | modificadores-e-atributos | Paridade de tabela com o cânone | AC-32 | Teste/determinismo | ADR-0009 | ✅ |
| TR-modificadores-013 | modificadores-e-atributos | Valores de tuning vêm do catálogo validado; valor já escalado, params não escalam | R8 | Dados de tuning | ADR-0004, ADR-0009 | ✅ |
| TR-modificadores-014 | modificadores-e-atributos | Um portador por Maldição da dupla (base, vinculo, especie, espelhos), persistente na Exaustão e na reserva, criável no passo de um pacto | R14, AC-40 | Pactos | ADR-0009, ADR-0003, ADR-0017 | ✅ |
| TR-modificadores-015 | modificadores-e-atributos | Espelho por tipos_propagados_maldicao e fator_propagacao_maldicao, entra e sai com a fonte do jogador em todos os portadores | R14, F6 | Pactos | ADR-0009, ADR-0017 | ✅ |
| TR-modificadores-016 | modificadores-e-atributos | Origens vinculo, especie e espelho e lista restrita de atributos do portador da Maldição | R2, R3 | Pactos | ADR-0009 | ✅ |
| TR-pipeline-001 | pipeline-visual | Três famílias de material por papel, lista fechada | R1 | Render | ADR-0011 | ✅ |
| TR-pipeline-002 | pipeline-visual | Grading regional por LUT global, com plano B | R2 | Render/engine | ADR-0011 | ✅ |
| TR-pipeline-003 | pipeline-visual | Escurecimento por profundidade calculado na CPU, em linear | R3 | Render | ADR-0011 | ✅ |
| TR-pipeline-004 | pipeline-visual | t_vivo e t_apres globais escritos pelo orquestrador; sem TIME no mundo; zero no meio do wipe | R8 | Tempo | ADR-0001, ADR-0011 | ✅ |
| TR-pipeline-005 | pipeline-visual | Telégrafo em duas passadas, quad e malha de borda, 24 slots | R5 | Render | ADR-0011, ADR-0014 | ✅ |
| TR-pipeline-006 | pipeline-visual | Traço do jogador em CanvasGroup e imagens residuais | R6 | Render | ADR-0011 | ✅ |
| TR-pipeline-007 | pipeline-visual | Impact frame global, limitador F6, wipe e morte, modos de tela por prioridade | R7 | Render/estados | ADR-0011 | ✅ |
| TR-pipeline-008 | pipeline-visual | Teto de 500 draw calls por grupo, overdraw, partículas e luz, medidos por captura | R9 | Desempenho | ADR-0011 | ✅ |
| TR-pipeline-009 | pipeline-visual | Memória de textura 512 MiB com alerta em 448; tetos somam 504 MiB | R9 | Desempenho/memória | ADR-0011 | ✅ |
| TR-pipeline-010 | pipeline-visual | Chaves de project.godot, shader_globals e Shader Baker no preset de exportação | R10 | Engine/build | ADR-0011 | ✅ |
| TR-pipeline-011 | pipeline-visual | Emissores e animações do relógio vivo congelam no hitstop, com fallback | R8 | Engine/tempo | ADR-0011 | ✅ |
| TR-pipeline-012 | pipeline-visual | Acessibilidade de render: Reduzir flashes e Redução de movimento | R11 | Render/acessibilidade | ADR-0011 | ✅ |
| TR-pipeline-013 | pipeline-visual | Valores de tuning vêm do catálogo validado (VisualTuning); estado e opções injetados | R12 | Dados de tuning/DI | ADR-0004, ADR-0011 | ✅ |
| TR-pipeline-014 | pipeline-visual | Contorno tracejado secundário com raio_secundario_px do BossPatternDef, z 5, some no disparo | R5a | Pactos | ADR-0011, ADR-0014 | ✅ |
| TR-pipeline-015 | pipeline-visual | Fio de vínculo e marca do Virote como traco_sdf em z -5 com estados pela distância | R5b | Pactos | ADR-0011 | ✅ |
| TR-pipeline-016 | pipeline-visual | Validador acusa nó tel_sdf com dono da facção do jogador | R5b, AC-PV-88 | Pactos | ADR-0011 | ✅ |
| TR-feedback-001 | feedback-de-combate | Árbitro puro: lista de eventos e relógios entram, pedidos ordenados saem | R14 | Comunicação/DI | ADR-0002 | ✅ |
| TR-feedback-002 | feedback-de-combate | Só lê eventos e nunca escreve em sistema de jogo | R1 | Arquitetura de camadas | ADR-0002, ADR-0011 | ✅ |
| TR-feedback-003 | feedback-de-combate | Catálogo evento para resposta; remetente único de impulso de câmera, um por passo | R3 | Comunicação | ADR-0002, ADR-0007 | ✅ |
| TR-feedback-004 | feedback-de-combate | Prioridades P0-P4 e limitador F6; pedido negado é descartado e o evento segue | R4 | Render/comunicação | ADR-0011 | ✅ |
| TR-feedback-005 | feedback-de-combate | Degradação de VFX por uso medido, com histerese | F3 | Desempenho | ADR-0011 | ✅ |
| TR-feedback-006 | feedback-de-combate | Respostas vivas congelam no hitstop; respostas de apresentação correm | R2 | Tempo | ADR-0002, ADR-0001 | ✅ |
| TR-feedback-007 | feedback-de-combate | Números de dano: faixas por alvo, agregação, teto e regra de saída | R6 | Estrutura de dados/render | ADR-0002, ADR-0011 | ✅ |
| TR-feedback-008 | feedback-de-combate | Um som por gancho por passo; limite de vozes por gancho e total, por prioridade | R9 | Áudio | ADR-0016 | ✅ |
| TR-feedback-009 | feedback-de-combate | Acerto marcado lido da flag do evento acerto, sem contagem própria | R5 | Comunicação | ADR-0002, ADR-0010 | ✅ |
| TR-feedback-010 | feedback-de-combate | Ordem de camadas; impact frame é shader global, não camada | R11 | Render | ADR-0011, ADR-0007 | ✅ |
| TR-feedback-011 | feedback-de-combate | Preempção no mesmo passo entre chefe, recusa, passes e telégrafos | R12 | Render/ordem | ADR-0011 | ✅ |
| TR-feedback-012 | feedback-de-combate | Opções de acessibilidade aplicadas pelos donos, sem resposta que as contorne | R7 | Acessibilidade/persistência | ADR-0007, ADR-0011, ADR-0013 | ✅ |
| TR-feedback-013 | feedback-de-combate | Na Transição, descartar fila e respostas vivas; relógios zeram no meio do wipe | R13 | Estados/tempo | ADR-0001, ADR-0011 | ✅ |
| TR-feedback-014 | feedback-de-combate | Valores de tuning vêm do catálogo validado (FeedbackTuning) | Tuning Knobs | Dados de tuning | ADR-0004 | ✅ |
| TR-feedback-015 | feedback-de-combate | Catálogo de 13 eventos das Maldições, golpe sem hitstop nem câmera, número agregado jogador e Maldição no mesmo alvo | R15, R16, R17 | Pactos | ADR-0002, ADR-0011 | ✅ |
| TR-feedback-016 | feedback-de-combate | Ganchos de áudio sfx_maldicao_* | R18 | Pactos | ADR-0016 | ✅ |
| TR-combate-nucleo-001 | combate-nucleo | Ordem fixa dos 10 itens do passo vivo, só no estado Jogo | R1 | Tempo/ordem do passo | ADR-0001, ADR-0010 | ✅ |
| TR-combate-nucleo-002 | combate-nucleo | Hitstop como contador de passos (vale o maior), congela do passo seguinte; nunca Engine.time_scale | R10 | Tempo/ordem do passo | ADR-0001, ADR-0010 | ✅ |
| TR-combate-nucleo-003 | combate-nucleo | Lista de inimigos em ordem estável, estado vivo fora do SceneTree, lógica testável sem cena | R16, AC-02 | Estrutura de dados | ADR-0003 | ✅ |
| TR-combate-nucleo-004 | combate-nucleo | Descontos do item 3 antes do Movimento; disparo do item 5 com Especial primeiro, combo por slot, um golpe por passo | R2, R3 | Tempo/ordem do passo | ADR-0010 | ✅ |
| TR-combate-nucleo-005 | combate-nucleo | Geometria de acerto única (arco, círculo, leque) reusada pelos telégrafos (forma = teste, P3) | R4, R5, F4 | Comunicação entre sistemas | ADR-0010, ADR-0014 | ✅ |
| TR-combate-nucleo-006 | combate-nucleo | Projéteis em lista própria com ordem fixa de teste por passo e disparar_projetil para a IA | R6, R7, F5 | Estrutura de dados | ADR-0010 | ✅ |
| TR-combate-nucleo-007 | combate-nucleo | ferir_inimigo com dano float, contador de acertos e caminho silencioso para Status e Selo | R8, R9, F1 | Determinismo/dados | ADR-0010, ADR-0009 | ✅ |
| TR-combate-nucleo-008 | combate-nucleo | ferir_jogador com dano inteiro e um arredondamento; recursos do jogador no Combate; em combate consultado das Câmaras | R13, F10 | Determinismo/dados | ADR-0010, ADR-0009 | ✅ |
| TR-combate-nucleo-009 | combate-nucleo | Eventos tipados com campos fixos e durações prontas para HUD, Feedback, Áudio, Selo, Status, Câmaras, Run e Telemetria | R17 | Comunicação entre sistemas | ADR-0002, ADR-0010 | ✅ |
| TR-combate-nucleo-010 | combate-nucleo | Varredura de mortes com retrato por passe (até 4); morto não age; morte do jogador para os passos seguintes | R14 | Tempo/ordem do passo | ADR-0010, ADR-0003 | ✅ |
| TR-combate-nucleo-011 | combate-nucleo | Transição com seis ações em ordem no quadro de progresso_wipe >= 0,5 | R1 | Tempo/ordem do passo | ADR-0001, ADR-0011 | ✅ |
| TR-combate-nucleo-012 | combate-nucleo | Empurrão e impacto na parede com colisão própria contra paredes e obstáculos | R11, R12, F7, F8 | Capacidade da engine | ADR-0008, ADR-0010 | ✅ |
| TR-combate-nucleo-013 | combate-nucleo | Câmara limpa só é avaliada com hitstop em 0 (contrato com Câmaras e Run) | R10, AC-95 | Tempo/ordem do passo | ADR-0001, ADR-0010 | ✅ |
| TR-combate-nucleo-014 | combate-nucleo | Pedidos síncronos do Movimento (cancelar, garantir_invulneravel, aplicar_corte, esquiva_iniciada); Corte pesado sem hitstop | R18 | Comunicação entre sistemas | ADR-0010, ADR-0008 | ✅ |
| TR-combate-nucleo-015 | combate-nucleo | Todas as dependências do Combate por injeção (portadores, amostra, consultas, geometria, tuning, AttackDef) | R16, AC-04 | Comunicação entre sistemas | ADR-0001, ADR-0003, ADR-0010 | ✅ |
| TR-combate-nucleo-016 | combate-nucleo | Valores de tuning vêm do CombatTuning validado no catálogo (CV1-CV21) | R15 | Dados de tuning | ADR-0004 | ✅ |
| TR-combate-nucleo-017 | combate-nucleo | Orçamento de CPU dos itens 3, 5, 7, 8 e 9 com p99 <= 0,3 ms por passo | AC-81 | Desempenho | ADR-0010 | ✅ |
| TR-combate-nucleo-018 | combate-nucleo | Latência do golpe <= 2 passos + 1 quadro, medida até o fim de desenho do quadro | AC-92 | Desempenho/plataforma | ADR-0010, ADR-0006 | ✅ |
| TR-combate-nucleo-019 | combate-nucleo | Item 6.1 Maldições depois do Selo (6) e antes dos inimigos (7) | R1, R23 | Pactos | ADR-0001, ADR-0017, ADR-0010 | ✅ |
| TR-combate-nucleo-020 | combate-nucleo | Maldição na facção do jogador fora das listas de alvos, sem fogo amigo; aplicar_golpe_maldicao síncrono com abate creditado ao dono | R19, R20, R14 | Pactos | ADR-0010, ADR-0003 | ✅ |
| TR-combate-nucleo-021 | combate-nucleo | ferir_maldicao (F12) com Exaustão síncrona via exaurir; golpe e projétil inimigo testam só o alvo guardado | R21, R22, R7 | Pactos | ADR-0010, ADR-0014, ADR-0017 | ✅ |
| TR-combate-nucleo-022 | combate-nucleo | ferir_acuada (F13) sem hitstop nem número; falhar_encontro síncrono nos itens 7 e 8, antes da varredura | R25, F13 | Pactos | ADR-0010, ADR-0001, ADR-0014 | ✅ |
| TR-combate-nucleo-023 | combate-nucleo | Chefe subjugavel fica Subjugado na lista com pedido subjugar à IA e projéteis removidos; lacaios invocado_pelo_chefe saem sem abate | R24, R14 | Pactos | ADR-0010, ADR-0018 | ✅ |
| TR-combate-nucleo-024 | combate-nucleo | Eventos maldicao_atingida, maldicao_exausta, chamado, chamado_indisponivel, chefe_vencido e campos autor_player_id, limpo_pelo_chefe, origem maldicao | R17 | Pactos | ADR-0002, ADR-0010, ADR-0017 | ✅ |
| TR-armas-001 | armas-das-doutrinas | WeaponDef com exatamente 7 campos e AttackDef como sub-recurso; propriedade desconhecida é erro | R1, AC-AR-01 | Estrutura de dados | ADR-0004 | ✅ |
| TR-armas-002 | armas-das-doutrinas | Arma sem regra própria em código: tudo vem das formas e params do AttackDef | R1, AC-AR-07 | Conteúdo orientado a dados | ADR-0004, ADR-0010 | ✅ |
| TR-armas-003 | armas-das-doutrinas | Injeção da arma no começo da run: portador com vida_max e velocidade base, Combate com os dois AttackDef | R9, AC-AR-06 | Comunicação entre sistemas | ADR-0009, ADR-0010, ADR-0015 | ✅ |
| TR-armas-004 | armas-das-doutrinas | Tela de escolha antes da run com o componente de carta, navegável por teclado, mouse e gamepad | R4, AC-AR-12 | UI/entrada | ADR-0012, ADR-0006 | ✅ |
| TR-armas-005 | armas-das-doutrinas | Estados Escolhendo, Equipada e Encerrada; arma fixa durante a run | States, AC-AR-10 | Tempo/estados de jogo | ADR-0001, ADR-0015 | ✅ |
| TR-armas-006 | armas-das-doutrinas | Última arma em user://preferencias.cfg [armas] ultima_arma, gravada só ao confirmar | R4, AC-AR-08 | Persistência | ADR-0013 | ✅ |
| TR-armas-007 | armas-das-doutrinas | Build de playtest sem pré-seleção e com zero leituras e gravações de preferencias.cfg | R4, AC-AR-39 | Persistência/plataforma | ADR-0013 | ✅ |
| TR-armas-008 | armas-das-doutrinas | Chave derivada <chave_nome>_DESC e nomes canônicos validados, sem campo novo | R4, R8, AC-AR-33 | Dados/localização | ADR-0004 | ✅ |
| TR-armas-009 | armas-das-doutrinas | Validações cruzadas AV1-AV8 na segunda passada, com relatório de conjunto exato | Formulas, AC-AR-32 | Conteúdo orientado a dados | ADR-0004 | ✅ |
| TR-armas-010 | armas-das-doutrinas | Valores de tuning vêm do ArmasTuning e dos WeaponDef validados no catálogo | Tuning Knobs, R2 | Dados de tuning | ADR-0004 | ✅ |
| TR-armas-011 | armas-das-doutrinas | Arma escolhida em cada run chega à Telemetria local | R6 | Comunicação/persistência | ADR-0002, ADR-0013 | ✅ |
| TR-armas-012 | armas-das-doutrinas | Especial chamado da Besta só pede o salto à Maldição pela consulta pode chamar; recusa não consome recarga e emite chamado_indisponivel | R2b | Pactos | ADR-0010, ADR-0017, ADR-0002 | ✅ |
| TR-armas-013 | armas-das-doutrinas | Virote emite acerto_virote para a marca da Maldição | R2b | Pactos | ADR-0002 | ✅ |
| TR-armas-014 | armas-das-doutrinas | AV9 forma chamado só no slot especial de WeaponDef pactos; pares com pactos validados pelo ML8 na 2ª passada | AV9 | Pactos | ADR-0004 | ✅ |
| TR-selo-001 | selo-e-fluxo | Fluxo float 0..100 com regeneração por passo vivo no item 6 e +3 por acerto_de_arma do item 5 | R1 | Comunicação entre sistemas | ADR-0002, ADR-0010 | ✅ |
| TR-selo-002 | selo-e-fluxo | Plantar no item 6, depois do golpe, consumindo só selo do buffer | R2 | Tempo/ordem do passo | ADR-0001, ADR-0010, ADR-0006 | ✅ |
| TR-selo-003 | selo-e-fluxo | Flag do Input selo apertado neste passo para selo_sem_fluxo uma vez por toque | R2, AC-SF-08 | Entrada | ADR-0006 | ✅ |
| TR-selo-004 | selo-e-fluxo | Investida ativa lida pelo Combate no item 5 antes do disparo, guardada e entregue ao Selo | R2, AC-SF-10 | Comunicação entre sistemas | ADR-0010 | ✅ |
| TR-selo-005 | selo-e-fluxo | Dano por passo pelo caminho silencioso de ferir_inimigo, com M do grupo Selo a cada passo | R3 | Comunicação entre sistemas | ADR-0010, ADR-0009 | ✅ |
| TR-selo-006 | selo-e-fluxo | Consulta no_selo(inimigo) válida até o próximo item 6, lida pela IA | R4 | Estrutura de dados | ADR-0003 | ✅ |
| TR-selo-007 | selo-e-fluxo | Acerto do item 8 credita Fluxo no fim do passo e só serve no seguinte | F1, AC-SF-26 | Tempo/ordem do passo | ADR-0010, ADR-0002 | ✅ |
| TR-selo-008 | selo-e-fluxo | Fluxo, recarga e Selos parados no hitstop e fora de Jogo | R1, R6 | Tempo/ordem do passo | ADR-0001 | ✅ |
| TR-selo-009 | selo-e-fluxo | Selos apagados no quadro da metade do wipe pelo aviso câmara nova, sem selo_fim | R6 | Tempo/ordem do passo | ADR-0001 | ✅ |
| TR-selo-010 | selo-e-fluxo | Inimigo morto pelo Selo cai na varredura do Combate | R5 | Comunicação entre sistemas | ADR-0010 | ✅ |
| TR-selo-011 | selo-e-fluxo | Lista de Selos ativos em ordem de criação, marcas por inimigo, sem SceneTree | R3, R8 | Estrutura de dados | ADR-0003 | ✅ |
| TR-selo-012 | selo-e-fluxo | Eventos selo, selo_sem_fluxo e selo_fim emitidos pelo Selo | R2, R3 | Comunicação entre sistemas | ADR-0002 | ✅ |
| TR-selo-013 | selo-e-fluxo | Valores de tuning vêm do SealTuning validado no catálogo (SV1-SV12) | R7, AC-SF-24 | Dados de tuning | ADR-0004 | ✅ |
| TR-selo-014 | selo-e-fluxo | Fluxo só por acerto_de_arma, Virote gera e golpe de Maldição não | R1a | Pactos | ADR-0010, ADR-0002 | ✅ |
| TR-selo-015 | selo-e-fluxo | Teste dentro do Selo percorre só inimigos, Maldição imune | R3a | Pactos | ADR-0010 | ✅ |
| TR-status-001 | efeitos-de-status | Estado por inimigo: Sangramento e Queimadura (acúmulos float + restante int) e Abalo (restante), em passos vivos | R1 | Estrutura de dados | ADR-0003 | ✅ |
| TR-status-002 | efeitos-de-status | aplicar_status síncrono, chamado por Combate e Selo, recusando alvo não atingível | R2 | Comunicação | ADR-0002, ADR-0010, ADR-0009 | ✅ |
| TR-status-003 | efeitos-de-status | Dano por passo no item 7, em ordem estável, antes de impacto e IA; aplicado no item 8 fere no passo seguinte | R4 | Ordem do passo | ADR-0010, ADR-0001 | ✅ |
| TR-status-004 | efeitos-de-status | Dano de status pelo caminho silencioso de ferir_inimigo, sem acerto, empurrão, hitstop, Fluxo nem M | R4 | Comunicação | ADR-0010 | ✅ |
| TR-status-005 | efeitos-de-status | Morte por status fechada na varredura do item 9 | R5 | Ordem do passo | ADR-0010 | ✅ |
| TR-status-006 | efeitos-de-status | Abalo com relógio único no Status e fonte única no portador | R6 | Comunicação | ADR-0009 | ✅ |
| TR-status-007 | efeitos-de-status | Contadores de status congelam em hitstop e fora de Jogo | R7 | Tempo do passo | ADR-0001 | ✅ |
| TR-status-008 | efeitos-de-status | Troca de câmara limpa todos os status | R7 | Ciclo de vida | ADR-0001, ADR-0010 | ✅ |
| TR-status-009 | efeitos-de-status | Número agregado por inimigo com período em passos vivos e animação no relógio de apresentação | R8 | Apresentação / tempo | ADR-0002, ADR-0011 | ✅ |
| TR-status-010 | efeitos-de-status | Dependências injetadas; testes sem SceneTree | R10 | Testabilidade | ADR-0003 | ✅ |
| TR-status-011 | efeitos-de-status | Valores de tuning vêm do catálogo validado (StatusTuning, ST1-ST11) | R9 | Dados | ADR-0004 | ✅ |
| TR-status-012 | efeitos-de-status | Consulta estado(inimigo) para HUD e VFX; sinais com teto de 3 e redução em multidão | R6 | Apresentação | ADR-0011, ADR-0003 | ✅ |
| TR-status-013 | efeitos-de-status | Golpe de Maldição aplica Abalo pelo impacto do Combate; Maldições sem status; Saída antes de Entrada no mesmo passo | R3a, R1a | Pactos | ADR-0010, ADR-0017 | ✅ |
| TR-telegrafos-001 | telegrafos | Telégrafo como entidade em pool pré-alocado, ligado ao dono | R1 | Estrutura de dados | ADR-0003, ADR-0014 | ✅ |
| TR-telegrafos-002 | telegrafos | Um telégrafo por inimigo; teto 24 com recusa e nova tentativa | R2 | Orçamento / capacidade | ADR-0014 | ✅ |
| TR-telegrafos-003 | telegrafos | Mira travada na criação; progresso linear só em passo vivo; acompanha o dono | R3 | Tempo do passo | ADR-0014, ADR-0001 | ✅ |
| TR-telegrafos-004 | telegrafos | Disparo resolvido no mesmo passo pela IA | R4 | Ordem do passo | ADR-0014, ADR-0010 | ✅ |
| TR-telegrafos-005 | telegrafos | Formas e dimensões derivadas do EnemyDef, fonte única | R5 | Dados | ADR-0014 | ✅ |
| TR-telegrafos-006 | telegrafos | A forma desenhada é o teste de acerto | R6 | Geometria | ADR-0014, ADR-0010 | ✅ |
| TR-telegrafos-007 | telegrafos | Comprimento da faixa limitado por parede ou obstáculo na mira | F3 | Geometria | ADR-0014, ADR-0008 | ✅ |
| TR-telegrafos-008 | telegrafos | Quebrar, cancelar e liberar tudo na hora na troca de câmara | R7 | Ciclo de vida | ADR-0014, ADR-0001 | ✅ |
| TR-telegrafos-009 | telegrafos | Entrega do estado de cada telégrafo ao Pipeline a cada quadro | AC-TG-13 | Comunicação | ADR-0014, ADR-0011 | ✅ |
| TR-telegrafos-010 | telegrafos | Validação TV1-TV6 pelo mesmo derivar() usado em jogo | R10 | Dados | ADR-0014, ADR-0004 | ✅ |
| TR-telegrafos-011 | telegrafos | Valores de tuning vêm do catálogo validado (TelegraphTuning) | R10 | Dados | ADR-0004 | ✅ |
| TR-telegrafos-012 | telegrafos | Dependências injetadas; testes sem SceneTree | R11 | Testabilidade | ADR-0014, ADR-0003 | ✅ |
| TR-telegrafos-013 | telegrafos | Duas passadas em z -5 e z 5, crescimento sem pulsar, contorno de 6 px na opção de acessibilidade | AC-TG-22 | Render / acessibilidade | ADR-0011, ADR-0007 | ✅ |
| TR-telegrafos-014 | telegrafos | Áudio com no máximo 3 telégrafos soando ao mesmo tempo | Visual/Audio | Áudio | ADR-0016 | ✅ |
| TR-telegrafos-015 | telegrafos | Telégrafo guarda alvo travado e raio, testa só ele e falha no vazio se o alvo sair | R2a, R6a | Pactos | ADR-0014 | ✅ |
| TR-telegrafos-016 | telegrafos | Dimensões pelo raio do alvo travado (F7); Maldição nunca cria telégrafo e o teto de 24 não muda | R2b, F7 | Pactos | ADR-0014 | ✅ |
| TR-telegrafos-017 | telegrafos | cancelar_telegrafo na TransicaoFase e na queda do chefe | R7a | Pactos | ADR-0014 | ✅ |
| TR-ia-001 | ia-de-inimigos-e-elites | IA no item 7, em ordem estável, nunca em hitstop nem fora de Jogo | R2 | Ordem do passo | ADR-0001, ADR-0018 | ✅ |
| TR-ia-002 | ia-de-inimigos-e-elites | Lista de inimigos com identidade estável; morto não age; remoção na varredura | R1 | Estrutura de dados | ADR-0003, ADR-0010, ADR-0018 | ✅ |
| TR-ia-003 | ia-de-inimigos-e-elites | Máquina de fases com timers em passos vivos | R3-R7 | Estado | ADR-0003, ADR-0014, ADR-0018 | ✅ |
| TR-ia-004 | ia-de-inimigos-e-elites | Fluxos de RNG ia (variável) e elites (consumo fixo de 1 real por inimigo) | R10 | Determinismo | ADR-0005, ADR-0018 | ✅ |
| TR-ia-005 | ia-de-inimigos-e-elites | Preparo acoplado a iniciar_telegrafo; golpe no mesmo passo do disparo | R5 | Comunicação | ADR-0014, ADR-0018 | ✅ |
| TR-ia-006 | ia-de-inimigos-e-elites | Inimigos presos a obstáculos e parede e separados par a par ao fim do item 7 | R9 | Colisão | ADR-0008, ADR-0018 | ✅ |
| TR-ia-007 | ia-de-inimigos-e-elites | Elite, chefe e profundidade como fontes no portador | R10 | Comunicação | ADR-0009, ADR-0018 | ✅ |
| TR-ia-008 | ia-de-inimigos-e-elites | sortear_elite chamado pelas Câmaras, no máximo 1 elite por onda | R10 | Contrato | ADR-0005, ADR-0018 | ✅ |
| TR-ia-009 | ia-de-inimigos-e-elites | ranged só inicia o preparo dentro do retângulo visível da câmera | R11 | Comunicação (câmera → regra) | ADR-0007, ADR-0018 | ✅ |
| TR-ia-010 | ia-de-inimigos-e-elites | Quebra por pedir_recuperacao; armadura de elite e chefe | R8 | Comunicação | ADR-0010, ADR-0014, ADR-0018 | ✅ |
| TR-ia-011 | ia-de-inimigos-e-elites | Consulta de alvos atingíveis em ordem estável, com raio, para Input e Movimento | Dependencies | Contrato | ADR-0006, ADR-0008, ADR-0018 | ✅ |
| TR-ia-012 | ia-de-inimigos-e-elites | Lê no_selo do item 6 e aplica lentidão e cambaleio ao andar, não ao avanço | R9 | Ordem do passo | ADR-0001, ADR-0010, ADR-0018 | ✅ |
| TR-ia-013 | ia-de-inimigos-e-elites | Dependências injetadas; testes sem SceneTree | R15 | Testabilidade | ADR-0003, ADR-0018 | ✅ |
| TR-ia-014 | ia-de-inimigos-e-elites | Valores de tuning vêm do catálogo validado (IATuning, EnemyDef, EliteRules, IV1-IV9) | R14 | Dados | ADR-0004, ADR-0018 | ✅ |
| TR-ia-015 | ia-de-inimigos-e-elites | Alvo por inimigo exposto por consulta; atrair sem renovação com respiro e imobilizar só em comuns | R16, R17, R18, F6 | Pactos | ADR-0018, ADR-0017, ADR-0010 | ✅ |
| TR-ia-016 | ia-de-inimigos-e-elites | Consulta atingiveis só leitura em ordem estável de spawn, sem Maldição nem acuada | R19, R20 | Pactos | ADR-0018, ADR-0003 | ✅ |
| TR-ia-017 | ia-de-inimigos-e-elites | Chefe ativo com fases TransicaoFase e Subjugado; subjugar para IA e colisão ofensiva; lacaios sem RNG | R21 | Pactos | ADR-0018, ADR-0010 | ✅ |
| TR-ia-018 | ia-de-inimigos-e-elites | Alvo padrão acuada por paridade de ordem, suspenso enquanto atraído | R22 | Pactos | ADR-0018, ADR-0017 | ✅ |
| TR-ia-019 | ia-de-inimigos-e-elites | Pedido puxar da IA para a técnica Convergência (TecnicaDef.puxar): aceita comuns e elites, o chefe recusa | ADR-0017 Risks; Maldições TecnicaDef.puxar | Pactos | ADR-0018, ADR-0017 | ✅ |
| TR-movimento-001 | movimento-e-esquiva | Só o Movimento escreve a posição do jogador; outros pedem deslocar(v) | R1 | Posse de estado | ADR-0008, ADR-0003 | ✅ |
| TR-movimento-002 | movimento-e-esquiva | Roda só em Jogo; o orquestrador decide passo() ou passo_congelado() | R2 | Tempo do passo | ADR-0001, ADR-0008 | ✅ |
| TR-movimento-003 | movimento-e-esquiva | passo_congelado() só iguala anterior a atual; sem consulta ao hitstop | R2 | Tempo do passo | ADR-0001, ADR-0008 | ✅ |
| TR-movimento-004 | movimento-e-esquiva | Ordem interna fixa do passo; Movimento antes de Combate e Selo | R3 | Ordem do passo | ADR-0008, ADR-0001 | ✅ |
| TR-movimento-005 | movimento-e-esquiva | Pedidos síncronos ao Combate na ordem cancelar, garantir_invulneravel, esquiva_iniciada | R5 | Comunicação | ADR-0008 | ✅ |
| TR-movimento-006 | movimento-e-esquiva | Esquiva pelo buffer; toque sem carga no congelamento emite esquiva_sem_carga no 1º passo vivo | R5 | Entrada | ADR-0006, ADR-0008 | ✅ |
| TR-movimento-007 | movimento-e-esquiva | Colisão própria discreta com círculos e retângulo; inimigos não bloqueiam | R10 | Colisão | ADR-0008 | ✅ |
| TR-movimento-008 | movimento-e-esquiva | Teleporte com aviso para reset de interpolação na apresentação | R1 | Câmera / interpolação | ADR-0007, ADR-0008 | ✅ |
| TR-movimento-009 | movimento-e-esquiva | Corte da esquiva: consulta ordenada, M pelo portador, aplicar_corte no Combate, sem hitstop | R8 | Comunicação | ADR-0008, ADR-0009, ADR-0010 | ✅ |
| TR-movimento-010 | movimento-e-esquiva | Máximo de cargas sincronizado com o atributo no item 0 | R7 | Comunicação | ADR-0008, ADR-0009 | ✅ |
| TR-movimento-011 | movimento-e-esquiva | Módulo puro injetado; determinismo bit a bit entre instâncias no mesmo build | R12 | Testabilidade / determinismo | ADR-0003, ADR-0008 | ✅ |
| TR-movimento-012 | movimento-e-esquiva | Consultas e eventos esquiva e esquiva_sem_carga para HUD, Pipeline e Áudio | Interactions | Comunicação | ADR-0002, ADR-0012, ADR-0008 | ✅ |
| TR-movimento-013 | movimento-e-esquiva | Valores de tuning vêm do catálogo validado (MovementTuning, MV1-MV8) | R11 | Dados | ADR-0004 | ✅ |
| TR-movimento-014 | movimento-e-esquiva | Orçamento de CPU do Movimento até 0,2 ms por passo (provisório) | AC-P | Desempenho | ADR-0001 | ✅ |
| TR-camaras-001 | camaras-e-ondas | Câmaras são dono único de p e p_max; chave do RNG é o índice da câmara (santuário incluído), não p | R3 | interface entre sistemas | ADR-0005, ADR-0015 | ✅ |
| TR-camaras-002 | camaras-e-ondas | Câmara montada no quadro da metade do wipe, depois do teleporte; 1ª onda no mesmo quadro | R4 | tempo do passo | ADR-0001, ADR-0008 | ✅ |
| TR-camaras-003 | camaras-e-ondas | Retângulo jogável = câmara inteira; obstáculos circulares entregues a Movimento, Selo, Telégrafos e IA | R2 | estrutura de dados / colisão | ADR-0008, ADR-0014 | ✅ |
| TR-camaras-004 | camaras-e-ondas | Layout pelo fluxo layout com consumo fixo (10 candidatos por pedra, 91 reais) | R5 | determinismo | ADR-0005 | ✅ |
| TR-camaras-005 | camaras-e-ondas | Ondas compostas na montagem pelo fluxo ondas | R6 | determinismo | ADR-0005 | ✅ |
| TR-camaras-006 | camaras-e-ondas | Spawn sorteia sempre 14 candidatos (28 reais); só a escolha final depende do jogador | R7 | determinismo | ADR-0005 | ✅ |
| TR-camaras-007 | camaras-e-ondas | Próxima onda e câmara limpa avaliadas no item 10, só com hitstop 0 | R9 | tempo do passo | ADR-0001 | ✅ |
| TR-camaras-008 | camaras-e-ondas | Consulta em combate; ao limpar remove projéteis e emite camara_limpa uma vez no mesmo passo | R10, R11 | comunicação | ADR-0002, ADR-0010 | ✅ |
| TR-camaras-009 | camaras-e-ondas | Portas com estado, posição e alcance de 111 px; interação pede a Transição e é ignorada em hitstop e Transição | R13 | input / estado de jogo | ADR-0001, ADR-0006, ADR-0015 | ✅ |
| TR-camaras-010 | camaras-e-ondas | Valores de tuning (WaveRules, RoomTuning) vêm do catálogo validado (WV1-WV9) | R15 | dados | ADR-0004 | ✅ |
| TR-camaras-011 | camaras-e-ondas | Montagem pede reposicionar_maldicao(pos) e encontro_na_camara(indice); acuada nasce sem RNG e pos_acuada fica guardada | R4-P, F6 | Pactos | ADR-0015, ADR-0017, ADR-0005 | ✅ |
| TR-camaras-012 | camaras-e-ondas | Campo ordem por inimigo passado à IA; filtro por spawn_dist_acuada_px sem mudar o consumo dos 14 candidatos | R7-P, F3-P | Pactos | ADR-0005, ADR-0018 | ✅ |
| TR-camaras-013 | camaras-e-ondas | Fase Subjugado com em combate falso e R9 suspensa; só limpar_camara_chefe emite camara_limpa(4, chefe), uma vez | R8-P, R10-P, R18-P | Pactos | ADR-0001, ADR-0010, ADR-0015 | ✅ |
| TR-camaras-014 | camaras-e-ondas | Câmara do chefe sem sorteio nem fluxos; lacaios entram na lista pelo módulo de Chefes com teto de 9 inimigos | R14-P | Pactos | ADR-0018, ADR-0005, ADR-0003 | ✅ |
| TR-camaras-015 | camaras-e-ondas | Câmara limpa conta só a lista de inimigos; Maldições e acuada ficam fora | R9-P | Pactos | ADR-0003, ADR-0010 | ✅ |
| TR-portas-001 | portas-e-recompensas | Fluxo portas com 4 reais fixos por escolha e chave pelo índice da câmara; portas forçadas consomem 0 | R7 | determinismo | ADR-0005 | ✅ |
| TR-portas-002 | portas-e-recompensas | Ordem recompensa, pedir_oferta, espera bencao_escolhida após tela_fechada, depois abre as portas; mundo parado | R2 | comunicação / estado de jogo | ADR-0001, ADR-0011, ADR-0012 | ✅ |
| TR-portas-003 | portas-e-recompensas | Concessão ao camara_limpa; nada creditado se jogador_morreu cai no mesmo passo | R2 | tempo do passo | ADR-0002, ADR-0001 | ✅ |
| TR-portas-004 | portas-e-recompensas | Última câmara jogável sem recompensa e sem porta; contrato fim_da_run com a Run | R2, R6 | interface entre sistemas | ADR-0002, ADR-0015 | ✅ |
| TR-portas-005 | portas-e-recompensas | porta_escolhida(i) vira a recompensa da próxima câmara e é entregue à Run; tudo injetado, sem SceneTree | R9, R11 | interface / composição | ADR-0002, ADR-0015 | ✅ |
| TR-portas-006 | portas-e-recompensas | Fragmentos creditados na ContaFragmentos injetada; cura lê vida_max do portador | R4, R5 | interface entre sistemas | ADR-0009, ADR-0015 | ✅ |
| TR-portas-007 | portas-e-recompensas | Valores de tuning (RewardTable) vêm do catálogo validado (PV1-PV7) | R10 | dados | ADR-0004 | ✅ |
| TR-portas-008 | portas-e-recompensas | Evento de porta escolhida com tipo e opcoes para Telemetria e HUD | Dependencies | comunicação | ADR-0002, ADR-0015 | ✅ |
| TR-portas-009 | portas-e-recompensas | Estado Aguardando pacto com encontro_aguardando e pacto_resolvido lembrado; ordem recompensa, Bênção, pacto, portas | R2-P, R11-P | Pactos | ADR-0002, ADR-0015 | ✅ |
| TR-portas-010 | portas-e-recompensas | Porta forçada chefe sem sorteio; trio (portas, 0, 5) consumido sem reordenar outros fluxos | R6-P, R9-P | Pactos | ADR-0005 | ✅ |
| TR-run-001 | run-e-regioes | Máquina de estados da run (Sem run, Escolha de arma, Ativa, Encerrada) coordenada com o orquestrador | R1 | estado de jogo | ADR-0001, ADR-0005, ADR-0015 | ✅ |
| TR-run-002 | run-e-regioes | Ordem de início arma, seed (entropia injetável, --seed só em debug), estado inicial, câmara 0, Transição | R2 | determinismo / ciclo da run | ADR-0005, ADR-0001 | ✅ |
| TR-run-003 | run-e-regioes | Sequência pela RegionDef e camaras_jogaveis; p_max lido das Câmaras; montar o índice 6 é RN3 | R3, R9 | dados / interface | ADR-0004 | ✅ |
| TR-run-004 | run-e-regioes | Vitória na ordem camara_limpa, fim_da_run, crédito, run_encerrada; tela final sem Transição | R4 | comunicação / estado de jogo | ADR-0002, ADR-0015 | ✅ |
| TR-run-005 | run-e-regioes | Morte vence a limpeza no mesmo passo | R5 | tempo do passo | ADR-0001, ADR-0002 | ✅ |
| TR-run-006 | run-e-regioes | Abandono pela pausa, desabilitado em Bênção; pausa recusada em Transição e Morte | R6 | UI / input | ADR-0012, ADR-0006 | ✅ |
| TR-run-007 | run-e-regioes | Resumo de 12 campos (10 + desfecho_chefe e dupla, R7-P) montado uma vez e imutável, lido pela tela final e pela Telemetria | R7, R7-P | estrutura de dados | ADR-0002, ADR-0015 | ✅ |
| TR-run-008 | run-e-regioes | nova_run com reset total dos sistemas da run e descarte da seed e dos fluxos; saldo da Economia fora do reset | R8 | ciclo de vida | ADR-0005, ADR-0003, ADR-0009, ADR-0015 | ✅ |
| TR-run-009 | run-e-regioes | Duração em passos de Jogo, contando o hitstop | F3 | tempo do passo | ADR-0001 | ✅ |
| TR-run-010 | run-e-regioes | Várias regiões (reservado) com índice da região na chave do RNG e no orçamento | R10 | determinismo | ADR-0005 | ✅ |
| TR-run-011 | run-e-regioes | Valores de tuning (RunTuning) vêm do catálogo validado (RN1-RN3) | Tuning Knobs | dados | ADR-0004 | ✅ |
| TR-run-012 | run-e-regioes | Última arma escolhida vem marcada na tela de início | R2 | persistência | ADR-0013 | ✅ |
| TR-run-013 | run-e-regioes | Estados da run com Escolha da dupla (só Pactos) entre Escolha de arma e Ativa; fase Subjugado não encerra a run | R1-P | Pactos | ADR-0015 | ✅ |
| TR-run-014 | run-e-regioes | Run recebe pedir_dupla, dupla_confirmada, chefe_escolhido e chefe_subjugado; com Pactos cria a seed em dupla_confirmada | R2-P, R11-P | Pactos | ADR-0015, ADR-0002, ADR-0005 | ✅ |
| TR-run-015 | run-e-regioes | Vitória no chefe em ordem fixa (crédito do chefe, camara_limpa, fim_da_run, creditar vitoria, run_encerrada); morte no mesmo passo vence | R4-P, R5-P | Pactos | ADR-0015, ADR-0001 | ✅ |
| TR-run-016 | run-e-regioes | Reset total limpa Maldições, chefe e lacaios; registro de pactos e vínculo fica fora do reset, no perfil persistido | R8-P | Pactos | ADR-0015, ADR-0013 | ✅ |
| TR-bencaos-001 | bencaos-tradicoes | Pool de 18 BoonDef na ordem do manifesto | R1, R4 | dados | ADR-0004 | ✅ |
| TR-bencaos-002 | bencaos-tradicoes | Registro de tomadas sem repetir, restantes() e tomadas(), zerado na Nova run | R2, R8, R9 | ciclo de vida | ADR-0009, ADR-0015 | ✅ |
| TR-bencaos-003 | bencaos-tradicoes | Fluxos bencaos e raridade com F7 e consumo fixo de 6 reais por oferta e por troca | R4 | determinismo | ADR-0005 | ✅ |
| TR-bencaos-004 | bencaos-tradicoes | Efeito aplicado pelo Modificadores antes do registro e dos eventos | R5 | ordem entre sistemas | ADR-0009 | ✅ |
| TR-bencaos-005 | bencaos-tradicoes | Troca e escolha no mesmo passo, a troca vence; sem pular | R5, R6 | input / UI | ADR-0012 | ✅ |
| TR-bencaos-006 | bencaos-tradicoes | Contrato síncrono pedir_oferta(região, índice), sem_bencao, oferta_ja_aberta, restantes() | R3 | interface entre sistemas | ADR-0002, ADR-0015 | ✅ |
| TR-bencaos-007 | bencaos-tradicoes | Eventos oferta_aberta, oferta_trocada e bencao_tomada para Tela, HUD, Áudio e Telemetria | R5 | comunicação | ADR-0002, ADR-0012 | ✅ |
| TR-bencaos-008 | bencaos-tradicoes | Mundo parado com a oferta aberta; contadores do Combate não descontam | R11 | tempo do passo / estado | ADR-0001, ADR-0011 | ✅ |
| TR-bencaos-009 | bencaos-tradicoes | Texto da carta com o número da raridade, arredondado como no Modificadores, em chave de tradução | R10 | dados / localização | ADR-0009, ADR-0012 | ✅ |
| TR-bencaos-010 | bencaos-tradicoes | Valores de tuning (BencaosTuning, RarityTable) vêm do catálogo validado (BN1, BN2) | Tuning Knobs | dados | ADR-0004 | ✅ |
| TR-bencaos-011 | bencaos-tradicoes | Bênção de dano_todo_pct espelha no portador da Maldição no mesmo passo; Tradição de slot só no Virote | R14-P, AC-BN-26 | Pactos | ADR-0009 | ✅ |
| TR-economia-001 | economia-de-fragmentos | ContaFragmentos injetada, sem singleton, com saldo que atravessa as runs e coletados_run | R1 | composição / ciclo de vida | ADR-0015 | ✅ |
| TR-economia-002 | economia-de-fragmentos | Valores de tuning (EconomyRates) vêm do catálogo validado; cada taxa tem um só dono | R2 | dados | ADR-0004 | ✅ |
| TR-economia-003 | economia-de-fragmentos | Interface só de leitura para HUD e Telemetria; evento saldo_mudou | R8 | comunicação | ADR-0002, ADR-0012 | ✅ |
| TR-economia-004 | economia-de-fragmentos | Ordem com a Run (coletados antes da vitória, efetivo devolvido); nada creditado se a morte cai no mesmo passo | R4 | interface / tempo do passo | ADR-0002, ADR-0015 | ✅ |
| TR-economia-005 | economia-de-fragmentos | exportar() e importar(int) sem arquivo no MVP | R7 | persistência | ADR-0013 | ✅ |
| TR-economia-006 | economia-de-fragmentos | nova_run() zera coletados_run e mantém o saldo | R6 | ciclo de vida | ADR-0015 | ✅ |
| TR-economia-007 | economia-de-fragmentos | Run e Portas aceitam a Economia ausente sem quebrar | Dependencies | composição | ADR-0015 | ✅ |
| TR-economia-008 | economia-de-fragmentos | Fonte chefe ativa, creditar(chefe, 6) chamado por Chefes no 1º passo vivo após o hitstop ou no Exorcizar; Pactuar não credita (EC1) | R2-P, R4-P | Pactos | ADR-0015, ADR-0001, ADR-0010 | ✅ |
| TR-economia-009 | economia-de-fragmentos | Saldo de Fragmentos fora do save no MVP, enquanto pactos e vínculo persistem no perfil (decisão 21) | OQ 6 | Pactos | ADR-0013 | ✅ |
| TR-hud-001 | hud | HUD só lê, sem escrita e sem estado de jogo | R1 | comunicação | ADR-0002, ADR-0012 | ✅ |
| TR-hud-002 | hud | Na criação, inclusive na Transição, lê o estado por consulta, nunca só por evento | R14 | comunicação | ADR-0002, ADR-0012 | ✅ |
| TR-hud-003 | hud | Âncoras nas bordas do viewport, margem de 48 px, escala de UI de 85 a 150%, ultrawide | R2, R13 | plataforma / UI | ADR-0012, ADR-0007 | ✅ |
| TR-hud-004 | hud | Vinheta de Vida baixa na camada de pós (z 50), sem 12ª camada | R4 | renderização | ADR-0011, ADR-0012 | ✅ |
| TR-hud-005 | hud | Sinais preco_revelado e tela_fechada; rachar espera o hitstop; visibilidade pelo estado de jogo | R3, R12 | comunicação / estado | ADR-0012 | ✅ |
| TR-hud-006 | hud | Glifo por dispositivo via rotulo_acao, trocado no passo seguinte | R10 | input | ADR-0012, ADR-0006 | ✅ |
| TR-hud-007 | hud | Relógio de UI em tempo real que para com a pausa | Game Feel | tempo | ADR-0012 | ✅ |
| TR-hud-008 | hud | Latência de no máximo 1 passo do evento da fonte | R1 | desempenho / comunicação | ADR-0002, ADR-0012 | ✅ |
| TR-hud-009 | hud | Fios de Vida em pool de 9, os mais próximos; aparecem pela queda da Vida, não pelo acerto | R9 | estrutura de dados | ADR-0012 | ✅ |
| TR-hud-010 | hud | Valores de tuning (HudTuning) vêm do catálogo validado (HU1-HU14) | R14 | dados | ADR-0004 | ✅ |
| TR-hud-011 | hud | Camada de UI, fontes e orçamento de draw calls do Pipeline | Dependencies | renderização / desempenho | ADR-0011 | ✅ |
| TR-hud-012 | hud | Opções de acessibilidade do HUD aplicadas e guardadas entre sessões | R13 | persistência / UI | ADR-0012, ADR-0013 | ✅ |
| TR-hud-013 | hud | Bloco do Pacto só com Pactos, lê estado_pacto no início e reage a troca_indisponivel e troca_feita | R15, R19 | Pactos | ADR-0012, ADR-0002 | ✅ |
| TR-hud-014 | hud | Vida da Maldição em barra de largura fixa (F8), atualização em até 1 passo, troca de slots no passo do evento | F8, R18 | Pactos | ADR-0012 | ✅ |
| TR-tela-bencao-001 | tela-de-bencao-e-carta | Só lê e devolve escolher ou trocar por objeto injetado; relógio de UI injetável | R1, R16 | comunicação | ADR-0012 | ✅ |
| TR-tela-bencao-002 | tela-de-bencao-e-carta | CartaView montada pela Bênçãos a partir do BoonDef (glifo, icone_ganho, chave do preço com {valor}) | R2 | dados / interface | ADR-0012 | ✅ |
| TR-tela-bencao-003 | tela-de-bencao-e-carta | Fileira na ordem do sorteio e escala s com margem de 48 px | R3 | UI / plataforma | ADR-0012 | ✅ |
| TR-tela-bencao-004 | tela-de-bencao-e-carta | Um modelo de foco para mouse, teclado e gamepad | R6 | input | ADR-0012, ADR-0006 | ✅ |
| TR-tela-bencao-005 | tela-de-bencao-e-carta | Trava de 500 ms, borda de subida e buffer esvaziado ao abrir | R7 | input | ADR-0012, ADR-0006 | ✅ |
| TR-tela-bencao-006 | tela-de-bencao-e-carta | Troca e confirmar no mesmo quadro, só trocar(); troca sem carga desabilitada | R8 | input | ADR-0012 | ✅ |
| TR-tela-bencao-007 | tela-de-bencao-e-carta | Sinais preco_revelado e tela_fechada; a Bênçãos segura bencao_escolhida até tela_fechada | R9 | comunicação | ADR-0002, ADR-0012 | ✅ |
| TR-tela-bencao-008 | tela-de-bencao-e-carta | Mundo congelado em gravura no fundo; entrada em até 0,45 s | R5, R10 | renderização | ADR-0011 | ✅ |
| TR-tela-bencao-009 | tela-de-bencao-e-carta | Pausa por cima, sem pular; perder o foco da janela não pausa nem escolhe | R12 | estado / input | ADR-0012, ADR-0006 | ✅ |
| TR-tela-bencao-010 | tela-de-bencao-e-carta | Alto contraste, redução de movimento e Reduzir flashes pelo limitador | R14 | UI / renderização | ADR-0011, ADR-0012, ADR-0013 | ✅ |
| TR-tela-bencao-011 | tela-de-bencao-e-carta | Componente reutilizável CartaView e GrupoDeCartas com modos; só bênção no MVP | R15 | estrutura de UI | ADR-0012 | ✅ |
| TR-tela-bencao-012 | tela-de-bencao-e-carta | Valores de tuning (TelaBencaoTuning) vêm do catálogo validado (TB1-TB10) | AC-TB-35 | dados | ADR-0004 | ✅ |
| TR-tela-bencao-013 | tela-de-bencao-e-carta | Foco e escolher respondem no quadro do aperto (até 16,7 ms) | Game Feel | desempenho / input | ADR-0012 | ✅ |
| TR-tela-bencao-014 | tela-de-bencao-e-carta | Modo arma no MVP com 3 cartas e aviso_texto opcional na CartaView | R15-P | Pactos | ADR-0012 | ✅ |
| TR-tela-bencao-015 | tela-de-bencao-e-carta | Modo maldicao com duas escolhas em ordem para a Escolha do Pacto | R15b-P | Pactos | ADR-0012 | ✅ |
| TR-telemetria-001 | telemetria-local | Um .jsonl por sessão em user://, descarga a cada linha, campos comuns, última linha pode ficar truncada | R2, R3, R10 | persistência | ADR-0013 | ✅ |
| TR-telemetria-002 | telemetria-local | Só escuta; o jogo nunca lê o arquivo; tudo injetado | R1, R13 | comunicação | ADR-0002, ADR-0013 | ✅ |
| TR-telemetria-003 | telemetria-local | Esquema dos 10 eventos do MVP e campos ainda não emitidos (causa da morte, porta escolhida, câmara entrou, passo vivo) | R4, R5 | comunicação | ADR-0002 | ✅ |
| TR-telemetria-004 | telemetria-local | Contadores por câmara; duração em passos de Jogo, contando o hitstop | R5, F1 | tempo do passo | ADR-0001 | ✅ |
| TR-telemetria-005 | telemetria-local | Opção telemetria_ligada na configuração do usuário; estados Armada e Desligada; Apagar dados | R6 | persistência | ADR-0013 | ✅ |
| TR-telemetria-006 | telemetria-local | Privacidade sem caminho absoluto nem identificador, data em UTC, sem rede | R7 | plataforma / privacidade | ADR-0013 | ✅ |
| TR-telemetria-007 | telemetria-local | Falhas absorvidas com um TL1 e Parada por falha; orçamento de 1 ms por linha e 3 ms por passo (TL2) | R8, F4 | desempenho / robustez | ADR-0013 | ✅ |
| TR-telemetria-008 | telemetria-local | Limite de bytes com reserva de 512 B; retenção das últimas 20 sessões | R9, F3, F5 | persistência | ADR-0013 | ✅ |
| TR-telemetria-009 | telemetria-local | Seed e impressão do catálogo (64 e 4 hex) nas linhas de sessão e de run | R4 | determinismo / dados | ADR-0004, ADR-0005 | ✅ |
| TR-telemetria-010 | telemetria-local | Valores de tuning (TelemetriaTuning) vêm do catálogo validado | Tuning Knobs | dados | ADR-0004 | ✅ |
| TR-telemetria-011 | telemetria-local | Schema 2 com encontro_pacto, pacto, vinculo_fim_run, run_iniciada com dupla e pactos e resumo de 12 campos | R4-P | Pactos | ADR-0013, ADR-0002 | ✅ |
| TR-telemetria-012 | telemetria-local | Pior passo com 5 linhas dentro do orçamento de 3 ms por passo | F4-P | Pactos | ADR-0013 | ✅ |
| TR-maldicoes-019 | maldicoes | Orçamento de CPU do item 6.1 (Maldições) com p99 <= 0,1 ms por passo | Desempenho do 6.1 | Pactos | ADR-0017 | ✅ |
| TR-maldicoes-001 | maldicoes | Maldição é entidade da facção do jogador ligada a player_id e portador, fora das listas de inimigos e atingíveis (sem fogo amigo, não conta na câmara limpa, não bloqueia o jogador) | R1 | Pactos | ADR-0017, ADR-0003, ADR-0010 | ✅ |
| TR-maldicoes-002 | maldicoes | Dupla campo/reserva por jogador (MaldicaoRef) com estados Seguindo a Saltando/Pronta/Exausta; a dupla pode crescer no meio da run com portador novo | R2, R24 | Pactos | ADR-0017, ADR-0003, ADR-0009 | ✅ |
| TR-maldicoes-003 | maldicoes | Ordem fixa dos 8 sub-passos no item 6.1 só em passo vivo; troca automática dentro de exaurir (itens 7 e 8); quem entra só age no 6.1 seguinte | R23 | Pactos | ADR-0017, ADR-0001, ADR-0010 | ✅ |
| TR-maldicoes-004 | maldicoes | IA de aliado: alvo por prioridade (marca do Virote, mais perto do jogador no fio, seguir), desempate pelo menor id, fio com histerese | R4, R5, F1 | Pactos | ADR-0017 | ✅ |
| TR-maldicoes-005 | maldicoes | Golpe da Maldição pelo impacto do Combate com de_arma falso (sem Fluxo, golpe_* ou hitstop); abate creditado ao dono via autor_player_id | R6 | Pactos | ADR-0010, ADR-0017 | ✅ |
| TR-maldicoes-006 | maldicoes | Alvo por inimigo (jogador ou Maldição atraída); telégrafo e projétil testam só o alvo travado | R7 | Pactos | ADR-0018, ADR-0010, ADR-0014, ADR-0017 | ✅ |
| TR-maldicoes-007 | maldicoes | Atração limitada via atrair(id, passos, passos_respiro) sem renovação e com respiro; saída de campo avisada à IA no mesmo passo; fator_andar_atraido lido a cada passo | R17, R21 | Pactos | ADR-0017, ADR-0018 | ✅ |
| TR-maldicoes-008 | maldicoes | ferir_maldicao com F3 do Modificadores, sem invulnerabilidade nem hitstop; Exaustão com troca automática; maldicao_atingivel imune durante o salto | R8, R9, R22 | Pactos | ADR-0010, ADR-0017, ADR-0009 | ✅ |
| TR-maldicoes-009 | maldicoes | Contadores por passo vivo (Exaustão, regeneração com acumulador fracionário, recarga da troca) congelados em hitstop, pausa e transição | R9.3, R10, R15 | Pactos | ADR-0017, ADR-0001 | ✅ |
| TR-maldicoes-010 | maldicoes | Ação Troca no input por passo (buffer de 10 passos congelado no hitstop); recusa emite troca_indisponivel(motivo) | R11 | Pactos | ADR-0017, ADR-0006 | ✅ |
| TR-maldicoes-011 | maldicoes | Técnica combinada por dados: Saída e depois Entrada no mesmo passo, abates da Saída antes, Entrada lê o estado deixado (imobilizado, atraído, Abalo) | R12, F5 | Pactos | ADR-0017, ADR-0004 | ✅ |
| TR-maldicoes-012 | maldicoes | Chamado do Pacto via pode_chamar/pedir_chamado (item 5, executa no 6.1): salto de N passos que para em obstáculo, pouso que imobiliza comum e atrai, M_chamado, recusa pelo Combate | R13, R22 | Pactos | ADR-0017, ADR-0010 | ✅ |
| TR-maldicoes-013 | maldicoes | reposicionar_maldicao(pos) na troca de câmara limpa marca, atração e imobilização e preserva Vida, estados e recargas | R14 | Pactos | ADR-0017, ADR-0015 | ✅ |
| TR-maldicoes-014 | maldicoes | Leitura estado_pacto(player_id) sem efeito colateral e igual na pausa | R19 | Pactos | ADR-0012, ADR-0017 | ✅ |
| TR-maldicoes-015 | maldicoes | Eventos da R20 um por fato, nunca em passo congelado, com emissor único | R20 | Pactos | ADR-0002, ADR-0017 | ✅ |
| TR-maldicoes-016 | maldicoes | Passivas condicionais por código (fonte especie:<id>:<passiva>) e espelho de dano_todo_pct e velocidade_pct do jogador nos portadores da dupla | R22, R24 | Pactos | ADR-0009, ADR-0017 | ✅ |
| TR-maldicoes-017 | maldicoes | Catálogo CurseDef, TecnicaDef e MaldicoesTuning validado por ML1-ML8; valores de tuning vêm do catálogo validado | R3, R16, R17 | Pactos | ADR-0004, ADR-0017 | ✅ |
| TR-maldicoes-018 | maldicoes | Fio de vínculo sempre visível, sem telégrafo de chão, marca do Virote e ganchos sfx_maldicao_* com no máximo 1 por passo | ML-V1, ML-V2, ML-V3, ML-V4, ML-V5, ML-A1 | Pactos | ADR-0011, ADR-0016 | ✅ |
| TR-chefes-001 | chefes | Chefe como EnemyDef com comportamento chefe, lista de BossPatternDef e ChefesTuning validados por CH1-CH8; tuning vem do catálogo validado | R1, R11 | Pactos | ADR-0004 | ✅ |
| TR-chefes-002 | chefes | Máquina de estados do chefe (Surgindo a Morto/Subjugado) em ciclo de 4 padrões com timers por passo vivo | R4, R6 | Pactos | ADR-0018 | ✅ |
| TR-chefes-003 | chefes | Luta do chefe determinística sem consumir RNG (arena fixa, esperas fixas, lacaios sem fluxos elites/spawn) | R2, R6, R8 | Pactos | ADR-0005, ADR-0018 | ✅ |
| TR-chefes-004 | chefes | Alvo do chefe travado no início do Preparo; cada golpe testa só esse alvo; golpe em curso não fere ninguém se o alvo sair | R3 | Pactos | ADR-0014, ADR-0010, ADR-0018 | ✅ |
| TR-chefes-005 | chefes | Telégrafos SETOR, RETANGULO, ANEL e CIRCULO no MVP, retângulo pelo raio do alvo travado, cancelamento na TransicaoFase e no abate | R5, R7, R9.1 | Pactos | ADR-0014 | ✅ |
| TR-chefes-006 | chefes | Contorno secundário tracejado por raio_secundario_px, só desenho | R11, CH8 | Pactos | ADR-0014, ADR-0011, ADR-0004 | ✅ |
| TR-chefes-007 | chefes | disparar_projetil(alvo = id): projétil de alvo único atravessa quem não é o alvo e some por pilar, parede ou tempo | R5.3 | Pactos | ADR-0010, ADR-0018 | ✅ |
| TR-chefes-008 | chefes | Deslocamento forçado sem dano (puxão e pulso repulsor) em jogador e Maldição com colisão, ignorado por invulneráveis | R5.4, R7, F3 | Pactos | ADR-0008, ADR-0010 | ✅ |
| TR-chefes-009 | chefes | Invocação controlada de lacaios com teto e marca invocado_pelo_chefe, removidos na queda do chefe sem abate nem ao_abater | R5.4, R8 | Pactos | ADR-0018, ADR-0010 | ✅ |
| TR-chefes-010 | chefes | TransicaoFase com gatilho único, inimigo invulnerável (dano x 0, ticks continuam) e Fúria alterando velocidade e recargas | R7, F4 | Pactos | ADR-0018, ADR-0010, ADR-0009 | ✅ |
| TR-chefes-011 | chefes | Armadura total, imunidade a imobilização, fonte chefe (empurrão x 0,12) e Abalo funcionando | R1 | Pactos | ADR-0010, ADR-0009 | ✅ |
| TR-chefes-012 | chefes | Desfecho pela marca subjugavel do spawn: chefe fica na lista inerte com Vida 0, hitstop de chefe 36 mais impact frame, chefe_vencido, abate e cura só no Exorcizar | R9, R9b.1, R9b.2 | Pactos | ADR-0010, ADR-0011, ADR-0015 | ✅ |
| TR-chefes-013 | chefes | Escolha síncrona resolver_subjugado, creditar, limpar_camara_chefe; Câmaras como emissora única de camara_limpa; chefe_subjugado em s+37; escolha repetida ignorada | R9b.3, R9b.4, R9b.5, R12 | Pactos | ADR-0015, ADR-0002, ADR-0010 | ✅ |
| TR-chefes-014 | chefes | Morte do jogador no mesmo passo tem precedência sobre vitória e subjugação | Edge Cases, AC-CH-19 | Pactos | ADR-0010, ADR-0015 | ✅ |
| TR-chefes-015 | chefes | Barra de chefe no HUD lê Vida, vida_max, fase e subjugado, atualiza no mesmo passo, sem fio de Vida sob o chefe | R10 | Pactos | ADR-0012 | ✅ |
| TR-chefes-016 | chefes | Impact frame de chefe com preempção, luz de chefe, leitura da Fase 2 e ganchos de áudio chefe_* | CH-V1, CH-V2, CH-V3, CH-V4, CH-A1 | Pactos | ADR-0011, ADR-0016 | ✅ |
| TR-chefes-017 | chefes | Chefe mais lacaios dentro do teto de inimigos (9) e do teto de telégrafos (24) | CH6 | Pactos | ADR-0014, ADR-0003 | ✅ |
| TR-vinculo-001 | vinculo-e-pactos | PerfilVinculo injetado, escrito só pelo Vínculo, atravessa runs e sessões (escopo perfil) | V1, V34 | Pactos | ADR-0015, ADR-0001, ADR-0013 | ✅ |
| TR-vinculo-002 | vinculo-e-pactos | Sorteio do encontro ao criar a run no fluxo RNG novo pactos, consumo fixo de 4 reais mesmo com garantia | V6, F1, V40 | Pactos | ADR-0005, ADR-0015 | ✅ |
| TR-vinculo-003 | vinculo-e-pactos | Tela Escolha do Pacto antes da seed; seed nasce em dupla_confirmada; estado inicial inclui dupla e perfil | V16, V16b, V40, V42 | Pactos | ADR-0015, ADR-0005, ADR-0012 | ✅ |
| TR-vinculo-004 | vinculo-e-pactos | Encontro em câmara de combate normal, índices 1-2, no máximo 1 por run; consultas encontro_na_camara e encontro_aguardando sem RNG | V4, V6, V41 | Pactos | ADR-0015 | ✅ |
| TR-vinculo-005 | vinculo-e-pactos | Entidade acuada neutra, imóvel, sem fogo amigo, fora da câmara limpa, congela em hitstop, pausa e Transição | V7, States | Pactos | ADR-0010, ADR-0017 | ✅ |
| TR-vinculo-006 | vinculo-e-pactos | Alvo por paridade da ordem de nascimento, atração com prioridade, golpe só testa o seu alvo, troca de alvo no mesmo passo na fuga | V8, V44 | Pactos | ADR-0010, ADR-0017 | ✅ |
| TR-vinculo-007 | vinculo-e-pactos | ferir_acuada com dano inteiro, sem hitstop, aplica M do atacante; falhar_encontro síncrono antes da varredura | V12, V44 | Pactos | ADR-0010 | ✅ |
| TR-vinculo-008 | vinculo-e-pactos | Telas de consentimento e do chefe no estado Bênção, mundo parado, pacto grava no fim do mesmo passo | V9, V18 | Pactos | ADR-0001, ADR-0012, ADR-0013, ADR-0015 | ✅ |
| TR-vinculo-009 | vinculo-e-pactos | Recompensa sai primeiro; Portas esperam pacto_resolvido antes de abrir (passo 2b) | V9, V41 | Pactos | ADR-0015, ADR-0002 | ✅ |
| TR-vinculo-010 | vinculo-e-pactos | Dupla cresce de 1 para 2 no meio da run, nova Maldição na reserva em Pronta | V15, V43 | Pactos | ADR-0017 | ✅ |
| TR-vinculo-011 | vinculo-e-pactos | Escolha Pactuar/Exorcizar no chefe subjugado com eventos chefe_escolhido e pacto_registrado | V18, V32, V47 | Pactos | ADR-0015, ADR-0002, ADR-0012 | ✅ |
| TR-vinculo-012 | vinculo-e-pactos | pontos_run só em memória com tetos; consolida em run_encerrada antes da tela final, emite vinculo_atualizado, depois grava | V17, V20 | Pactos | ADR-0015, ADR-0013 | ✅ |
| TR-vinculo-013 | vinculo-e-pactos | Sair no meio da run consolida como abandono com regra de derrota; encontro Aguardando vira pendente | V20b, V18 | Pactos | ADR-0013, ADR-0015 | ✅ |
| TR-vinculo-014 | vinculo-e-pactos | Bônus de nível aplicados só no começo da run pela fonte de modificador vinculo (vida_max, mult_recuperacao, bonus_dano_basico no básico) | V19, V43, F4 | Pactos | ADR-0009, ADR-0017 | ✅ |
| TR-vinculo-015 | vinculo-e-pactos | Conteúdo de [vinculo] via escrever/ler/campos_de_ids, sem float nem StringName, espécies na ordem do manifesto, nível como cache de F3 | V2, V30, V31, V46 | Pactos | ADR-0013 | ✅ |
| TR-vinculo-016 | vinculo-e-pactos | ler() corrige só a entrada afetada, aviso VP-S1 uma vez por chave, nunca trava | V33, V2 | Pactos | ADR-0013 | ✅ |
| TR-vinculo-017 | vinculo-e-pactos | Valores de tuning vêm de VinculoTuning validado (VP1-VP9) e CurseDef.memorias do catálogo | Formulas, VP1-VP9, V22 | Pactos | ADR-0004 | ✅ |
| TR-vinculo-018 | vinculo-e-pactos | Telemetria com estado_inicial ampliado e eventos encontro_pacto, pacto e vinculo_fim_run | V45 | Pactos | ADR-0013, ADR-0002 | ✅ |
| TR-save-001 | save-e-perfil | Perfil único 0 e arquivo user://perfil.cfg em ConfigFile, caminhos por CaminhosDePersistencia.de(0) | R1, R2 | Pactos | ADR-0013 | ✅ |
| TR-save-002 | save-e-perfil | RepositorioDePerfil com carregar sem falha e salvar com Error, gravação só por gravar_atomico do ArmazemDeArquivos | R2, R7, AC-SP-24 | Pactos | ADR-0013 | ✅ |
| TR-save-003 | save-e-perfil | Seção [vinculo] opaca com contrato ler/escrever, especies com chave = id, campos_de_ids; seções futuras com o mesmo contrato | R3, R15, AC-SP-02 | Pactos | ADR-0013 | ✅ |
| TR-save-004 | save-e-perfil | Carga uma vez por sessão depois do catálogo Pronto e antes da escolha de arma, em sequência pura | R4 | Pactos | ADR-0013, ADR-0015, ADR-0004 | ✅ |
| TR-save-005 | save-e-perfil | Catálogo em Falhou deixa o Save em Sem gravação, sem ler nem gravar o perfil | States, AC-SP-21 | Pactos | ADR-0013, ADR-0004 | ✅ |
| TR-save-006 | save-e-perfil | Gatilhos de gravação: pacto_registrado, run_encerrada (vitória, derrota, abandono), Sair, reset, dupla escolhida | R5, AC-SP-06 | Pactos | ADR-0015, ADR-0002, ADR-0013 | ✅ |
| TR-save-007 | save-e-perfil | Gatilho marca pendente; grava no fim de passo fora de Jogo, nunca no meio dos eventos; gatilhos coalescidos em uma gravação | R5.1, R5.3, AC-SP-04, AC-SP-05 | Pactos | ADR-0013, ADR-0001, ADR-0002, ADR-0015 | ✅ |
| TR-save-008 | save-e-perfil | Só grava se o texto mudou; texto determinístico byte a byte e sem dados pessoais | R5.2, R2, AC-SP-03, AC-SP-23 | Pactos | ADR-0013 | ✅ |
| TR-save-009 | save-e-perfil | schema_version (ausente = 1) e cadeia pura de migração com migrações de conteúdo do dono; carga não grava | R6, AC-SP-12 | Pactos | ADR-0013 | ✅ |
| TR-save-010 | save-e-perfil | Falha ao gravar mantém estado em memória, PERSIST_FALHA_GRAVAR uma vez por sessão, sem laço de nova tentativa | R7, AC-SP-07 | Pactos | ADR-0013 | ✅ |
| TR-save-011 | save-e-perfil | Arquivo ausente, corrompido (cópia .bak incremental) ou de versão futura, com modo Sem gravação | R8, AC-SP-08..11, AC-SP-16, AC-SP-17 | Pactos | ADR-0013 | ✅ |
| TR-save-012 | save-e-perfil | Ids desconhecidos viram órfãs regravadas; ids de campos_de_ids viram vazio; chaves e seções desconhecidas preservadas na escrita | R9, AC-SP-13..15 | Pactos | ADR-0013 | ✅ |
| TR-save-013 | save-e-perfil | Interceptar fechar a janela, consolidar abandono e gravar antes de sair; falha mostra PERFIL_SAIR_SEM_SALVAR | R10, AC-SP-20 | Pactos | ADR-0013, ADR-0015, ADR-0012 | ✅ |
| TR-save-014 | save-e-perfil | Reset com duas confirmações e cópia .reset.bak, cancelado se a cópia falhar, sem tocar outros arquivos | R11, AC-SP-18, AC-SP-19 | Pactos | ADR-0013, ADR-0012 | ✅ |
| TR-save-015 | save-e-perfil | exportar_texto e importar_texto com a validação da carga, sem tela no MVP | R12, AC-SP-22 | Pactos | ADR-0013 | ✅ |
| TR-save-016 | save-e-perfil | Build de playtest lê e grava o perfil; PerfilNulo injetável sem if no Save | R13 | Pactos | ADR-0013, ADR-0001 | ✅ |
| TR-save-017 | save-e-perfil | Lógica pura injetada pelo Main sem Autoload, testes com ArmazemEmMemoria, só thread principal | R14 | Pactos | ADR-0001, ADR-0013 | ✅ |
| TR-save-018 | save-e-perfil | Avisos PERFIL_* uma vez por sessão só fora de Jogo, navegáveis por teclado e gamepad | UI Requirements | Pactos | ADR-0012 | ✅ |
