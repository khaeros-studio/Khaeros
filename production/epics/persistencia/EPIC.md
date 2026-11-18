# Epic: Save e perfil (persistência)

> **Layer**: Foundation
> **GDD**: design/gdd/save-e-perfil.md
> **Architecture Module**: Persistência / Save e perfil (user://, gravação atômica, perfil.cfg)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories persistencia`
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Armazém de arquivos em `user://` com gravação atômica e `.bak`, um perfil (`perfil.cfg`, seção `[vinculo]` opaca, chaves desconhecidas preservadas), binds, preferências e o arquivo de telemetria; repositórios por dono, gravação só fora do estado Jogo; portas de texto exportar/importar sem tela. Pode ser feito com armazém em memória antes dos experimentos; a gravação real espera EX-0013.

## Dependências entre épicos

- conteudo
- input
- experimentos-de-engine (EX-0013-P1..P7)

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **18 / 18** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-001 | Perfil único 0 e arquivo user://perfil.cfg em ConfigFile, caminhos por CaminhosDePersistencia.de(0) | ADR-0013 ✅ |
| TR-save-002 | RepositorioDePerfil com carregar sem falha e salvar com Error, gravação só por gravar_atomico do ArmazemDeArquivos | ADR-0013 ✅ |
| TR-save-003 | Seção [vinculo] opaca com contrato ler/escrever, especies com chave = id, campos_de_ids; seções futuras com o mesmo contrato | ADR-0013 ✅ |
| TR-save-004 | Carga uma vez por sessão depois do catálogo Pronto e antes da escolha de arma, em sequência pura | ADR-0013 ✅, ADR-0015 ✅, ADR-0004 ✅ |
| TR-save-005 | Catálogo em Falhou deixa o Save em Sem gravação, sem ler nem gravar o perfil | ADR-0013 ✅, ADR-0004 ✅ |
| TR-save-006 | Gatilhos de gravação: pacto_registrado, run_encerrada (vitória, derrota, abandono), Sair, reset, dupla escolhida | ADR-0015 ✅, ADR-0002 ✅, ADR-0013 ✅ |
| TR-save-007 | Gatilho marca pendente; grava no fim de passo fora de Jogo, nunca no meio dos eventos; gatilhos coalescidos em uma gravação | ADR-0013 ✅, ADR-0001 ✅, ADR-0002 ✅, ADR-0015 ✅ |
| TR-save-008 | Só grava se o texto mudou; texto determinístico byte a byte e sem dados pessoais | ADR-0013 ✅ |
| TR-save-009 | schema_version (ausente = 1) e cadeia pura de migração com migrações de conteúdo do dono; carga não grava | ADR-0013 ✅ |
| TR-save-010 | Falha ao gravar mantém estado em memória, PERSIST_FALHA_GRAVAR uma vez por sessão, sem laço de nova tentativa | ADR-0013 ✅ |
| TR-save-011 | Arquivo ausente, corrompido (cópia .bak incremental) ou de versão futura, com modo Sem gravação | ADR-0013 ✅ |
| TR-save-012 | Ids desconhecidos viram órfãs regravadas; ids de campos_de_ids viram vazio; chaves e seções desconhecidas preservadas na escrita | ADR-0013 ✅ |
| TR-save-013 | Interceptar fechar a janela, consolidar abandono e gravar antes de sair; falha mostra PERFIL_SAIR_SEM_SALVAR | ADR-0013 ✅, ADR-0015 ✅, ADR-0012 ✅ |
| TR-save-014 | Reset com duas confirmações e cópia .reset.bak, cancelado se a cópia falhar, sem tocar outros arquivos | ADR-0013 ✅, ADR-0012 ✅ |
| TR-save-015 | exportar_texto e importar_texto com a validação da carga, sem tela no MVP | ADR-0013 ✅ |
| TR-save-016 | Build de playtest lê e grava o perfil; PerfilNulo injetável sem if no Save | ADR-0013 ✅, ADR-0001 ✅ |
| TR-save-017 | Lógica pura injetada pelo Main sem Autoload, testes com ArmazemEmMemoria, só thread principal | ADR-0001 ✅, ADR-0013 ✅ |
| TR-save-018 | Avisos PERFIL_* uma vez por sessão só fora de Jogo, navegáveis por teclado e gamepad | ADR-0012 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/save-e-perfil.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
