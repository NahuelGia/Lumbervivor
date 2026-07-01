extends Control
class_name Tutorial

@onready var content_label = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ContentLabel
@onready var next_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NextButton
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/BackButton
@onready var skip_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SkipButton

var current_page = 0
var pages = [
	{
		"title": "BIENVENIDO A LUMBERVIVOR",
		"content": "Eres un leñador. De día: tala árboles y mejora tu equipo.\nDe noche: defiende tu cabaña de los zombies.\n\n¡Protege la cabaña a toda costa!"
	},
	{
		"title": "CONTROLES",
		"content": "MOVIMIENTO:\nW A S D\n\nATAQUE:\nCLIC IZQUIERDO\n\nEMPUJE:\nCLIC DERECHO\n\nBANCO DE TRABAJO:\nB (solo de día)"
	},
	{
		"title": "¿LISTO?",
		"content": "Tala árboles de día para obtener madera.\nMejora tu arma y defensa en el banco.\n\nCuando llegue la noche, protege tu cabaña.\nElimina todos los zombies para ganar.\n\n¡Que comience la supervivencia!"
	}
]

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
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

func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main.tscn")

func _update_content() -> void:
	var page = pages[current_page]
	content_label.text = "%s\n\n%s" % [page["title"], page["content"]]

	if current_page == pages.size() - 1:
		next_button.text = "Empezar Juego"
	else:
		next_button.text = "Siguiente"
