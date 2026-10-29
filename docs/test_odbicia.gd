extends Node

var bledy: int = 0
var kontrole: int = 0
var gra: GraPongAPI


func sprawdz(ok: bool, opis: String) -> void:
	kontrole += 1
	if ok:
		print("PASS: ", opis)
	else:
		bledy += 1
		push_error("FAIL: " + opis)


func klatki(ile: int = 2) -> void:
	for i in range(ile):
		await get_tree().physics_frame
		await get_tree().process_frame


func _ready() -> void:
	start.call_deferred()


func przygotuj(tryb: String) -> void:
	Ustawienia.tryb = tryb
	Ustawienia.intensywnosc_efektow = 100
	gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
	get_tree().root.add_child(gra)
	await klatki()
	gra.przebieg().set_process(false)
	gra.przebieg().set_physics_process(false)
	gra.pilka().set_physics_process(false)
	gra.lewa_paletka().set_physics_process(false)
	gra.prawa_paletka().set_physics_process(false)
	gra.pilka().intro_aktywne = false
	gra.pilka().respawn_oczekuje = false
	gra.pilka().run_state = null
	for cel in get_tree().get_nodes_in_group("przeciwnicy_run"):
		cel.queue_free()
	await klatki()


func kontakt(opis: String, punkt_startu: Vector2, ruch: Vector2, normalna: Vector2, kolor: Color, y: float, wall: bool = false) -> void:
	var efekty := gra.efekty_wizualne
	for efekt in efekty.aktywne:
		if is_instance_valid(efekt):
			efekt.queue_free()
	efekty.aktywne.clear()
	await klatki()
	var pilka := gra.pilka()
	pilka.position = punkt_startu
	pilka.velocity = ruch
	pilka.predkosc = ruch.length()
	pilka.czas_rundy = 0.0
	efekty.czas_od_odbicia = 1.0
	var indeks := efekty.nastepne_iskry
	pilka._physics_process(1.0 / 60.0)
	sprawdz(efekty.aktywne.size() == 1, opis + ": jeden efekt kontaktu")
	sprawdz(efekty.nastepne_iskry == (indeks + 1) % efekty.pula_iskier.size(), opis + ": jeden burst particle")
	var iskry := efekty.pula_iskier[indeks]
	sprawdz(Vector2.RIGHT.rotated(iskry.rotation).dot(normalna) > 0.99, opis + ": kierunek w glab planszy")
	sprawdz(iskry.modulate.is_equal_approx(kolor), opis + ": kolor kontaktu")
	sprawdz(absf(iskry.global_position.y - y) < 1.0, opis + ": wysokosc kontaktu")
	sprawdz(pilka.velocity.dot(normalna) > 0.0, opis + ": pilka odbita")
	if wall:
		sprawdz(is_equal_approx(iskry.global_position.x, Ustawienia.prawa_granica), opis + ": efekt na granicy")
		sprawdz(is_equal_approx(pilka.velocity.length(), ruch.length()), opis + ": zachowana predkosc")
		# Druga klatka na samej granicy z pilka oddalajaca sie od sciany.
		efekty.czas_od_odbicia = 1.0
		pilka._physics_process(0.0)
		sprawdz(efekty.nastepne_iskry == (indeks + 1) % efekty.pula_iskier.size(), opis + ": brak powtorzenia na granicy")
	await klatki(1)
	if DisplayServer.get_name() != "headless" and ruch.length() < 1000.0 and is_zero_approx(y - gra.lewa_paletka().position.y):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/odbicia-%s.png" % opis)


func start() -> void:
	await przygotuj("2graczy")
	for szybkosc in [620.0, 6000.0]:
		for prawa in [false, true]:
			var paletka := gra.prawa_paletka() if prawa else gra.lewa_paletka()
			var normalna := Vector2.LEFT if prawa else Vector2.RIGHT
			var polowa := paletka._polowa_wysokosci_paletki()
			for offset in [-polowa + 8.0, 0.0, polowa - 8.0]:
				var y: float = paletka.position.y + offset
				var dystans := 28.0 if szybkosc < 1000.0 else 90.0
				await kontakt("%s-%s-%d" % ["prawa" if prawa else "lewa", str(offset), int(szybkosc)], Vector2(paletka.position.x + normalna.x * dystans, y), -normalna * szybkosc, normalna, paletka._kolor_paletki(), y)
	gra.queue_free()
	await klatki()
	await przygotuj("endless")
	for szybkosc in [620.0, 6000.0]:
		for y in [Ustawienia.gorna_granica + 60.0, gra.lewa_paletka().position.y, Ustawienia.dolna_granica - 60.0]:
			await kontakt("wall-%d-%d" % [int(y), int(szybkosc)], Vector2(Ustawienia.prawa_granica - 15.0, y), Vector2.RIGHT * szybkosc, Vector2.LEFT, gra.lewa_paletka()._kolor_paletki(), y, true)
	gra.queue_free()
	await klatki()
	print("WYNIK: %d kontroli, %d bledow" % [kontrole, bledy])
	get_tree().quit(bledy)
