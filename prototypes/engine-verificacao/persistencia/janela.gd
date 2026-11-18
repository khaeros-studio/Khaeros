# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends Node
## EX-0013-P6 (OS.shell_open da pasta) e P7 (interceptar fechamento, gravar perfil,
## PERFIL_SAIR_SEM_SALVAR / "Tentar de novo"). A 1ª gravação falha de propósito
## (arquivo somente-leitura); o "Tentar de novo" é simulado e a 2ª dá certo. Saída "EX|".

const RAIZ: String = "user://experimentos"
var _tentativas: int = 0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	DirAccess.make_dir_recursive_absolute(RAIZ)
	var p: String = RAIZ + "/perfil.cfg"
	var f := FileAccess.open(p, FileAccess.WRITE); f.store_string("[perfil]\nv=0\n"); f.close()
	FileAccess.set_read_only_attribute(p, true)
	var pasta: String = ProjectSettings.globalize_path(RAIZ)
	if "--shell" in OS.get_cmdline_user_args():
		print("EX|P6 shell_open(%s) err=%d" % [pasta, OS.shell_open(pasta)])
	print("EX|P7 pronto auto_accept_quit=%s" % get_tree().auto_accept_quit)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("EX|P7 NOTIFICATION_WM_CLOSE_REQUEST recebida; janela continua aberta")
		_tentar_salvar()

func _tentar_salvar() -> void:
	_tentativas += 1
	var p: String = RAIZ + "/perfil.cfg"
	var c := ConfigFile.new()
	c.set_value("perfil", "v", _tentativas)
	var f := FileAccess.open(p, FileAccess.WRITE)
	var err: int = FileAccess.get_open_error() if f == null else OK
	if f != null:
		f.store_string(c.encode_to_text())
		f.close()
	print("EX|P7 tentativa %d gravar perfil err=%d" % [_tentativas, err])
	if err != OK:
		print("EX|P7 mostraria PERFIL_SAIR_SEM_SALVAR; simulando clique em 'Tentar de novo'")
		FileAccess.set_read_only_attribute(p, false)
		await get_tree().create_timer(0.5).timeout
		_tentar_salvar()
		return
	print("EX|P7 gravado: %s; saindo" % FileAccess.get_file_as_string(p).c_escape())
	get_tree().quit()
