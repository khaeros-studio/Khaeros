## CodexHistoria: base narrativa, prólogo cinematográfico, ecos de memória,
## bestiário de maldições por grau e doutrinas com Expansões de Domínio de Khaeros.
## Módulo puro (RefCounted), 100% determinístico e sem dependências de cena.
class_name CodexHistoria
extends RefCounted

## Registro de Ecos de Memória descobertos nesta instância (chave: eco_id -> bool).
var ecos_descobertos: Dictionary = {}


## Retorna os 3 atos do Prólogo da campanha de Khaeros em ordem sequencial.
static func prologo_atos() -> Array[Dictionary]:
	var atos: Array[Dictionary] = [
		{
			"titulo": "A Ruptura do Limiar",
			"subtitulo": "Ato I — O Dia em que a Beira Sangrou",
			"texto": (
				"Quando a fronteira do mundo rachou na Ruptura do Limiar, o Fluxo cru rasgou a pedra e a memória.\n"
				+ "Da sombra viva emergiram as Maldições — de Ecos errantes de Grau 3 a horrores de Grau Especial.\n"
				+ "Tudo o que respira além do pórtico aprende a primeira lei da Beira: nenhum poder se toma sem tributo.\n"
				+ "Restou apenas o silêncio frio do abismo e a certeza de que a fenda continua se alargando."
			),
			"img_key": "prologo_01",
		},
		{
			"titulo": "A Escola da Ordem de Khaeros",
			"subtitulo": "Ato II — Cinzel, Selo e Juramento",
			"texto": (
				"Sob lamparinas de âmbar, a Escola da Ordem de Khaeros forja exorcistas para enfrentar o que devora o mundo.\n"
				+ "Guiados por Halvar, Maren e Oreth, os aprendizes escolhem uma das cinco Doutrinas como filosofia de guerra.\n"
				+ "Cada arma sintoniza o Fluxo em rito e técnica até despertar sua forma absoluta: a Expansão de Domínio.\n"
				+ "Na Academia, ninguém sobrevive apenas pelo aço — sobrevive quem impõe sua vontade sobre a maldição."
			),
			"img_key": "prologo_02",
		},
		{
			"titulo": "A Descida pelos Quatro Círculos",
			"subtitulo": "Ato III — O Chamado do Iniciado",
			"texto": (
				"Seu juramento foi selado, Iniciado; agora o Portal do Limiar aguarda no pátio silencioso do Campus.\n"
				+ "Atravesse os quatro círculos: o Limiar da Beira, o Veio Instável, o Fosso das Cinzas e o Santuário Partido.\n"
				+ "Purifique as Maldições de Grau Especial que guardam cada abismo — ou dobre-as ao seu vínculo, se ousar.\n"
				+ "Cumpra o rito até o coração partido do santuário antes que a última fenda consuma Khaeros."
			),
			"img_key": "prologo_01",
		},
	]
	return atos


## Retorna os 12 Ecos de Memória / Monólitos de Lore (3 por região da campanha).
static func todos_ecos() -> Array[Dictionary]:
	var ecos: Array[Dictionary] = [
		{
			"id": "eco_limiar_01",
			"regiao": "limiar",
			"titulo": "A Primeira Lei da Beira",
			"autor": "Estela do Primeiro Pórtico",
			"texto": (
				"Na madrugada da Ruptura, a pedra não caiu — apenas esqueceu o que sustentava. "
				+ "Quem atravessa o Limiar descobre depressa por que os antigos selaram estas lajes: "
				+ "aqui o espaço cobra memória em troca de passo, e o ar frio de cinza apaga a sombra de quem hesita. "
				+ "Toda marca deixada no chão é uma advertência para o próximo Iniciado."
			),
		},
		{
			"id": "eco_limiar_02",
			"regiao": "limiar",
			"titulo": "Escala das Maldições",
			"autor": "Mestre Halvar — Vigília da Forja",
			"texto": (
				"A Ordem classifica o horror em quatro graus para que o medo tenha medida. "
				+ "Do Grau 3 ao Grau 1, Ecos e Anomalias respondem ao corte limpo e à postura firme; "
				+ "já no Grau Especial, a maldição não obedece mais à carne, mas a um domínio próprio. "
				+ "Se sua lâmina tremer diante de um Eco Perdido, volte ao Campus antes que o abismo reconheça seu nome."
			),
		},
		{
			"id": "eco_limiar_03",
			"regiao": "limiar",
			"titulo": "O Rei Sem Povo do Pórtico",
			"autor": "Crônica Rasgada do Altar",
			"texto": (
				"Contam os registros que o Soberano do Limiar já montou guarda diante do portal antes mesmo da Academia erguer suas muralhas de âmbar. "
				+ "Quando o véu rasgou, ele recusou o recuo e aceitou o ouro partido da própria fenda em seu peito. "
				+ "Agora desce em círculo de correntes partidas, cobrando em sangue o preço de cada juramento novo."
			),
		},
		{
			"id": "eco_veio_01",
			"regiao": "veio_instavel",
			"titulo": "Anatomia do Fluxo Cru",
			"autor": "Mestra Maren — Tratado do Pulso",
			"texto": (
				"No Veio Instável, o Fluxo não corre sob a terra; ele sangra pelas paredes em fendas magenta que invertem a luz e a sombra. "
				+ "Um exorcista imprudente vê apenas poder abundante, mas quem canaliza além da própria medida dissolve os contornos da mente. "
				+ "Ritmo, distância e silêncio valem mais que fúria quando o chão vibra em dois tempos."
			),
		},
		{
			"id": "eco_veio_02",
			"regiao": "veio_instavel",
			"titulo": "Olhos no Intervalo da Fenda",
			"autor": "Relato de Batedor da 3ª Turma",
			"texto": (
				"Os Espreitadores não caminham como bestas comuns — dobram a própria costura do ar e reaparecem onde a nossa guarda já passou. "
				+ "E quando uma Fenda Errante abre seu anel de seis estilhaços no centro da câmara, nenhuma armadura pesada basta sem leitura do telégrafo. "
				+ "Aprendemos tarde demais: no Veio, ficar imóvel por um segundo equivale a assinar a própria lápide."
			),
		},
		{
			"id": "eco_veio_03",
			"regiao": "veio_instavel",
			"titulo": "O Hexagrama que Nunca Fecha",
			"autor": "Monólito Partido do Veio",
			"texto": (
				"Três assinaturas arcanas fundiram-se neste círculo quando os primeiros arcanistas tentaram amarrar o Veio Instável com um único rito perpétuo. "
				+ "O feitiço sobreviveu aos seus autores, transformando o Guardião do Rito em uma lei cega de Fluxo puro. "
				+ "Ele não odeia os Iniciados — apenas executa a sentença de um contrato que ninguém mais sabe cancelar."
			),
		},
		{
			"id": "eco_fosso_01",
			"regiao": "fosso_das_cinzas",
			"titulo": "Onde a Forja Silenciou",
			"autor": "Placa Calcinada da Fundição",
			"texto": (
				"Antes da queda do terceiro círculo, as fornalhas do Fosso das Cinzas temperavam as lâminas da Ordem com Fluxo purificado. "
				+ "Quando uma erupção de Grau Especial partiu os pilares centrais, o calor consumiu bigornas, escudos e mestres em um único suspiro de brasa. "
				+ "Hoje, apenas o estalo das cinzas vivas lembra o dia em que o aço da Escola aprendeu a sangrar."
			),
		},
		{
			"id": "eco_fosso_02",
			"regiao": "fosso_das_cinzas",
			"titulo": "A Lição da Rocha e do Juramento",
			"autor": "Epitáfio da Cidadela Baixa",
			"texto": (
				"Os Baluartes de Cinza carregam nos ombros de pedra o peso de antigos defensores que se recusaram a abandonar os portões. "
				+ "Mesmo corrompidos pela escória, mantêm o ritmo lento e implacável de quem sustenta uma linha até o fim. "
				+ "Quem trilha a Doutrina do Guardião lê nesses monstros um espelho sombrio do próprio voto."
			),
		},
		{
			"id": "eco_fosso_03",
			"regiao": "fosso_das_cinzas",
			"titulo": "O Coração da Fornalha Morta",
			"autor": "Última Carta do Mestre Ferreiro",
			"texto": (
				"Não desçam ao fundo do Fosso procurando sobreviventes. "
				+ "O núcleo da grande forja engoliu nossos martelos e reuniu toda a cinza jurada num único corpo colossal que cai dos céus como meteoro. "
				+ "Se o Colosso de Cinza erguer os punhos, nenhuma muralha comum ficará inteira — rompa o alcance antes que o chão vire lava."
			),
		},
		{
			"id": "eco_santuario_01",
			"regiao": "santuario_partido",
			"titulo": "O Preço das Esferas Negras",
			"autor": "Mestre Oreth — Tomo do Véu Lacrado",
			"texto": (
				"Os ortodoxos chamam os Pactos de heresia porque temem segurar uma maldição pela garganta sem destruí-la. "
				+ "O verdadeiro Domador de Pactos absorve espíritos corrompidos em esferas negras de vínculo consentido e os liberta em enxames coordenados quando a linha ameaça romper. "
				+ "Mas lembre-se: toda esfera guardada dentro do peito sussurra no silêncio."
			),
		},
		{
			"id": "eco_santuario_02",
			"regiao": "santuario_partido",
			"titulo": "A Câmara dos Cinco Domínios",
			"autor": "Fragmento do Selo Central",
			"texto": (
				"Outrora, este santuário sustentava o equilíbrio entre as cinco filosofias de Khaeros sob uma cúpula intacta de cristal azul-gelo. "
				+ "Quando a fenda vertical abriu-se no altar principal, o próprio lugar foi partido entre memória e abismo. "
				+ "Cada laje flutuante aqui ainda guarda a ressonância de uma Expansão de Domínio desfeita no último combate."
			),
		},
		{
			"id": "eco_santuario_03",
			"regiao": "santuario_partido",
			"titulo": "Sentença Diante do Arconte",
			"autor": "Testamento da Primeira Vigília",
			"texto": (
				"O Arconte da Fenda não é um invasor vindo de fora — ele é a cicatriz viva da nossa maior ambição, coroado por seis estilhaços que orbitam o vazio. "
				+ "Quando seu Fluxo atingir o auge e você ativar o Selo, lembre-se do que uma Expansão de Domínio realmente é: "
				+ "não um feitiço aprendido, mas o instante em que sua filosofia reescreve o mundo ao redor."
			),
		},
	]
	return ecos


## Filtra e retorna cópias profundas dos Ecos pertencentes à região [param reg_id].
static func ecos_por_regiao(reg_id: String) -> Array[Dictionary]:
	var filtrados: Array[Dictionary] = []
	if reg_id.is_empty():
		return filtrados
	var ecos: Array[Dictionary] = todos_ecos()
	for eco: Dictionary in ecos:
		var eco_regiao: String = String(eco.get("regiao", ""))
		if eco_regiao == reg_id:
			filtrados.append(eco.duplicate(true))
	return filtrados


## Retorna uma cópia profunda do Eco correspondente a [param eco_id], ou {} caso não exista.
static func obter_eco(eco_id: String) -> Dictionary:
	if eco_id.is_empty():
		return {}
	var ecos: Array[Dictionary] = todos_ecos()
	for eco: Dictionary in ecos:
		var id_atual: String = String(eco.get("id", ""))
		if id_atual == eco_id:
			return eco.duplicate(true)
	return {}


## Retorna as 12 entradas canônicas do Bestiário (3 por região, cobrindo Patamares 1 a 4).
static func bestiario() -> Array[Dictionary]:
	var entradas: Array[Dictionary] = [
		{
			"id": "eco_perdido",
			"nome": "Eco Perdido",
			"grau": "Grau 3",
			"regiao": "limiar",
			"patamar": 1,
			"papel": "Horda",
			"sinal_sensorial": (
				"Arrastar seco de tecido sobre a pedra e pegadas úmidas de tinta preta "
				+ "que evaporam antes do calcanhar tocar a laje."
			),
			"espolio": "Tinta de Memória Fria + Fivela Sem Inscrição",
			"descricao": (
				"Vestígio humano esvaziado pela Ruptura: um capuz de névoa fria que se desfaz em fiapos de tinta "
				+ "sem sequer projetar sombra no chão. Alimenta-se do calor residual de juramentos e acelera quando marcha em bando."
			),
			"tatica": (
				"Avança em convergência de enxame e ganha velocidade com outros Ecos vivos. "
				+ "Reduza a horda cedo, quebre a Ceifa do Esquecimento com golpes pesados ou esquive através do arco para punir pelas costas."
			),
		},
		{
			"id": "vulto_mudo",
			"nome": "Vulto Mudo",
			"grau": "Grau 2",
			"regiao": "limiar",
			"patamar": 2,
			"papel": "Oportunista",
			"sinal_sensorial": (
				"Silêncio súbito que apaga o eco dos próprios passos enquanto riscos paralelos "
				+ "de garras invisíveis cortam a névoa rente às bordas."
			),
			"espolio": "Tendão de Tinta Silenciosa + Colar de Amarra Rompida",
			"descricao": (
				"Resíduo veloz de Anomalia envolto em tinta silenciosa; sem lamento humano, carrega apenas "
				+ "instinto predador faminto por guardas abertas. Espécimes lúcidos chegam a consentir vínculos com Pactos."
			),
			"tatica": (
				"Circunda os flancos esperando você gastar a esquiva e fecha o espaço com o Bote de Penumbra. "
				+ "Esquive perpendicularmente ao corredor para punir sua derrapagem e cuidado com as Paredes de Sombra abaixo de 50% de Vida."
			),
		},
		{
			"id": "soberano_do_limiar",
			"nome": "Soberano do Limiar",
			"grau": "Grau Especial",
			"regiao": "limiar",
			"patamar": 4,
			"papel": "Solo/Chefe",
			"sinal_sensorial": (
				"Cheiro de ferro frio e ozônio, retinir de correntes invisíveis contra os quatro pilares "
				+ "e um círculo de selos dourados rachados queimando a poeira."
			),
			"espolio": "Elo de Ouro Partido + Selo do Juramento Subjugado",
			"descricao": (
				"Maldição Primordial de Grau Especial que reivindica a coroa quebrada do primeiro círculo. "
				+ "Desce envolto em selos dourados e correntes partidas, exigindo tributo de cada juramento novo."
			),
			"tatica": (
				"Imune a cambaleio, alterna quatro padrões legíveis: corte frontal, Irrupção contra pilares, "
				+ "Pulso de Soberania com 12 projéteis e Convergência com puxão e Ecos. Aos 50% de Vida entra em Fúria com recuperações 40% menores."
			),
		},
		{
			"id": "anomalia_menor",
			"nome": "Anomalia Menor",
			"grau": "Grau 3",
			"regiao": "veio_instavel",
			"patamar": 1,
			"papel": "Controlador",
			"sinal_sensorial": (
				"Zumbido elétrico em dois tempos e cheiro acre de ozônio queimado "
				+ "emanando de crostas cristalinas magenta nos cantos da câmara."
			),
			"espolio": "Prisma de Fluxo Cru + Lente de Observação Fraturada",
			"descricao": (
				"Forma instável condensada no excesso de Fluxo cru do Veio Instável (com exemplares desgarrados "
				+ "vazando ao Limiar), marcada por cristais facetados e um núcleo emissor magenta que vigia dos flancos."
			),
			"tatica": (
				"Recua ao menor sinal de aproximação e dispara a Agulha de Fluxo em corredor reto telegrafado. "
				+ "Esquive lateralmente, quebre o núcleo exposto com golpe pesado e afaste-se do Estilhaço de Sobrecarga ao finalizá-la."
			),
		},
		{
			"id": "espreitador_da_fenda",
			"nome": "Espreitador da Fenda",
			"grau": "Grau 2",
			"regiao": "veio_instavel",
			"patamar": 2,
			"papel": "Oportunista",
			"sinal_sensorial": (
				"Odor de vidro partido, estalo seco duplo atrás dos ombros "
				+ "e uma costura violeta de ar rasgado pairando a um palmo do chão."
			),
			"espolio": "Fibrila de Espaço Rasgado + Insígnia da 3ª Turma Partida ao Meio",
			"descricao": (
				"Predador refinado do Veio Instável que dobra a costura do espaço para flanquear exorcistas "
				+ "distraídos. Sua silhueta em crescente se dissolve em fumaça violeta antes de morder pela retaguarda."
			),
			"tatica": (
				"Inicia o preparo à distância média e teleporta-se atrás do alvo causando dano ampliado e Abalo pelas costas. "
				+ "Mantenha deslocamento lateral após o telégrafo e respeite o Rastro Cortante que deixa ao recuar ferido."
			),
		},
		{
			"id": "guardiao_do_rito",
			"nome": "Guardião do Rito",
			"grau": "Grau Especial",
			"regiao": "veio_instavel",
			"patamar": 4,
			"papel": "Solo/Chefe",
			"sinal_sensorial": (
				"Os veios magenta das paredes apagam-se num silêncio metálico, dando lugar ao cheiro "
				+ "de cera quente e a um hexagrama dourado gravado sob luz zenital dura."
			),
			"espolio": "Assinatura de Bronze Ritual + Contrato Sem Cláusula de Saída",
			"descricao": (
				"Entidade cerimonial nascida da convergência de três ecos arcanos sobre um hexagrama perpétuo. "
				+ "Como uma lei cega do Veio Instável, executa descargas geométricas para desfazer runas em pó."
			),
			"tatica": (
				"Mantém distância disparando leques triplos velozes e triângulos explosivos que expulsam dos três pilares. "
				+ "Use as colunas para desestabilizar sua simetria, esquive na diagonal através do leque e pressione na recarga do cetro."
			),
		},
		{
			"id": "brasa_errante",
			"nome": "Brasa Errante",
			"grau": "Grau 2",
			"regiao": "fosso_das_cinzas",
			"patamar": 2,
			"papel": "Controlador",
			"sinal_sensorial": (
				"Chiado contínuo de ferro mergulhado em óleo frio, cheiro sufocante de enxofre adocicado "
				+ "e gotas de escória vitrificada estalando sobre o piso."
			),
			"espolio": "Carvão de Fluxo Vitrificado + Cinzel Derretido da Forja Baixa",
			"descricao": (
				"Núcleo flutuante de escória viva nascido dos cadinhos estilhaçados na queda do Fosso das Cinzas. "
				+ "Três cascas negras orbitam seu coração incandescente enquanto nega terreno com poças ardentes."
			),
			"tatica": (
				"Lança arcos lentos de escória que deixam poças de Queimadura para encurralar você diante de brutos. "
				+ "Empurre-a para longe das zonas seguras, puna seu núcleo quando as cascas abrem e finalize sem deixar ativar a Têmpera Reversa."
			),
		},
		{
			"id": "baluarte_de_cinza",
			"nome": "Baluarte de Cinza",
			"grau": "Grau 1",
			"regiao": "fosso_das_cinzas",
			"patamar": 3,
			"papel": "Bruto",
			"sinal_sensorial": (
				"Tremor lento que faz pedregulhos saltarem no chão, cheiro de basalto queimado "
				+ "e dois sulcos fundos de punhos pétreos arrastados na cinza."
			),
			"espolio": "Placa de Basalto Jurado + Voto de Ferro Calcinado",
			"descricao": (
				"Massa pétrea revestida de cinza vitrificada e brasas antigas, nascida do voto dos defensores "
				+ "da forja silenciada. Avança como muralha ambulante, sustentando impactos frontais até desabar sobre o piso."
			),
			"tatica": (
				"Mitiga golpes frontais leves e desencadeia o Quebra-Limiar Sísmico em amplo raio. "
				+ "Contorne para o flanco, aplique Abalo ou golpes pesados para rachar sua guarda e leia a segunda onda abaixo de 50% de Vida."
			),
		},
		{
			"id": "colosso_de_cinza",
			"nome": "Colosso de Cinza",
			"grau": "Grau Especial",
			"regiao": "fosso_das_cinzas",
			"patamar": 4,
			"papel": "Solo/Chefe",
			"sinal_sensorial": (
				"Chuva muda de fuligem acesa caindo do teto, ar seco que distorce a visão "
				+ "e o rugido grave de um fole gigante antes do impacto meteórico."
			),
			"espolio": "Núcleo de Cinza Primordial + Martelo Rachado do Mestre Ferreiro",
			"descricao": (
				"Titã forjado nas brasas extintas da antiga fundição da Ordem, que despenca do alto como meteoro de magma. "
				+ "Cada esmagamento racha as lajes do Fosso com ondas ígneas que consomem aço e osso."
			),
			"tatica": (
				"Seus golpes lentos cobrem arcos gigantescos de 260 px e evoluem para quedas de meteoro em Fornalha Aberta. "
				+ "Evacue por completo a zona incandescente e concentre dano crítico na grade peitoral aberta durante sua recuperação."
			),
		},
		{
			"id": "fenda_errante",
			"nome": "Fenda Errante",
			"grau": "Grau 1",
			"regiao": "santuario_partido",
			"patamar": 2,
			"papel": "Controlador",
			"sinal_sensorial": (
				"Estalo agudo de vidro partindo em câmera lenta, cheiro metálico de ar rarefeito "
				+ "e poeira sugada em espiral antes do rasgo se abrir."
			),
			"espolio": "Estilhaço de Cúpula Partida + Diapasão de Cristal Azul-Gelo",
			"descricao": (
				"Ruptura viva nascida da cúpula despedaçada do Santuário (com exemplares à deriva arrastados até o Veio), "
				+ "sem carne nem osso. Acumula pressão de domínios rompidos até estourar em múltiplas direções."
			),
			"tatica": (
				"Flutua imune ao piso e dispara anéis simultâneos de seis estilhaços em 60 graus — dobrando com anel defasado abaixo de 50% de Vida. "
				+ "Use os vãos angulares, esquive através da onda ou empurre-a com golpe pesado para desviar o eixo do disparo."
			),
		},
		{
			"id": "coro_fraturado",
			"nome": "Coro Fraturado",
			"grau": "Grau 1",
			"regiao": "santuario_partido",
			"patamar": 3,
			"papel": "Líder",
			"sinal_sensorial": (
				"Acorde dissonante de cinco vozes fora de sincronia vibrando no maxilar, "
				+ "odor frio de incenso velho e cinco anéis concêntricos riscados no pó."
			),
			"espolio": "Corda Vocal de Cristal Dissonante + Partitura Rasgada dos Cinco Selos",
			"descricao": (
				"Vestígio fundido de cinco oficiantes do Santuário que entoaram um Selo conjunto no instante da ruptura. "
				+ "Coroado por um halo quebrado de cinco placas, liga fios de ressonância para fortalecer outras maldições."
			),
			"tatica": (
				"Recua para a retaguarda acelerando e protegendo até dois aliados vinculados. "
				+ "Fure a linha para interromper o Cântico da Ruptura com golpe pesado — quebrando todos os escudos da sala — e leia os três anéis do Requiém."
			),
		},
		{
			"id": "arconte_da_fenda",
			"nome": "Arconte da Fenda",
			"grau": "Grau Especial",
			"regiao": "santuario_partido",
			"patamar": 4,
			"papel": "Solo/Chefe",
			"sinal_sensorial": (
				"Queda súbita de gravidade por meio segundo, gosto metálico de ozônio no ar gelado "
				+ "e uma fenda vertical de luz negra cercada por seis estilhaços mudos."
			),
			"espolio": "Coração de Fenda Selado + Lascas da Cúpula de Cristal Azul-Gelo",
			"descricao": (
				"Regente supremo de Grau Especial e cicatriz viva da maior ambição da Ordem no Santuário Partido. "
				+ "Cercado por seis cristais orbitais, impõe a prova definitiva a toda doutrina que ousa desafiá-lo."
			),
			"tatica": (
				"Seus seis cristais anunciam cada ataque antes do piso: leques de cinco projéteis, dobras entre pilares e invocações de Ecos. "
				+ "Gire pelos quatro pilares, limpe os flancos e guarde o Selo [Q] para punir após as rajadas cruzadas da Fase 2."
			),
		},
	]
	return entradas


## Retorna as 4 Fichas de Ambiente Ativo canônicas (1 por região da campanha).
static func ambientes_ativos() -> Array[Dictionary]:
	var ambientes: Array[Dictionary] = [
		{
			"id": "lajes_suspensas_beira",
			"regiao": "limiar",
			"nome": "As Lajes Suspensas da Beira",
			"efeito_passivo": (
				"Tributo da Hesitação: permanecer mais de 3 s parado no mesmo quadrante ergue geada "
				+ "de tinta que desacelera a caminhada até você se deslocar ou esquivar."
			),
			"perigos_dinamicos": [
				(
					"Laje que Esquece: placas periféricas racham por 1,2 s antes de afundar na névoa por 4 s, "
					+ "encurtando rotas de fuga e punindo quedas com dano de posicionamento."
				),
				(
					"Sopro de Névoa Cega: rajadas rasantes varrem faixas laterais anunciadas por fiapos horizontais, "
					+ "empurrando combatentes na direção do precipício sem encobrir telégrafos."
				),
			],
			"neutralizacao": (
				"Arremesso de Borda: use golpes pesados, escudos e empurrões para lançar Ecos Perdidos e Vultos Mudos "
				+ "sobre lajes prestes a afundar ou contra o Sopro, obtendo abates instantâneos ou atordoamento prolongado."
			),
		},
		{
			"id": "fissuras_obsidiana_veio",
			"regiao": "veio_instavel",
			"nome": "As Fissuras de Obsidiana do Veio",
			"efeito_passivo": (
				"Pulso em Dois Tempos: o Fluxo cru sob o piso pulsa num compasso audível que acelera "
				+ "brevemente projéteis e descargas arcanas a cada batida forte."
			),
			"perigos_dinamicos": [
				(
					"Sangria de Veio: fissuras diagonais brilham em magenta por 0,9 s e ejetam um jato estreito "
					+ "de Fluxo cru que fatia a câmara em dois setores isolados."
				),
				(
					"Eco de Sobrecarga: disparar o Selo ou alto custo de Fluxo sobre uma rachadura ativa sem ler "
					+ "o ritmo devolve um anel de estilhaços cristalinos após 0,6 s."
				),
			],
			"neutralizacao": (
				"Condução de Fissura: atraia ou empurre inimigos para cima de uma rachadura prestes a sangrar — "
				+ "o jato de Fluxo cru fere e aplica Abalo também nos adversários, quebrando sua postura."
			),
		},
		{
			"id": "fornalha_morta_fosso",
			"regiao": "fosso_das_cinzas",
			"nome": "A Fornalha Morta do Fosso",
			"efeito_passivo": (
				"Sobreaquecimento da Escória: permanecer mais de 2,5 s sobre grelhas metálicas incandescentes "
				+ "acumula calor até aplicar Queimadura, forçando duelos nas passarelas frias de basalto."
			),
			"perigos_dinamicos": [
				(
					"Abertura de Fole: respiradouros laterais sopram brasa sobre as grelhas centrais após 1,0 s "
					+ "de chiado, causando dano térmico e reacendendo poças de escória próximas."
				),
				(
					"Queda de Escória do Cadinho: impactos sísmicos pesados soltam gotas incandescentes do teto "
					+ "em 2 a 3 círculos telegrafados (0,8 s), abrindo novas poças temporárias de Queimadura."
				),
			],
			"neutralizacao": (
				"Válvulas de Têmpera: golpeie os contrapesos de corrente nas bordas da câmara para descarregar "
				+ "ar frio rasante, apagando poças ativas e aplicando Abalo em inimigos superaquecidos como Brasas e o Colosso."
			),
		},
		{
			"id": "observatorio_despedacado",
			"regiao": "santuario_partido",
			"nome": "O Observatório Despedaçado",
			"efeito_passivo": (
				"Ressonância de Domínio Desfeito: sempre que você ou um chefe libera técnicas de alto Fluxo, "
				+ "as lajes de cristal azul-gelo ampliam levemente o ganho de Fluxo por acertos limpos nos 3 s seguintes."
			),
			"perigos_dinamicos": [
				(
					"Cicatrização da Fenda Vertical: fendas finas rasgam as emendas entre lajes flutuantes "
					+ "(0,85 s de linha magenta) e fecham com puxão gravitacional que fere quem permanece sobre a junta."
				),
				(
					"Refração de Cristal Caído: projéteis inimigos que atingem arestas de cristal nas bordas "
					+ "externas dividem-se em dois estilhaços lentos a 45 graus, punindo recuo colado às paredes."
				),
			],
			"neutralizacao": (
				"Sintonizar os Pilares de Cristal: atraia descargas inimigas contra os quatro pilares centrais "
				+ "para carregá-los sem refração; um golpe pesado num pilar carregado emite onda purificadora que "
				+ "cancela projéteis próximos e quebra escudos de líderes como o Coro Fraturado."
			),
		},
	]
	return ambientes


## Retorna as 5 Doutrinas jogáveis com seus nomes canônicos, papéis e Expansões de Domínio.
static func doutrinas_codex() -> Array[Dictionary]:
	var doutrinas: Array[Dictionary] = [
		{
			"id": "lamina",
			"nome": "Lâmina do Juramento",
			"dominio": "Santuário da Lâmina Perpétua",
			"papel": "Duelista de Curta Distância e Quebra de Postura",
			"descricao": (
				"Ensinada por Mestre Halvar, a doutrina molda o Fluxo em aço reto e compromisso no impacto. "
				+ "Encadeia combos de três cortes cujo golpe final quebra a preparação inimiga e fecha espaços com investidas precisas. "
				+ "Ao liberar o Selo máximo, manifesta o Santuário da Lâmina Perpétua: anéis dourados de lâminas giratórias que julgam toda maldição no alcance."
			),
		},
		{
			"id": "ressonancia",
			"nome": "Ressonância de Sangue",
			"dominio": "Horizonte da Ressonância Infinita",
			"papel": "Arcanista de Alcance e Controle Espacial",
			"descricao": (
				"Preservada por Mestra Maren, troca vitalidade bruta por alcance letal e leitura fria da arena. "
				+ "Projeta pulsos arcanos contínuos à distância e repele cercos com ondas radiais antes que o perigo toque sua guarda. "
				+ "No ápice do Fluxo, abre o Horizonte da Ressonância Infinita: um vórtice gravitacional rúnico que dispara oito orbes em todas as direções."
			),
		},
		{
			"id": "pactos",
			"nome": "Domador de Pactos",
			"dominio": "Vórtice dos Mil Pactos",
			"papel": "Manipulador de Maldições, Esferas Negras e Enxames",
			"descricao": (
				"Guardada nos arquivos sombrios de Mestre Oreth, revela o Domador de Pactos como um Manipulador de Maldições "
				+ "que subjuga espíritos corrompidos, os absorve em esferas negras de vínculo consentido e os liberta em enxames implacáveis. "
				+ "Lutando à distância com virotes de marcação e familiares selados em osso, transborda o Fluxo no Vórtice dos Mil Pactos: "
				+ "um selo sombrio que rasga a arena em faixas negras e precipita enxames de maldições sobre os alvos mais próximos."
			),
		},
		{
			"id": "guardiao",
			"nome": "Égide do Guardião",
			"dominio": "Cidadela Inquebrável do Juramento",
			"papel": "Vanguarda Blindada e Sustentação Defensiva",
			"descricao": (
				"Inspirada na imutabilidade dos antigos bastiões da Ordem, transforma o corpo do Iniciado em muralha viva. "
				+ "Empunha o escudo-bastião com vitalidade elevada para esmagar preparações inimigas e erguer proteção temporária nos momentos críticos. "
				+ "Quando o Selo desperta, constrói a Cidadela Inquebrável do Juramento: um domo hexagonal dourado que reforça escudos e repele o cerco."
			),
		},
		{
			"id": "veu",
			"nome": "Lâminas do Véu",
			"dominio": "Eclipse do Véu Silencioso",
			"papel": "Infiltrador Ágil de Golpes Críticos e Sombra",
			"descricao": (
				"Forjada nas vigílias furtivas das fendas profundas, privilegia mobilidade extrema, flanco e precisão letal. "
				+ "Combina estocadas velozes com lampejos sombrios para cruzar através das linhas adversárias sem perder o ritmo. "
				+ "Ao alcançar o Selo pleno, desencadeia o Eclipse do Véu Silencioso: relâmpagos violeta-ciano que encadeiam golpes críticos garantidos entre múltiplos alvos."
			),
		},
	]
	return doutrinas


## Helper rápido que retorna o nome da Expansão de Domínio correspondente a [param arma_id].
static func nome_dominio(arma_id: StringName) -> String:
	match arma_id:
		&"lamina":
			return "Santuário da Lâmina Perpétua"
		&"ressonancia":
			return "Horizonte da Ressonância Infinita"
		&"pactos":
			return "Vórtice dos Mil Pactos"
		&"guardiao":
			return "Cidadela Inquebrável do Juramento"
		&"veu":
			return "Eclipse do Véu Silencioso"
	return ""


## Registra a descoberta de [param eco_id]. Retorna true se for inédito, false se já descoberto ou vazio.
func descobrir_eco(eco_id: String) -> bool:
	if eco_id.is_empty():
		return false
	if bool(ecos_descobertos.get(eco_id, false)):
		return false
	ecos_descobertos[eco_id] = true
	return true


## Indica se [param eco_id] já foi descoberto nesta instância.
func foi_descoberto(eco_id: String) -> bool:
	if eco_id.is_empty():
		return false
	return bool(ecos_descobertos.get(eco_id, false))


## Retorna a quantidade total de Ecos únicos descobertos nesta instância.
func total_ecos_descobertos() -> int:
	var valores: Array = ecos_descobertos.values()
	var total: int = 0
	for i: int in range(valores.size()):
		if bool(valores[i]):
			total += 1
	return total
