class_name BonusKulki
extends Area2D

enum TypBonusu { PRZYSPIESZENIE, DWIE_PILKI }

const CZAS_POJAWIENIA = 0.22
const CZAS_ZEBRANIA = 0.2

@export var typ: TypBonusu = TypBonusu.PRZYSPIESZENIE

var czas_animacji = 0.0
var pozycja_bazowa_y = 0.0
var zebrany = false
var czas_zebrania = 0.0


func _ready() -> void:
	add_to_group("bonus")
	pozycja_bazowa_y = position.y
	body_entered.connect(_on_body_entered)
	scale = Vector2(0.78, 0.78)
	modulate.a = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	czas_animacji += delta
	if zebrany:
		czas_zebrania += delta
		var postep_zebrania = clampf(czas_zebrania / CZAS_ZEBRANIA, 0.0, 1.0)
		scale = Vector2.ONE * (1.0 + postep_zebrania * 0.16)
		modulate.a = 1.0 - postep_zebrania
		queue_redraw()
		if postep_zebrania >= 1.0:
			queue_free()
		return

	var postep = clampf(czas_animacji / CZAS_POJAWIENIA, 0.0, 1.0)
	var wygladzone = 1.0 - pow(1.0 - postep, 3.0)
	scale = Vector2.ONE * lerpf(0.78, 1.0, wygladzone)
	modulate.a = wygladzone
	position.y = pozycja_bazowa_y + sin(czas_animacji * 2.4) * 2.4
	queue_redraw()


func _draw() -> void:
	var kolor = _kolor_bonusu()
	if zebrany:
		var postep = clampf(czas_zebrania / CZAS_ZEBRANIA, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 18.0 + postep * 23.0, 0.0, TAU, 48, Color(kolor, 1.0 - postep), 2.2, true)
		return

	var puls = 0.5 + 0.5 * sin(czas_animacji * 3.0)
	var promien = 20.0 + sin(czas_animacji * 3.5) * 0.8
	draw_circle(Vector2.ZERO, promien + 8.0, Color(kolor, 0.055 + puls * 0.035))
	draw_circle(Vector2(0.0, 3.0), promien + 1.0, Color(0.0, 0.0, 0.0, 0.32))
	draw_circle(Vector2.ZERO, promien, _kolor_obwodki())
	draw_circle(Vector2.ZERO, promien - 3.0, kolor)
	draw_arc(Vector2.ZERO, promien + 3.0, czas_animacji * 0.45, czas_animacji * 0.45 + 2.1, 32, _kolor_blysku(), 1.5, true)

	if typ == TypBonusu.DWIE_PILKI:
		_rysuj_dwie_pilki()
	else:
		_rysuj_blyskawice()


func _rysuj_blyskawice() -> void:
	var blyskawica = PackedVector2Array([
		Vector2(2.0, -11.0),
		Vector2(-7.0, 1.0),
		Vector2(-1.5, 1.0),
		Vector2(-3.0, 11.0),
		Vector2(8.0, -3.0),
		Vector2(2.0, -3.0)
	])
	draw_colored_polygon(blyskawica, Color("#59400e"))
	draw_circle(Vector2(-7.0, -8.0), 2.0, Color(1.0, 1.0, 1.0, 0.72))


func _rysuj_dwie_pilki() -> void:
	draw_circle(Vector2(-5.5, -2.0), 7.5, Color("#075062"))
	draw_circle(Vector2(-5.5, -2.0), 5.8, Color("#f2ffff"))
	draw_circle(Vector2(6.0, 4.0), 7.5, Color("#075062"))
	draw_circle(Vector2(6.0, 4.0), 5.8, Color("#f2ffff"))
	draw_circle(Vector2(-7.0, -4.0), 1.5, Color.WHITE)
	draw_circle(Vector2(4.5, 2.0), 1.5, Color.WHITE)


func _kolor_bonusu() -> Color:
	return Color("#43dce8") if typ == TypBonusu.DWIE_PILKI else Color("#ffc857")


func _kolor_obwodki() -> Color:
	return Color("#d8ffff") if typ == TypBonusu.DWIE_PILKI else Color("#fff3d3")


func _kolor_blysku() -> Color:
	return Color("#f1ffff") if typ == TypBonusu.DWIE_PILKI else Color("#fff8e8")


func _on_body_entered(body: Node2D) -> void:
	if zebrany or not body is PilkaAPI:
		return
	var gra := get_parent() as GraPongAPI
	gra.odtworz_dzwiek_bonusu()
	var pilka := body as PilkaAPI
	match typ:
		TypBonusu.PRZYSPIESZENIE:
			pilka.przyspiesz()
		TypBonusu.DWIE_PILKI:
			pilka.dodaj_dodatkowa_pilke(global_position)
	_rozpocznij_zbieranie()


func _rozpocznij_zbieranie() -> void:
	zebrany = true
	monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
