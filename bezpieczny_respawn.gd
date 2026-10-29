class_name BezpiecznyRespawn
extends RefCounted

const MARGINES: float = 10.0
const KROK: float = 8.0


static func znajdz(pilka: Pilka, promien: float, centralnie: bool = true) -> Vector2:
	var arena := Rect2(Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica), Vector2(Ustawienia.prawa_granica - Ustawienia.lewa_granica, Ustawienia.dolna_granica - Ustawienia.gorna_granica)).grow(-promien - MARGINES)
	var srodek := arena.get_center()
	var obszar := arena.intersection(Rect2(srodek - Vector2(160,180), Vector2(320,360))) if centralnie else arena
	if wolne(pilka, srodek, promien):
		return srodek
	var kandydaci: Array[Vector2] = []
	var krok := KROK if centralnie else 16.0
	for y in range(int(ceil(obszar.size.y / krok)) + 1):
		for x in range(int(ceil(obszar.size.x / krok)) + 1):
			var punkt := obszar.position + Vector2(minf(x * krok, obszar.size.x), minf(y * krok, obszar.size.y))
			kandydaci.append(punkt)
	kandydaci.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(srodek) < b.distance_squared_to(srodek))
	for punkt in kandydaci:
		if wolne(pilka, punkt, promien):
			return punkt
	return Vector2(INF, INF)


static func wolne(pilka: Pilka, punkt: Vector2, promien: float) -> bool:
	var bezpieczny_promien := promien + MARGINES
	var arena := Rect2(Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica), Vector2(Ustawienia.prawa_granica - Ustawienia.lewa_granica, Ustawienia.dolna_granica - Ustawienia.gorna_granica)).grow(-bezpieczny_promien)
	if not arena.has_point(punkt):
		return false
	for wezel in pilka.get_tree().get_nodes_in_group("przeciwnicy_run"):
		var wrog := wezel as KrysztalRun
		if wrog == null or wrog.rozpad or wrog.is_queued_for_deletion():
			continue
		var poczatek := wrog.to_global(wrog.tor_poczatek - wrog.position)
		var koniec := wrog.to_global(wrog.tor_koniec - wrog.position)
		if wrog.wariant.params.wander_speed <= 0.0:
			poczatek = wrog.global_position
			koniec = poczatek
		var najblizszy := Geometry2D.get_closest_point_to_segment(punkt, poczatek, koniec)
		if punkt.distance_to(najblizszy) <= bezpieczny_promien + KrysztalRun.PROMIEN + 4.0:
			return false
	var ksztalt := CircleShape2D.new()
	ksztalt.radius = bezpieczny_promien
	var zapytanie := PhysicsShapeQueryParameters2D.new()
	zapytanie.shape = ksztalt
	zapytanie.transform = Transform2D(0.0, punkt)
	zapytanie.collision_mask = pilka.collision_mask
	zapytanie.exclude = [pilka.get_rid()]
	return pilka.get_world_2d().direct_space_state.intersect_shape(zapytanie, 1).is_empty()
