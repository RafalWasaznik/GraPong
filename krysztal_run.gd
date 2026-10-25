class_name KrysztalRun
extends StaticBody2D

signal zniszczony
signal wygasl_nietkniety
signal pancerz_pekl

const PROMIEN: float = 30.0
const CZAS_BEZ_TRAFIENIA: float = 20.0
const CZAS_ROZPADU: float = 0.35
const KOLOR: Color = Color("#ad83ff")
const KOLOR_CYJAN: Color = Color("#55e7ff")
const BURST_RADIUS: float = PROMIEN * 3.0
const ARMOR_HP: int = 1
const WANDER_SPEED: float = 40.0
const MAX_CHAIN_STEPS: int = 3
const KOLOR_PEKAJACY: Color = Color("#ec68ff")
const KOLOR_STALI: Color = Color("#87b9cc")

class Parametry extends RefCounted:
	var burst_radius: float
	var armor_hp: int
	var wander_speed: float
	var track_length: float

	func _init(promien: float = 0.0, pancerz: int = 0, predkosc: float = 0.0, trasa: float = 0.0) -> void:
		burst_radius = promien
		armor_hp = pancerz
		wander_speed = predkosc
		track_length = trasa


class Wariant extends RefCounted:
	var id: StringName
	var nazwa: String
	var spawnWeight: float
	var minHits: int
	var hp_multiplier: float
	var params: Parametry

	func _init(identyfikator: StringName, nazwa_pl: String, waga: float, odbicia: int, mnoznik_hp: float, parametry: Parametry) -> void:
		id = identyfikator
		nazwa = nazwa_pl
		spawnWeight = waga
		minHits = odbicia
		hp_multiplier = mnoznik_hp
		params = parametry


static var CRYSTAL_VARIANTS: Array[Wariant] = [
	Wariant.new(&"standard", "Standardowy", TrudnoscRun.DIFFICULTY.VARIANT_WEIGHTS[0], TrudnoscRun.DIFFICULTY.VARIANT_UNLOCKS[0], 1.0, Parametry.new()),
	Wariant.new(&"burst", "Pękający", TrudnoscRun.DIFFICULTY.VARIANT_WEIGHTS[1], TrudnoscRun.DIFFICULTY.VARIANT_UNLOCKS[1], 1.0, Parametry.new(BURST_RADIUS)),
	Wariant.new(&"armored", "Opancerzony", TrudnoscRun.DIFFICULTY.VARIANT_WEIGHTS[2], TrudnoscRun.DIFFICULTY.VARIANT_UNLOCKS[2], 1.0, Parametry.new(0.0, ARMOR_HP)),
	Wariant.new(&"wanderer", "Wędrujący", TrudnoscRun.DIFFICULTY.VARIANT_WEIGHTS[3], TrudnoscRun.DIFFICULTY.VARIANT_UNLOCKS[3], 1.0, Parametry.new(0.0, 0, WANDER_SPEED, 140.0)),
]

var wariant: Wariant = CRYSTAL_VARIANTS[0]
var run_state: RunState
var nietkniety: bool = true
var armor_hp: int = 0
var czas_pekania_pancerza: float = 0.0
var wybuch_zniszczenia: bool = false
var tor_poczatek: Vector2
var tor_koniec: Vector2
var tor_postep: float = 0.0
var tor_kierunek: float = 1.0
var hp: int = TrudnoscRun.DIFFICULTY.CRYSTAL_HP_BASE
var max_hp: int = TrudnoscRun.DIFFICULTY.CRYSTAL_HP_BASE
var czas_bez_trafienia: float = 0.0
var blysk: float = 0.0
var rozpad: bool = false
var czas_rozpadu: float = 0.0
var czas_animacji: float = 0.0
var kolizja: CollisionShape2D


static func losuj_wariant(trudnosc: TrudnoscRun) -> Wariant:
	var suma: float = 0.0
	for waga in trudnosc.variant_weights:
		suma += waga
	var los := randf() * suma
	for i in range(CRYSTAL_VARIANTS.size()):
		los -= trudnosc.variant_weights[i]
		if los < 0.0:
			return CRYSTAL_VARIANTS[i]
	return CRYSTAL_VARIANTS[0]


func skonfiguruj(definicja: Wariant, stan: RunState, poczatek: Vector2, koniec: Vector2) -> void:
	wariant = definicja
	run_state = stan
	max_hp = TrudnoscRun.getDifficulty(stan.hits, stan.bossIndex).crystal_hp
	hp = max_hp
	armor_hp = wariant.params.armor_hp
	tor_poczatek = poczatek
	tor_koniec = koniec
	tor_postep = poczatek.distance_to(koniec) * 0.5
	tor_kierunek = -1.0 if randf() < 0.5 else 1.0
	position = poczatek.lerp(koniec, 0.5)


func obszar_toru() -> Rect2:
	return Rect2(tor_poczatek, tor_koniec - tor_poczatek).abs().grow(PROMIEN + TrudnoscRun.DIFFICULTY.TRACK_PADDING)


func _ready() -> void:
	name = "Kryształ"
	collision_layer = 1
	collision_mask = 0
	kolizja = CollisionShape2D.new()
	var ksztalt := ConvexPolygonShape2D.new()
	ksztalt.points = _punkty_szesciokata(PROMIEN)
	kolizja.shape = ksztalt
	add_child(kolizja)
	queue_redraw()


func trafienie(obrazenia: int, od_pilki: bool = true) -> void:
	if rozpad or is_queued_for_deletion():
		return
	nietkniety = false
	czas_bez_trafienia = 0.0
	blysk = 0.16
	if od_pilki and armor_hp > 0:
		armor_hp -= 1
		if armor_hp == 0:
			czas_pekania_pancerza = CZAS_ROZPADU
			pancerz_pekl.emit()
		queue_redraw()
		return
	hp = maxi(0, hp - obrazenia)
	if hp == 0:
		rozpad = true
		wybuch_zniszczenia = wariant.params.burst_radius > 0.0
		kolizja.set_deferred("disabled", true)
		zniszczony.emit()
	queue_redraw()


func rozlicz_przed_bossem() -> float:
	if rozpad or is_queued_for_deletion():
		return 0.0
	var udzial := float(hp) / float(max_hp)
	hp = 0
	rozpad = true
	kolizja.set_deferred("disabled", true)
	queue_redraw()
	return udzial


func _physics_process(delta: float) -> void:
	if run_state != null and run_state.wybor_aktywny:
		return
	czas_animacji += delta
	if rozpad:
		czas_rozpadu += delta
		if czas_rozpadu >= CZAS_ROZPADU:
			queue_free()
	else:
		if wariant.params.wander_speed > 0.0 and (run_state == null or not run_state.boss_aktywny):
			var dlugosc := tor_poczatek.distance_to(tor_koniec)
			if dlugosc > 0.0:
				tor_postep += tor_kierunek * wariant.params.wander_speed * delta
				if tor_postep < 0.0 or tor_postep > dlugosc:
					tor_kierunek *= -1.0
					tor_postep = clampf(tor_postep, 0.0, dlugosc)
				position = tor_poczatek.lerp(tor_koniec, tor_postep / dlugosc)
		czas_bez_trafienia += delta
		if czas_bez_trafienia >= CZAS_BEZ_TRAFIENIA:
			if nietkniety:
				wygasl_nietkniety.emit()
			queue_free()
	blysk = maxf(0.0, blysk - delta)
	czas_pekania_pancerza = maxf(0.0, czas_pekania_pancerza - delta)
	queue_redraw()


func _draw() -> void:
	if rozpad:
		var postep := clampf(czas_rozpadu / CZAS_ROZPADU, 0.0, 1.0)
		if wybuch_zniszczenia:
			draw_arc(Vector2.ZERO, lerpf(PROMIEN, wariant.params.burst_radius, postep), 0.0, TAU, 48, Color(KOLOR_PEKAJACY, 1.0 - postep), 3.0, true)
		for i in range(8):
			var kat := TAU * float(i) / 8.0 + czas_animacji * 0.35
			var kierunek := Vector2.RIGHT.rotated(kat)
			var srodek := kierunek * (7.0 + postep * 42.0)
			var kolor_fragmentu := KOLOR_PEKAJACY if wybuch_zniszczenia else (KOLOR_CYJAN if i % 2 == 0 else KOLOR)
			draw_line(srodek, srodek + kierunek * 8.0, Color(kolor_fragmentu, 1.0 - postep), 2.5, true)
		return
	if wariant.params.wander_speed > 0.0:
		var poczatek := tor_poczatek - position
		var koniec := tor_koniec - position
		var znacznik := (koniec - poczatek).normalized().orthogonal() * 5.0
		draw_line(poczatek, koniec, Color(KOLOR_CYJAN, 0.22), 1.0, true)
		draw_line(poczatek - znacznik, poczatek + znacznik, Color(KOLOR_CYJAN, 0.4), 1.5, true)
		draw_line(koniec - znacznik, koniec + znacznik, Color(KOLOR_CYJAN, 0.4), 1.5, true)
	var blik := clampf(blysk / 0.16, 0.0, 1.0)
	var punkty := _punkty_szesciokata(PROMIEN)
	var obrys := punkty.duplicate()
	obrys.append(obrys[0])
	var wypelnienie := KOLOR.lerp(KOLOR_CYJAN, 0.24).lerp(Color.WHITE, 0.24 + blik * 0.7)
	draw_colored_polygon(punkty, wypelnienie)
	draw_polyline(obrys, Color.WHITE.lerp(KOLOR_CYJAN, 1.0 - blik), 3.8, true)
	if wariant.params.burst_radius > 0.0:
		var puls := 0.5 + 0.5 * sin(czas_animacji * 4.0)
		draw_colored_polygon(_punkty_szesciokata(PROMIEN * 0.7), Color(KOLOR_PEKAJACY, 0.15 + puls * 0.3))
		draw_polyline(obrys, KOLOR_PEKAJACY.lerp(Color.WHITE, blik), 3.8, true)
		for i in range(3):
			var kierunek := Vector2.RIGHT.rotated(TAU * float(i) / 3.0)
			var pekniecie := PackedVector2Array([kierunek * 27.0, kierunek * 14.0 + kierunek.orthogonal() * 5.0, kierunek * 7.0, Vector2.ZERO])
			draw_polyline(pekniecie, KOLOR_PEKAJACY, 2.0, true)
	if armor_hp > 0:
		var powloka := _punkty_szesciokata(PROMIEN + 4.0)
		powloka.append(powloka[0])
		draw_colored_polygon(punkty, Color("#233b50"))
		draw_polyline(obrys, KOLOR_CYJAN.lerp(Color.WHITE, blik), 4.5, true)
		draw_polyline(powloka, KOLOR_STALI, 3.0, true)
	if czas_pekania_pancerza > 0.0:
		var postep := 1.0 - czas_pekania_pancerza / CZAS_ROZPADU
		for i in range(6):
			var kierunek := Vector2.RIGHT.rotated(TAU * float(i) / 6.0)
			var srodek := kierunek * (PROMIEN + postep * 26.0)
			draw_line(srodek - kierunek.orthogonal() * 6.0, srodek + kierunek.orthogonal() * 6.0, Color(KOLOR_STALI, 1.0 - postep), 3.0, true)
	for i in range(mini(max_hp, 6)):
		var punkt_a: Vector2 = punkty[i]
		var punkt_b: Vector2 = punkty[(i + 1) % 6]
		var offset := (punkt_a + punkt_b).normalized() * 5.0
		var poczatek := punkt_a.lerp(punkt_b, 0.22) + offset
		var koniec := punkt_a.lerp(punkt_b, 0.78) + offset
		var wypelnienie_segmentu := clampf(float(hp) * 6.0 / float(max_hp) - i, 0.0, 1.0) if max_hp > 6 else (1.0 if i < hp else 0.0)
		draw_line(poczatek, koniec, Color("#35445d"), 3.0, true)
		if wypelnienie_segmentu > 0.0:
			draw_line(poczatek, poczatek.lerp(koniec, wypelnienie_segmentu), Color.WHITE, 4.0, true)


func _punkty_szesciokata(promien: float) -> PackedVector2Array:
	var punkty := PackedVector2Array()
	for i in range(6):
		punkty.append(Vector2.RIGHT.rotated(TAU * float(i) / 6.0 - PI / 2.0) * promien)
	return punkty
