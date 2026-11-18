# Evidência de QA — Épicos `conteudo` (Stories 009–010) e `assets-e-conteudo` (Stories 001–005, 009)

- **Data:** 2026-11-18
- **Status Geral:** PASS (68 recursos `.tres` no manifesto, 0 órfãos, 0 erros V1–V11 e códigos dos donos)

## 1. Resumo de Entregas — Épico `conteudo`
- **Story 009 (`story-009-recarga-e-tela-de-erros.md`):**
  - `src/content/consumidor_de_ajustes.gd`: contrato `ConsumidorDeAjustes` (`receber_ajustes` / `revogar_ajustes`).
  - `src/content/carregador_de_catalogo.gd`: suporte a `recarregar()` usando `ResourceLoader.CACHE_MODE_IGNORE_DEEP`, recusa com aviso em run ou em release, revogação de ajustes antes da primeira leitura ao sair de `PRONTO`, e re-injeção ao entrar em `PRONTO`.
  - `src/presentation/tela_de_erros_do_catalogo.gd` e `src/presentation/content_error_screen.gd`: Tela de Erros do Catálogo seguindo `design/ux/tela-erros-do-catalogo.md` e `ADR-0012` (ordenação de erros antes de avisos, operação exclusivamente digital por D-pad/teclado ignorando `InputEventJoypadMotion`, cópia para área de transferência, botão de recarga exclusivo de debug e textos PT-BR de apoio embutidos).
  - Evidência visual: `production/qa/evidence/conteudo-tela-de-erros.png`.
  - Testes: `tests/unit/content/recarga_test.gd` e `tests/integration/content/recarga_e_falha_test.gd`.

- **Story 010 (`story-010-canone-importador-paridade.md`):**
  - `tools/content-import/importar_canone.gd` e `tools/content-import/gerar_catalogo_mvp.gd`.
  - Validadores de preparo/CI: `src/content/validacao/v5_nomes_canonicos.gd` (normalização NFC e checagem de nomes e doutrinas canônicas), `src/content/validacao/v9_ids_registrados.gd` (checagem acumulativa de `ids_registrados.csv`), `src/content/validacao/varredura_de_orfaos.gd` (detecção de `.tres` órfãos e verificação do texto `.tres` para campos obrigatórios ausentes e propriedades desconhecidas) e `src/content/validacao/tabela_de_textos_csv.gd`.
  - Testes: `tests/unit/content/v5_v9_test.gd`, `tests/integration/content/paridade_do_canone_test.gd` e `tests/integration/content/orfaos_e_canone_test.gd`.

## 2. Resumo de Entregas — Épico `assets-e-conteudo`
- **Story 001 (`story-001-manifesto-e-tunings-da-fatia.md`):**
  - Manifesto `assets/data/content_catalog.tres` com 68 entradas em ordem determinística.
  - 22 recursos `*Tuning` em `assets/data/tuning/*.tres` (`combat_tuning`, `armas_tuning`, `camera_tuning`, `input_tuning`, `visual_tuning`, `bencaos_tuning`, `run_tuning`, `hud_tuning`, `tela_bencao_tuning`, `feedback_tuning`, `telemetria_tuning`, `status_tuning`, `maldicoes_tuning`, `vinculo_tuning`, `chefes_tuning`, `room_tuning`, `modifiers_tuning`, `movement_tuning`, `seal_tuning`, `telegraph_tuning`, `ia_tuning`, `audio_tuning`).
- **Story 002 (`story-002-armas-ataques-e-inimigos.md`):**
  - 3 `WeaponDef` em `assets/data/armas/{lamina,ressonancia,pactos}.tres` com `AttackDef` embutidos.
  - 5 `EnemyDef` em `assets/data/inimigos/{eco_perdido,anomalia_menor,fenda_errante,anomalia_maior,soberano_do_limiar}.tres`.
  - Tabela PT-BR `assets/i18n/conteudo.csv` com todas as chaves e descrições parametrizadas sem dígitos literais.
- **Story 003 (`story-003-bencaos-regioes-e-camaras.md`):**
  - 18 `BoonDef` em `assets/data/bencaos/trad_*.tres` na ordem exata de `FixtureBn.IDS`, com `glifo`, `icone_ganho` em `res://assets/art/export/glifo_*.png` e `chave_preco` em `trad_resonance_preco_nome.tres`.
  - `assets/data/regioes/limiar.tres`, `assets/data/camaras/{rarity_table,reward_table,wave_rules,elite_rules}.tres` e `assets/data/economy_rates/economy_rates.tres`.
- **Story 004 (`story-004-pactos-maldicoes-e-chefe.md`):**
  - 4 `CurseDef` em `assets/data/maldicoes/{vulto_mudo,espreitador_da_fenda,baluarte_de_cinza,soberano_do_limiar}.tres`.
  - `EnemyDef` `soberano_do_limiar.tres` com os 4 `BossPatternDef` (`setor`, `retangulo`, `anel`, `circulo`).
- **Story 005 (`story-005-canon-csv-paridade-e-aposentar-json.md`):**
  - CSVs canônicos em `assets/data/canon/` (`mapa_ids.csv`, `ids_registrados.csv`, `tradicoes.csv`, `armas.csv`, `inimigos.csv`, `regioes.csv`, `recompensas.csv`, `maldicoes.csv`, `nomes_canonicos.csv`), todos acompanhados de `.csv.import` com `importer="keep"`.
  - **Aposentadoria do `data/integration/gameplay.json` legado:** todos os sistemas de domínio (`src/content/`, `src/gameplay/`, `src/presentation/`) consomem exclusivamente as definições tipadas carregadas por `CarregadorDeCatalogo` a partir de `res://assets/data/content_catalog.tres` (conforme ADR-0004 e AC-24). O arquivo `data/integration/gameplay.json` permanece congelado apenas como fixture legada da fatia transitória de `SessionCatalog`, não sendo lido por nenhum módulo do catálogo nem listado no manifesto.
