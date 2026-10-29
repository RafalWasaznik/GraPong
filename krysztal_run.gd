class_name KrysztalRun
extends StaticBody2D

signal zniszczony
signal wygasl_nietkniety
signal pancerz_pekl

const PROMIEN: float = 30.0
const CZAS_BEZ_TRAFIENIA: float = 20.0
const CZAS_ROZPADU: float = 0.24
const CZAS_POJAWIANIA: float = 0.18
const BURST_RADIUS: float = PROMIEN * 3.0
const ARMOR_HP: int = 1
const WANDER_SPEED: float = 40.0
const MAX_CHAIN_STEPS: int = 3

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
var czas_pojawiania: float = 0.0
var rdzen: Polygon2D
var material_rdzenia: ShaderMaterial
var wariant_rozpadu: int = 0
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
	max_hp = TrudnoscRun.getDifficulty(floori(stan.score), stan.bossIndex).crystal_hp
	hp = max_hp
	armor_hp = wariant.params.armor_hp
	tor_poczatek = poczatek
	tor_koniec = koniec
	tor_postep = poczatek.distance_to(koniec) * 0.5
	tor_kierunek = -1.0 if randf() < 0.5 else 1.0
	position = poczatek.lerp(koniec, 0.5)


func nagroda_bazowa() -> float:
	return 5.0


func obszar_toru() -> Rect2:
	return Rect2(tor_poczatek, tor_koniec - tor_poczatek).abs().grow(PROMIEN + TrudnoscRun.DIFFICULTY.TRACK_PADDING)


func _ready() -> void:
	process_physics_priority = -10
	name = "Kryształ"
	add_to_group("przeciwnicy_run")
	wariant_rozpadu = randi_range(0, 2)
	collision_layer = 1
	collision_mask = 0
	kolizja = CollisionShape2D.new()
	var ksztalt := ConvexPolygonShape2D.new()
	ksztalt.points = _punkty_szesciokata(PROMIEN)
	kolizja.shape = ksztalt
	kolizja.disabled = true
	add_child(kolizja)
	if not self is DronRun:
		rdzen = Polygon2D.new()
		rdzen.polygon = _punkty_szesciokata(PROMIEN * 0.26)
		material_rdzenia = ShaderMaterial.new()
		material_rdzenia.shader = preload("res://shaders/rdzen_mechaniczny.gdshader")
		rdzen.material = material_rdzenia
		add_child(rdzen)
	modulate.a = 0.0
	Ustawienia.paleta_przeciwnikow_zmieniona.connect(_odswiez_palete)
	_odswiez_palete()


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
		if rdzen != null:
			rdzen.hide()
		wybuch_zniszczenia = wariant.params.burst_radius > 0.0
		kolizja.set_deferred("disabled", true)
		_dzwiek_zniszczenia()
		zniszczony.emit()
	queue_redraw()


func rozlicz_przed_bossem() -> float:
	if rozpad or is_queued_for_deletion():
		return 0.0
	var udzial := float(hp) / float(max_hp)
	hp = 0
	rozpad = true
	if rdzen != null:
		rdzen.hide()
	kolizja.set_deferred("disabled", true)
	queue_redraw()
	return udzial


func _physics_process(delta: float) -> void:
	constant_linear_velocity = Vector2.ZERO
	var pozycja_przed := global_position
	if run_state != null and run_state.wybor_aktywny:
		return
	czas_animacji += delta
	if rdzen != null:
		rdzen.visible = not rozpad
		var efekty := clampf(Ustawienia.intensywnosc_efektow / 100.0, 0.0, 1.0)
		material_rdzenia.set_shader_parameter("faza", czas_animacji * efekty)
		var uszkodzenie := stopien_uszkodzenia()
		var paleta := PaletaPrzeciwnikow.pobierz(self)
		var kolor_rdzenia := paleta.rdzen.lerp(paleta.pekniecie, uszkodzenie)
		material_rdzenia.set_shader_parameter("energia", kolor_rdzenia.lerp(Color.WHITE, blysk * 4.0 * clampf(Ustawienia.intensywnosc_efektow / 100.0, 0.0, 1.0)))
		rdzen.scale = Vector2.ONE * (1.0 + uszkodzenie * 0.85 + (_puls_energii() - 0.5) * (0.08 + uszkodzenie * 0.12) * efekty)
	if czas_pojawiania < CZAS_POJAWIANIA:
		czas_pojawiania = minf(CZAS_POJAWIANIA, czas_pojawiania + delta)
		modulate.a = czas_pojawiania / CZAS_POJAWIANIA
		if czas_pojawiania >= CZAS_POJAWIANIA and not rozpad:
			kolizja.set_deferred("disabled", false)
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
		constant_linear_velocity = (global_position - pozycja_przed) / maxf(delta, 0.000001)
		czas_bez_trafienia += delta
		if czas_bez_trafienia >= CZAS_BEZ_TRAFIENIA:
			if nietkniety:
				wygasl_nietkniety.emit()
			queue_free()
	blysk = maxf(0.0, blysk - delta)
	czas_pekania_pancerza = maxf(0.0, czas_pekania_pancerza - delta)
	queue_redraw()


func _draw() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	var efekty := clampf(Ustawienia.intensywnosc_efektow / 100.0, 0.0, 1.0)
	var wejscie := clampf(czas_pojawiania / CZAS_POJAWIANIA, 0.0, 1.0)
	var skala := lerpf(0.75, 1.0, 1.0 - pow(1.0 - wejscie, 3.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * skala)
	if rozpad:
		if efekty <= 0.0:
			return
		var postep := clampf(czas_rozpadu / CZAS_ROZPADU, 0.0, 1.0)
		if wybuch_zniszczenia:
			draw_arc(Vector2.ZERO, lerpf(PROMIEN, wariant.params.burst_radius, postep), 0.0, TAU, 48, Color(paleta.pekniecie, (1.0 - postep) * efekty), 3.0, true)
		draw_circle(Vector2.ZERO, (1.0 - postep) * 19.0, Color(paleta.swiatlo, (1.0 - postep) * 0.65 * efekty))
		for i in range(6):
			var kat := TAU * float(i) / 6.0 - PI / 2.0 + wariant_rozpadu * 0.18
			var kierunek := Vector2.RIGHT.rotated(kat)
			var srodek := kierunek * (7.0 + (1.0 - pow(1.0 - postep, 2.0)) * (28.0 + wariant_rozpadu * 7.0))
			var kolor_fragmentu := paleta.pekniecie if wybuch_zniszczenia else (paleta.swiatlo if i % 2 == 0 else paleta.krysztal)
			var bok := kierunek.orthogonal() * (6.0 * (1.0 - postep))
			draw_colored_polygon(PackedVector2Array([srodek + kierunek * 10.0, srodek - kierunek * 5.0 + bok, srodek - kierunek * 5.0 - bok]), Color(kolor_fragmentu, (1.0 - postep) * efekty))
		for i in range(10):
			var iskra := Vector2.RIGHT.rotated(float(i) * 2.4) * (14.0 + postep * (38.0 + i * 2.0))
			draw_circle(iskra, 1.8 * (1.0 - postep), Color(paleta.swiatlo, (1.0 - postep) * efekty))
		return
	if wariant.params.wander_speed > 0.0:
		var poczatek := tor_poczatek - position
		var koniec := tor_koniec - position
		var znacznik := (koniec - poczatek).normalized().orthogonal() * 5.0
		draw_line(poczatek, koniec, Color(paleta.swiatlo, 0.22), 1.0, true)
		draw_line(poczatek - znacznik, poczatek + znacznik, Color(paleta.swiatlo, 0.4), 1.5, true)
		draw_line(koniec - znacznik, koniec + znacznik, Color(paleta.swiatlo, 0.4), 1.5, true)
	var blik := clampf(blysk / 0.16, 0.0, 1.0) * efekty
	var punkty := _punkty_szesciokata(PROMIEN)
	var obrys := punkty.duplicate()
	obrys.append(obrys[0])
	var etap := etap_uszkodzenia()
	var uszkodzenie := stopien_uszkodzenia()
	var puls := _puls_energii() * efekty
	var kolor_energii := paleta.rdzen.lerp(paleta.pekniecie, uszkodzenie).lerp(Color.WHITE, blik)
	var promien_rdzenia := 9.0 + uszkodzenie * 7.0
	draw_colored_polygon(_punkty_szesciokata(PROMIEN * 0.83), paleta.korpus.darkened(0.5))
	draw_circle(Vector2.ZERO, promien_rdzenia + 3.0 + puls * 1.8, Color(kolor_energii, 0.10 + puls * (0.06 + uszkodzenie * 0.14)))
	draw_colored_polygon(_punkty_szesciokata(promien_rdzenia), paleta.korpus.lerp(kolor_energii, 0.28 + uszkodzenie * 0.22))
	for i in range(6):
		var zew_a: Vector2 = punkty[i]
		var zew_b: Vector2 = punkty[(i + 1) % 6]
		var kierunek := (zew_a + zew_b).normalized()
		var bok := kierunek.orthogonal()
		var brak_plyty := (etap >= 2 and i == 1) or (etap == 3 and (i == 3 or i == 5))
		var przesuniecie := Vector2.ZERO
		if etap > 0 and (i == 2 or i == 4):
			przesuniecie = kierunek * (float(etap) * 1.1) + bok * float(etap) * (0.8 if i == 2 else -0.8)
			if etap == 3:
				przesuniecie += kierunek * sin(czas_animacji * 2.7 + float(i) * 1.9) * 0.65 * efekty
		var wewnetrzny := 0.40 + float(etap) * 0.045
		if not brak_plyty:
			var plyta := PackedVector2Array([zew_a * 0.95 + przesuniecie, zew_b * 0.95 + przesuniecie, zew_b * wewnetrzny + przesuniecie, zew_a * wewnetrzny + przesuniecie])
			var kolor_plyty := (paleta.pancerz if i % 2 == 0 else paleta.pancerz.darkened(0.22)).lerp(paleta.swiatlo, blik * 0.6)
			draw_colored_polygon(plyta, kolor_plyty)
			draw_colored_polygon(PackedVector2Array([plyta[0], plyta[1], zew_b * 0.79 + przesuniecie, zew_a * 0.79 + przesuniecie]), kolor_plyty.lightened(0.16))
			draw_line(plyta[0], plyta[1], paleta.krysztal.lerp(Color.WHITE, blik), 1.8, true)
			draw_line(plyta[1], plyta[2], paleta.korpus.darkened(0.4), 1.5, true)
			draw_line(plyta[2], plyta[3], Color(kolor_energii, 0.6), 1.0, true)
			if etap > 0 and (i == 0 or i == 2 or (etap >= 2 and i == 4)):
				_rysuj_pekniecie(kierunek, bok, przesuniecie, etap, paleta, blik, puls)
		else:
			var odlam := kierunek * (PROMIEN * 0.72)
			draw_colored_polygon(PackedVector2Array([zew_a * 0.88, odlam + bok * 2.0, zew_a * 0.64]), paleta.pancerz.darkened(0.25))
			draw_line(kierunek * (promien_rdzenia - 1.0), odlam, Color(kolor_energii, 0.65 + puls * 0.25), 1.5, true)
	if blik > 0.0:
		var postep_trafienia := 1.0 - clampf(blysk / 0.16, 0.0, 1.0)
		for i in range(5):
			var kierunek := Vector2.RIGHT.rotated(float(i) * 2.4 + float(wariant_rozpadu))
			var odprysk := kierunek * (25.0 + postep_trafienia * (13.0 + i * 2.0))
			var bok := kierunek.orthogonal() * 1.8
			draw_colored_polygon(PackedVector2Array([odprysk + kierunek * 3.0, odprysk - kierunek * 2.0 + bok, odprysk - bok]), Color(paleta.swiatlo, blik * 0.8))
			draw_line(odprysk - kierunek * 5.0, odprysk - kierunek * 2.0, Color(paleta.rdzen, blik), 1.0, true)
	if wariant.params.burst_radius > 0.0:
		for i in range(3):
			var znak := Vector2.RIGHT.rotated(float(i) * TAU / 3.0) * (promien_rdzenia + 3.0)
			draw_circle(znak, 1.8, paleta.zagrozenie.lerp(paleta.pekniecie, puls * 0.6))
	if armor_hp > 0:
		var powloka := _punkty_szesciokata(PROMIEN + 4.0)
		powloka.append(powloka[0])
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 24, paleta.pancerz_ciezki, 2.0, true)
		draw_polyline(obrys, paleta.swiatlo.lerp(Color.WHITE, blik), 4.5, true)
		draw_polyline(powloka, paleta.pancerz_ciezki, 3.0, true)
	if czas_pekania_pancerza > 0.0 and efekty > 0.0:
		var postep := 1.0 - czas_pekania_pancerza / CZAS_ROZPADU
		for i in range(6):
			var kierunek := Vector2.RIGHT.rotated(TAU * float(i) / 6.0)
			var srodek := kierunek * (PROMIEN + postep * 26.0)
			draw_line(srodek - kierunek.orthogonal() * 6.0, srodek + kierunek.orthogonal() * 6.0, Color(paleta.pancerz_ciezki, (1.0 - postep) * efekty), 3.0, true)



func _puls_energii() -> float:
	var faza := float(get_instance_id() % 31) * 0.37
	var tempo := 2.4 + stopien_uszkodzenia() * 3.0
	return clampf(0.5 + 0.28 * sin(czas_animacji * tempo + faza) + 0.14 * sin(czas_animacji * tempo * 1.73 + faza * 2.1) + 0.08 * sin(czas_animacji * 0.83 + faza), 0.0, 1.0)


func _rysuj_pekniecie(kierunek: Vector2, bok: Vector2, przesuniecie: Vector2, etap: int, paleta: PaletaPrzeciwnikow, blik: float, puls: float) -> void:
	var szczelina := PackedVector2Array([
		kierunek * 13.0 + przesuniecie,
		kierunek * 17.0 + bok * 2.5 + przesuniecie,
		kierunek * 21.0 - bok * 1.5 + przesuniecie,
		kierunek * 25.0 + bok * 1.8 + przesuniecie,
		kierunek * (26.0 if etap == 1 else 29.0) - bok + przesuniecie
	])
	var odgalezienie := PackedVector2Array([szczelina[2], kierunek * 21.0 - bok * 5.0 + przesuniecie, kierunek * 25.0 - bok * 7.0 + przesuniecie])
	var szerokosc := 1.7 + float(etap) * 0.7
	var kolor_szczeliny := paleta.korpus.darkened(0.75)
	var kolor_krawedzi := paleta.pekniecie.lerp(Color.WHITE, blik)
	draw_polyline(szczelina, Color(kolor_krawedzi, 0.08 + puls * 0.12 + blik * 0.3), szerokosc + 2.5, true)
	draw_polyline(szczelina, kolor_szczeliny, szerokosc, true)
	draw_polyline(odgalezienie, kolor_szczeliny, szerokosc * 0.7, true)
	for j in range(szczelina.size() - 1):
		draw_line(szczelina[j] + bok * 0.8, szczelina[j + 1] + bok * 0.8, Color(kolor_krawedzi, 0.75 + blik * 0.25), 1.0, true)
	draw_line(odgalezienie[0] + bok * 0.6, odgalezienie[1] + bok * 0.6, Color(kolor_krawedzi, 0.65), 0.8, true)


func _punkty_szesciokata(promien: float) -> PackedVector2Array:
	var punkty := PackedVector2Array()
	for i in range(6):
		punkty.append(Vector2.RIGHT.rotated(TAU * float(i) / 6.0 - PI / 2.0) * promien)
	return punkty


func stopien_uszkodzenia() -> float:
	return 1.0 - clampf(float(hp) / maxi(1, max_hp), 0.0, 1.0)


func etap_uszkodzenia() -> int:
	var proporcja := float(hp) / maxi(1, max_hp)
	return 0 if proporcja > 0.75 else (1 if proporcja > 0.5 else (2 if proporcja > 0.25 else 3))


func _dzwiek_zniszczenia() -> void:
	var gra := get_parent() as GraPongAPI
	if gra != null and is_instance_valid(gra.efekty_wizualne):
		gra.efekty_wizualne.dzwiek_energii(2 if self is DronRun else 3)


func _odswiez_palete() -> void:
	if material_rdzenia != null:
		var paleta := PaletaPrzeciwnikow.pobierz(self)
		var kolor_rdzenia := paleta.rdzen.lerp(paleta.pekniecie, stopien_uszkodzenia())
		material_rdzenia.set_shader_parameter("energia", kolor_rdzenia.lerp(Color.WHITE, blysk * 4.0 * clampf(Ustawienia.intensywnosc_efektow / 100.0, 0.0, 1.0)))
	queue_redraw()
