class_name EfektyMeczu
extends Node2D

const LIMIT_EFEKTOW: int = 20
const KOLOR_PILKI: Color = Color("#7ceaff")
var aktywne: Array[VFX2D] = []
var pula_iskier: Array[GPUParticles2D] = []
var nastepne_iskry: int = 0
var odtwarzacze_energii: Array[AudioStreamPlayer] = []
var kontakty_energii: Array[KontaktEnergii] = []
var kontakty_ramy: Array[KontaktEnergii] = []

class KontaktEnergii extends RefCounted:
	var miejsce: Vector2
	var normalna: Vector2
	var czas: float = 0.0

var czas_od_odbicia: float = 1.0
var impuls_wyniku: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 8
	Ustawienia.paleta_przeciwnikow_zmieniona.connect(queue_redraw)
	for rodzaj in range(4):
		var audio := AudioStreamPlayer.new()
		audio.stream = preload("res://dzwieki_gry.gd").utworz_energie(rodzaj)
		audio.bus = &"Efekty"
		audio.volume_db = -14.0 if rodzaj == 1 else -8.0
		audio.max_polyphony = 4
		add_child(audio)
		odtwarzacze_energii.append(audio)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var zanikanie := GradientTexture1D.new()
	zanikanie.gradient = gradient
	for i in range(4):
		var iskry := GPUParticles2D.new()
		iskry.emitting = false
		iskry.one_shot = true
		iskry.amount = 8
		iskry.lifetime = 0.24
		iskry.explosiveness = 1.0
		iskry.visibility_rect = Rect2(-100.0, -100.0, 200.0, 200.0)
		var parametry := ParticleProcessMaterial.new()
		parametry.direction = Vector3(1.0, 0.0, 0.0)
		parametry.spread = 65.0
		parametry.gravity = Vector3.ZERO
		parametry.initial_velocity_min = 35.0
		parametry.initial_velocity_max = 125.0
		parametry.scale_min = 1.0
		parametry.scale_max = 2.5
		parametry.color_ramp = zanikanie
		iskry.process_material = parametry
		add_child(iskry)
		pula_iskier.append(iskry)


func _process(delta: float) -> void:
	czas_od_odbicia += delta
	for i in range(kontakty_ramy.size() - 1, -1, -1):
		kontakty_ramy[i].czas += delta
		if kontakty_ramy[i].czas >= 0.3:
			kontakty_ramy.remove_at(i)
	for i in range(kontakty_energii.size() - 1, -1, -1):
		kontakty_energii[i].czas += delta
		if kontakty_energii[i].czas >= 0.24:
			kontakty_energii.remove_at(i)
	queue_redraw()
	var odswiez := impuls_wyniku != Vector2.ZERO
	impuls_wyniku = Vector2(maxf(0.0, impuls_wyniku.x - delta), maxf(0.0, impuls_wyniku.y - delta))
	if odswiez:
		var gra := get_parent() as GraPongAPI
		gra.odswiez_rysowanie()


func zmiana_wyniku(strona: int) -> void:
	impuls_wyniku[strona] = 0.35


func odbicie(miejsce: Vector2, normalna: Vector2, kolor: Color = KOLOR_PILKI, mocne: bool = false) -> void:
	var sila := Ustawienia.intensywnosc_efektow / 100.0
	if sila <= 0.0 or czas_od_odbicia < 0.045:
		return
	czas_od_odbicia = 0.0
	if kontakty_ramy.size() < 12:
		var gora := absf(miejsce.y - Ustawienia.gorna_granica)
		var dol := absf(miejsce.y - Ustawienia.dolna_granica)
		var lewa := absf(miejsce.x - Ustawienia.lewa_granica)
		var prawa := absf(miejsce.x - Ustawienia.prawa_granica)
		if (absf(normalna.y) > 0.9 and minf(gora, dol) <= 10.5) or (absf(normalna.x) > 0.9 and minf(lewa, prawa) <= 1.0):
			var kontakt := KontaktEnergii.new()
			kontakt.miejsce = miejsce
			kontakt.normalna = normalna
			if absf(normalna.y) > 0.9:
				kontakt.miejsce.y = Ustawienia.gorna_granica if gora < dol else Ustawienia.dolna_granica
			else:
				kontakt.miejsce.x = Ustawienia.lewa_granica if lewa < prawa else Ustawienia.prawa_granica
			kontakty_ramy.append(kontakt)
	_emituj("spark", miejsce, kolor, 62.0 if mocne else 38.0, 0.22, sila * (0.7 if mocne else 0.45))
	if mocne and not pula_iskier.is_empty():
		var iskry := pula_iskier[nastepne_iskry]
		nastepne_iskry = (nastepne_iskry + 1) % pula_iskier.size()
		iskry.global_position = miejsce
		iskry.rotation = normalna.angle()
		iskry.modulate = Color(kolor, sila)
		iskry.restart()


func punkt(miejsce: Vector2, kolor: Color = KOLOR_PILKI) -> void:
	_emituj("explosion", miejsce, kolor, 100.0, 0.38, Ustawienia.intensywnosc_efektow / 100.0 * 0.55)


func _emituj(rodzaj: String, miejsce: Vector2, kolor: Color, rozmiar: float, czas: float, sila: float) -> void:
	for i in range(aktywne.size() - 1, -1, -1):
		if not is_instance_valid(aktywne[i]) or aktywne[i].is_queued_for_deletion():
			aktywne.remove_at(i)
	if sila <= 0.0 or aktywne.size() >= LIMIT_EFEKTOW:
		return
	var efekt := VFX2D.new()
	if not VFX2D.effects().has(rodzaj):
		efekt.free()
		return
	efekt.effect = rodzaj
	efekt.size = Vector2.ONE * rozmiar
	efekt.duration = czas
	efekt.set_param(&"color_core", Color("#f4fdff"))
	efekt.set_param(&"color_mid", kolor)
	efekt.set_param(&"color_edge", Color(kolor, 0.0))
	efekt.set_param(&"intensity", sila)
	efekt.set_param(&"seed", randf() * 10.0)
	add_child(efekt)
	efekt.global_position = miejsce
	aktywne.append(efekt)


func dzwiek_energii(rodzaj: int) -> void:
	if rodzaj >= 0 and rodzaj < odtwarzacze_energii.size():
		odtwarzacze_energii[rodzaj].play()


func kontakt_pocisku(miejsce: Vector2, normalna: Vector2) -> void:
	dzwiek_energii(1)
	if kontakty_energii.size() >= LIMIT_EFEKTOW or Ustawienia.intensywnosc_efektow <= 0:
		return
	var kontakt := KontaktEnergii.new()
	kontakt.miejsce = to_local(miejsce)
	kontakt.normalna = normalna
	kontakty_energii.append(kontakt)


func _draw() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	for kontakt in kontakty_energii:
		var t := kontakt.czas / 0.24
		var alfa := (1.0 - t) * Ustawienia.intensywnosc_efektow / 100.0
		draw_set_transform(kontakt.miejsce, kontakt.normalna.angle())
		draw_line(Vector2(0,-18), Vector2(0,18), Color(paleta.zagrozenie, alfa * 0.35), 5.0, true)
		draw_arc(Vector2.ZERO, 2.0 + t * 19.0, -PI / 2.0, PI / 2.0, 16, Color(paleta.swiatlo, alfa), 1.5, true)
		draw_circle(Vector2.ZERO, (1.0 - t) * 6.0, Color(paleta.rdzen, alfa))
		for i in range(5):
			var kierunek := Vector2.RIGHT.rotated(-1.1 + i * 0.55)
			var punkt := kierunek * t * (20.0 + i * 3.0)
			draw_line(punkt, punkt + kierunek * 4.0, Color(paleta.zagrozenie, alfa), 1.3, true)
	draw_set_transform(Vector2.ZERO)
