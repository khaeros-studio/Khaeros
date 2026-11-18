@abstract
class_name EscritorDeGlobais
extends RefCounted
## Contrato de escrita dos globais de shader do Pipeline Visual (ADR-0011 §3, Key Interfaces).
## Possui duas implementações concretas:
## - `EscritorGlobalRS` (primário, via `RenderingServer.global_shader_parameter_set`)
## - `EscritorPorMaterial` (plano B, via `ShaderMaterial.set_shader_parameter` por família)

@abstract func escrever(nome: StringName, valor: Variant) -> void
