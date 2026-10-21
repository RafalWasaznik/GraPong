class_name PilkaAPI
extends CharacterBody2D

@onready var dzwiek_paletka: AudioStreamPlayer = $DzwiekPaletka
@onready var dzwiek_sciana: AudioStreamPlayer = $DzwiekSciana


func przyspiesz(_mnoznik: float = 1.15) -> void:
	pass


func pokaz_efekt_mocnego_odbicia() -> void:
	pass


func pokaz_efekt_strefy_przyspieszenia() -> void:
	pass


func animuj_rozmiar(_proporcja: float, _czas: float = 0.55) -> void:
	pass


func reset() -> void:
	pass


func dodaj_dodatkowa_pilke(_pozycja: Vector2) -> void:
	pass
