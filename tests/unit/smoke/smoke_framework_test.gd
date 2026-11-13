## Teste de fumaça do framework: prova que o gdUnit4 roda headless.
## Não testa gameplay. Pode ser apagado quando houver testes reais.
extends GdUnitTestSuite


func test_framework_runs_assertion_passes() -> void:
	# Arrange
	var a: int = 2
	var b: int = 3

	# Act
	var total: int = a + b

	# Assert
	assert_int(total).is_equal(5)


func test_node_created_with_auto_free_leaves_no_orphan() -> void:
	# Arrange — auto_free evita órfão (saída 101 do gdUnit4)
	var node: Node = auto_free(Node.new())

	# Act
	node.name = "Smoke"

	# Assert
	assert_str(String(node.name)).is_equal("Smoke")
