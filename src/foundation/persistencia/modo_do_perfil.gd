## Modo de sessão do perfil (ADR-0013 §7, Decisões 1; save-e-perfil "States and Transitions").
##
## Exemplo:
## [codeblock]
## if repositorio.carregar() == ModoDoPerfil.Valor.SEM_GRAVACAO:
##     pass  # reset indisponível, nada será gravado
## [/codeblock]
class_name ModoDoPerfil
extends RefCounted

## [code]NORMAL[/code]: grava nos gatilhos. [code]SEM_GRAVACAO[/code]: o arquivo nunca
## é tocado nesta sessão (versão futura, cópia de backup falhou ou catálogo Falhou).
enum Valor { NORMAL, SEM_GRAVACAO }
