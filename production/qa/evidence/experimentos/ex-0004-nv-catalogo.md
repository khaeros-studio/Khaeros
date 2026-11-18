# EX-0004-NV — catálogo (evidência)

- **Data**: 2026-11-16 · **Engine**: Godot 4.7.2.stable.official.ed1daf0bf (build padrão) · **Máquina**: Ryzen 5 5600H, SSD, Windows 11 10.0.26300
- **Protótipo**: `prototypes/engine-verificacao/catalogo/` (`probe.gd` como `--script`, `def.gd`, `export_presets.cfg`, `assets/data/canon/teste.csv` + `assets/data/outro/controle.csv` com `importer="keep"`). `res://gerado/` tem 40 pais `.tres` + 40 filhos externos `.tres` (gerados pelo modo `gerar`).
- **Templates de exportação**: não instalados. `--export-pack` funciona sem templates, então o `.pck` exportado foi gerado e executado com o binário do editor (`--main-pack`). Isso cobre "conteúdo exportado"; **não** cobre o binário do template de release (`OS.is_debug_build()` deu true em todas as execuções).

## Reproduzir

```bash
cd prototypes/engine-verificacao/catalogo
godot --headless --path . --import
godot --headless --path . --script probe.gd -- --modo=gerar     # uma vez
godot --headless --path . --script probe.gd -- --modo=tudo
godot --path . --script probe.gd -- --modo=hash                 # janela
godot --headless --path . --export-pack "Windows Desktop" <saida>.pck
godot --headless --main-pack <saida>.pck --script res://probe.gd -- --modo=hash
godot --headless --main-pack <saida>.pck --script res://probe.gd -- --modo=carga   # 5x
```

## Resultados

| # | Item | Observado | Resultado |
|---|---|---|---|
| 1 | `HashingContext` SHA-256 sobre int64 LE (`encode_s64(-1234567890123)`), float64 LE (`encode_double(0.1)`) e UTF-8 (`"Khaeros ação vínculo"`) | bytes `35fb048ee0feffff9a9999999999b93f4b686165726f732061c3a7c3a36f2076c3ad6e63756c6f`; SHA-256 `b755d9ea874182a58e4ba312ff981aee1ba4960eaaed9518e1924a2d30eedad2` **idêntico** em: headless no projeto, janela no projeto, `.pck` exportado, e Python `hashlib` (referência independente) | **VERIFICADO** (editor e pck exportado). Template de release: pendente |
| 2 | `ResourceLoader.load(p, "", CACHE_MODE_IGNORE_DEEP)` com manifesto de 40 entradas e filho externo editado no disco (pai `valor 3→3003`, filho `103→4242`) | `CACHE_MODE_REUSE`: devolve a mesma instância, valores antigos (3/103). `IGNORE_DEEP`: instância nova com 3003/4242; a instância antiga fica intacta; recarga das 40 entradas com `IGNORE_DEEP` ok 40/40 | **VERIFICADO** |
| 3 | CSV com `importer="keep"` | `--import` não gerou `.translation` nem nada em `.godot/imported/`; `FileAccess` lê o CSV (39 bytes, acentos íntegros) no headless e na janela. No `.pck` com `exclude_filter="assets/data/canon/*"` e `include_filter="*.csv"`: `canon/teste.csv` **ausente** (0 ocorrências; no pck, `FileAccess` → erro 7 `ERR_FILE_NOT_FOUND`), `outro/controle.csv` **presente** (controle) | **VERIFICADO**. O CSV `keep` entra no export se não for excluído: o filtro é obrigatório |
| 4 | `Resource.DEEP_DUPLICATE_ALL` | ClassDB: enum `Resource.DeepDuplicateMode` = `DEEP_DUPLICATE_NONE=0, DEEP_DUPLICATE_INTERNAL=1, DEEP_DUPLICATE_ALL=2`; `duplicate_deep` existe. `duplicate_deep()` padrão **não** copia o filho externo (compartilha); `duplicate_deep(DEEP_DUPLICATE_ALL)` copia, e mexer na cópia não altera o original | **VERIFICADO** (nome e comportamento conforme o ADR) |
| 5 | Carga síncrona de 40 `.tres` + 40 filhos externos, 5 processos novos | Projeto (texto `.tres`): 165,3 / 168,7 / 140,7 / 152,0 / 160,8 ms → **mediana 160,8 ms**. `.pck` exportado (convertido para binário): 101,5 / 103,5 / 84,8 / 86,2 / 73,3 ms → **mediana 86,2 ms**. Ambos abaixo de 250 ms. Cache de arquivos do SO quente (não é carga fria de disco) | **Registrado** (advisory; sem assert) |

Observação do export: o `--export-pack` converte `.tres` para binário e grava `*.tres.remap`; o script vai como `.gd.remap`. Os caminhos `res://...tres` continuam valendo no `.pck`.

## O que o ADR-0004 precisa mudar (aplicar pelo lead-programmer)

1. VR(1), VR(2), VR(3) e a constante `DEEP_DUPLICATE_ALL`: marcar verificados no 4.7.2 (editor + `.pck`), com o hash de referência acima.
2. Registrar que o CSV `keep` **é** empacotado por padrão quando o filtro o inclui; o preset precisa de `exclude_filter` com `assets/data/canon/*` (e o CI deve conferir a ausência no `.pck`).
3. Registrar AC-38: mediana 160,8 ms (texto, editor) / 86,2 ms (binário, pck) para 80 recursos.
4. Pendente: paridade do hash e tempo de carga no **template de release** — requer instalar os templates 4.7.2.
