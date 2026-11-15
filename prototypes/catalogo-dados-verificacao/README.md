# Verificação do catálogo de dados

Experimento executado em 2026-11-14 com Godot 4.7.2.stable.official.ed1daf0bf para apoiar o ADR-0004. Resultado de 16 verificações aprovadas, zero falhas e saída 0.

## Executar

No PowerShell, a partir da raiz do repositório.

```powershell
$catalogProbeLog = Join-Path $env:TEMP 'khaeros-catalog-probe.log'
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --log-file $catalogProbeLog --path 'prototypes/catalogo-dados-verificacao' --script main.gd
```

As duas definições de teste são gravadas numa pasta temporária própria por processo, cujo caminho aparece no resultado. O script normaliza separadores Windows para que os caminhos externos sejam serializados corretamente nos arquivos `.tres`.

## Resultados

- A cópia padrão com `duplicate_deep()` criou outro pai e manteve a referência ao recurso externo filho.
- `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` copiou o filho externo. Alterar a cópia preservou o valor original.
- A carga padrão reutilizou o recurso e o valor antigo após editar o arquivo filho.
- `ResourceLoader.CACHE_MODE_IGNORE_DEEP` criou pai e filho independentes, leu o valor atualizado do arquivo e preservou a instância antiga.
- `HashingContext.HASH_SHA256` produziu o vetor conhecido de `abc`, `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.

O teste confirma essas APIs em uma árvore pequena de recursos. A serialização canônica do catálogo, exportação release e orçamento de carga dependem dos seus testes de implementação.
