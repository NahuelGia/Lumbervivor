extends Control
class_name Tutorial

@onready var content_label = $VBoxContainer/ScrollContainer/ContentLabel
@onready var next_button = $VBoxContainer/NextButton
@onready var back_button = $VBoxContainer/BackButton

var current_page = 0
var pages = [
	{
		"title": "BIENVENIDO A LUMBERVIVOR",
		"content": "¡Eres un leñador que debe defender su cabaña de los zombies!\n\nEsta noche será larga y peligrosa.\nPrepárate para sobrevivir."
	},
	{
		"title": "¿DE QUÉ TRATA EL JUEGO?",
		"content": "OBJETIVO:\nProtege tu cabaña de las oleadas de zombies durante la noche.\n\nDURAN TE EL DÍA:\n• Tala árboles para obtener madera\n• Mejora tu hacha, armadura y fortaleza\n• Prepárate para la próxima noche\n\nDURAN TE LA NOCHE:\n• Los zombies atacan desde los bordes\n• ¡Defiende tu cabaña a toda costa!\n• Elimina todos los zombies para pasar a la siguiente ronda"
	},
	{
		"title": "CONTROLES BÁSICOS",
		"content": "MOVIMIENTO:\n• W - Arriba\n• A - Izquierda\n• S - Abajo\n• D - Derecha\n\nATAQUE:\n• CLIC IZQUIERDO - Atacar con el hacha\n\nEMPUJE:\n• CLIC DERECHO - Empujar zombies lejos\n\nBANCO DE TRABAJO:\n• B - Abre el banco de trabajo (solo de día)\n  Aquí mejoras tu equipo con la madera recolectada"
	},
	{
		"title": "RECURSOS Y MEJORAS",
		"content": "MADERA:\nObtén madera talando árboles durante el día.\nMáximo ~90 madera por día.\n\nMEJORAS (Costo en madera):\n• Hacha Mejorada (8) - Aumenta daño\n• Armadura de Madera (10) - Más salud\n• Barricada de Madera (6) - Fortalece la cerca\n\nLas mejoras se pierden si mueres.\nEs un juego roguelike: ¡sin progresión entre intentos!"
	},
	{
		"title": "ENEMIGOS",
		"content": "ZOMBIE NORMAL:\n50 HP, 10 daño, 75 px/s velocidad\n(Disponible desde el primer día)\n\nZOMBIE CORREDOR:\n35 HP, 8 daño, 130 px/s velocidad\n(Disponible a partir de la ronda 3)\n\nZOMBIE TANQUE:\n120 HP, 20 daño, 45 px/s velocidad\n(Disponible a partir de la ronda 3)\n\nLa dificultad aumenta:\n+10% vida y daño cada ronda"
	},
	{
		"title": "¡A JUGAR!",
		"content": "Ahora tienes todo lo que necesitas para sobrevivir.\n\nRecuerda:\n• Protege tu cabaña\n• Recolecta madera inteligentemente\n• Mejora lo que necesites\n• ¡NO MUERAS!\n\n¿Estás listo para enfrentarte a los zombies?\n\n¡Buena suerte, leñador!"
	}
]

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_update_content()

func _on_next_pressed() -> void:
	if current_page < pages.size() - 1:
		current_page += 1
		_update_content()
	else:
		# Ir al juego
		get_tree().change_scene_to_file("res://scenes/world/main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")

func _update_content() -> void:
	var page = pages[current_page]
	content_label.text = "%s\n\n%s" % [page["title"], page["content"]]

	if current_page == pages.size() - 1:
		next_button.text = "Empezar Juego"
	else:
		next_button.text = "Siguiente"
