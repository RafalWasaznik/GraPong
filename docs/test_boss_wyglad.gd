extends Node

var bledy: int = 0
var kontrole: int = 0
var gra: GraPongAPI
var katalog := "C:/Users/mojei/.codex/visualizations/2026/10/29/01a1895e-621e-7a42-a7ff-f31939ac64cb"
var sygnaly_smierci: int = 0
var sygnaly_gotowosci: int = 0

func sprawdz(ok: bool, opis: String) -> void:
	kontrole += 1
	if not ok:
		bledy += 1
		push_error(opis)
	else:
		print("PASS: ", opis)

func _ready() -> void:
	start.call_deferred()

func klatka() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame

func zdjecie(nazwa: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(katalog + "/boss_" + nazwa + ".png")

func start() -> void:
	Ustawienia.tryb = "endless"
	gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
	add_child(gra)
	await klatka()
	gra.przebieg().set_physics_process(false)
	gra.pilka().set_physics_process(false)
	gra.pilka().hide()
	gra.lewa_paletka().set_physics_process(false)
	var definicje := BossDefinicja.katalog()
	for indeks in [0, 1, 3, 5]:
		var boss := BossRun.new()
		boss.definicja = definicje[indeks % 2]
		boss.bossIndex = indeks
		boss.paletka = gra.lewa_paletka()
		boss.pilka = gra.pilka()
		gra.add_child(boss)
		boss.gotowy.connect(func(): sygnaly_gotowosci += 1)
		await get_tree().create_timer(1.35).timeout
		sprawdz(boss.intro == 0.0, "animowane wejscie zakonczone " + str(indeks))
		boss.set_physics_process(false)
		boss.intro = 0.0
		boss.czas_wizualny = 2.3
		var id := str(boss.definicja.id) + "_" + str(indeks)
		if indeks == 0:
			sprawdz(boss.kolizja.shape is RectangleShape2D and (boss.kolizja.shape as RectangleShape2D).size == Vector2(64,144), "hitbox Straznika 64x144")
		else:
			sprawdz(boss.kolizja.shape is CircleShape2D and (boss.kolizja.shape as CircleShape2D).radius == 30.0, "hitbox Rdzenia r30 " + id)
			sprawdz(boss.sat_kolizje.size() == (3 if indeks == 1 else 4), "liczba satelitow " + id)
			for sat in boss.sat_kolizje:
				sprawdz((sat.shape as CircleShape2D).radius == 18.0, "hitbox satelity r18")
		for etap in range(4):
			boss.maxHp = 100
			boss.hp = [100,75,50,25][etap]
			sprawdz(boss.etap_pancerza() == etap, "etap %d %s" % [etap,id])
			boss.queue_redraw()
			await zdjecie(id + "_hp_" + str(boss.hp))
		if indeks <= 1:
			var hp_zapis := boss.hp
			boss.hp = boss.maxHp
			for motyw in range(1,5):
				Ustawienia.motyw_tla = motyw
				Ustawienia.motyw_tla_zmieniony.emit(motyw)
				await get_tree().create_timer(0.7).timeout
				boss.queue_redraw()
				await zdjecie(id + "_motyw_" + str(motyw))
			boss.hp = hp_zapis
		Ustawienia.intensywnosc_efektow = 0.0
		Ustawienia.jakosc_tla = 0
		Ustawienia.grafika_tla_zmieniona.emit()
		boss.queue_redraw()
		await zdjecie(id + "_minimum")
		Ustawienia.intensywnosc_efektow = 70.0
		Ustawienia.jakosc_tla = 2
		Ustawienia.grafika_tla_zmieniona.emit()
		boss.hp = boss.maxHp
		if indeks == 0:
			for wzor in range(4):
				boss.kolejnosc.assign([wzor])
				boss._zapowiedz_wzor()
				sprawdz(boss.atak.wzor == wzor and boss.ostrzezenie >= 0.6, "wzor i ostrzezenie Straznika " + str(wzor))
				var liczba := boss.zaplanowane_starty.size()
				sprawdz(liczba == 2 if wzor == 1 else liczba > 0, "starty wzoru " + str(wzor))
				boss.ostrzezenie *= 0.25
				boss.queue_redraw()
				await zdjecie(id + "_zapowiedz_" + str(wzor))
				boss._wystrzel_wzor()
				sprawdz(boss.czasy_blyskow.size() == liczba, "kazdy emiter ma blysk " + str(wzor))
				sprawdz(boss.pociski.size() == liczba, "liczba pociskow " + str(wzor))
				if wzor == 2:
					sprawdz(boss.seria_pozostalo == 2, "seria ma dwa dalsze strzaly")
				boss.queue_redraw()
				await zdjecie(id + "_strzal_" + str(wzor))
				boss.odrocz_atak_po_stracie()
				boss.czasy_blyskow.clear()
				boss.miejsca_blyskow.clear()
				boss.kierunki_blyskow.clear()
			boss.trafienie(BossRun.Trafienie.new(1,-1,false))
			sprawdz(boss.hp == 99 and boss.cooldown_trafienia == 0.1, "obrazenia i cooldown Straznika")
		else:
			var hp_przed := boss.hp
			boss.trafienie(BossRun.Trafienie.new(1,-1,false))
			sprawdz(boss.hp == hp_przed, "Rdzen osloniety blokuje obrazenia " + id)
			boss._zapowiedz_rdzen()
			sprawdz(boss.zaplanowane_starty.size() == (1 if indeks == 1 else 2), "salwa satelitow " + id)
			boss.ostrzezenie *= 0.25
			boss.queue_redraw()
			await zdjecie(id + "_zapowiedz")
			boss._wystrzel_wzor()
			boss.queue_redraw()
			await zdjecie(id + "_strzal")
			boss.odrocz_atak_po_stracie()
			boss._traf_satellite(BossRun.Trafienie.new(1,0,false))
			sprawdz(boss.sat_hp[0] == 2, "wewnetrzna strona satelity blokuje obrazenia")
			for i in range(boss.sat_hp.size()):
				boss._traf_satellite(BossRun.Trafienie.new(2,i,true))
			sprawdz(boss._zywe_satelity() == 0 and boss.odsloniecie == 15.0, "zniszczenie oslon otwiera rdzen na 15s " + id)
			boss.trafienie(BossRun.Trafienie.new(1,-1,false))
			sprawdz(boss.hp == hp_przed-1, "odsloniety rdzen przyjmuje obrazenia")
			boss._zapowiedz_rdzen()
			sprawdz(boss.puls and boss.zaplanowane_starty.size() < 14 and boss.zaplanowane_starty.size() > 0, "puls zachowuje bezpieczna luke " + id)
			boss.queue_redraw()
			await zdjecie(id + "_odsloniety")
			boss.nowe_odsloniecie = false
			boss.odsloniecie = 0.01
			boss._aktualizuj_rdzen(0.02)
			sprawdz(boss.regeneruje, "poczatek regeneracji " + id)
			boss._aktualizuj_rdzen(0.01)
			sprawdz(boss.sat_hp[0] == 2 and boss.regen_indeks == 1, "regeneracja pierwszej satelity " + id)
			if indeks >= 3:
				var kierunek := boss.kierunek_orbity
				boss.czas_odwrocenia = 5.99
				boss._aktualizuj_rdzen(0.02)
				sprawdz(boss.kierunek_orbity == -kierunek, "odwracanie orbity " + id)
			if indeks == 5:
				sprawdz(is_equal_approx(boss.sat_kolizje[0].position.length(),70.0) and is_equal_approx(boss.sat_kolizje[1].position.length(),102.0), "dwie warstwy orbit 70/102")
		boss.hp = 0
		for czas in [0.04,0.17,0.29,0.43]:
			boss.rozpad = czas
			boss.queue_redraw()
			await zdjecie(id + "_rozpad_" + str(int(czas*100)))
		boss.rozpad = 0.0
		boss.pokonany.connect(func(): sygnaly_smierci += 1)
		boss._physics_process(0.49)
		sprawdz(not boss.is_queued_for_deletion(), "rozpad nie konczy sie przed 0.5s " + id)
		boss._physics_process(0.01)
		sprawdz(boss.is_queued_for_deletion(), "koniec rozpadu po 0.5s " + id)
		await klatka()
	sprawdz(sygnaly_gotowosci == 4, "wejscie uruchamia walke raz dla kazdego typu/fazy")
	sprawdz(sygnaly_smierci == 4, "pojedynczy sygnal pokonania kazdego typu/fazy")
	gra.queue_free()
	await klatka()
	print("BOSS_CHECK: %d kontroli, %d bledow" % [kontrole,bledy])
	get_tree().quit(bledy)
