extends Area2D

const KOLOR_BONUS = Color("#43dce8")
const CZAS_POJAWIENIA = 0.22
const CZAS_ZEBRANIA = 0.2

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
	if zebrany:
		var postep = clampf(czas_zebrania / CZAS_ZEBRANIA, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 18.0 + postep * 23.0, 0.0, TAU, 48, Color(KOLOR_BONUS, 1.0 - postep), 2.2, true)
		return

	var puls = 0.5 + 0.5 * sin(czas_animacji * 3.0)
	var promien = 20.0 + sin(czas_animacji * 3.5) * 0.8
	draw_circle(Vector2.ZERO, promien + 8.0, Color(KOLOR_BONUS, 0.055 + puls * 0.035))
	draw_circle(Vector2(0.0, 3.0), promien + 1.0, Color(0.0, 0.0, 0.0, 0.32))
	draw_circle(Vector2.ZERO, promien, Color("#d8ffff"))
	draw_circle(Vector2.ZERO, promien - 3.0, KOLOR_BONUS)
	draw_arc(Vector2.ZERO, promien + 3.0, czas_animacji * 0.45, czas_animacji * 0.45 + 2.1, 32, Color("#f1ffff"), 1.5, true)

	draw_circle(Vector2(-5.5, -2.0), 7.5, Color("#075062"))
	draw_circle(Vector2(-5.5, -2.0), 5.8, Color("#f2ffff"))
	draw_circle(Vector2(6.0, 4.0), 7.5, Color("#075062"))
	draw_circle(Vector2(6.0, 4.0), 5.8, Color("#f2ffff"))
	draw_circle(Vector2(-7.0, -4.0), 1.5, Color.WHITE)
	draw_circle(Vector2(4.5, 2.0), 1.5, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if zebrany or not body.has_method("dodaj_dodatkowa_pilke"):
		return
	body.dodaj_dodatkowa_pilke(global_position)
	_rozpocznij_zbieranie()


func _rozpocznij_zbieranie() -> void:
	zebrany = true
	monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
