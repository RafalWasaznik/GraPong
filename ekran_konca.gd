class_name EkranKonca
extends CanvasLayer

signal menu_pressed
signal replay_pressed

const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

var etykiety_nazw_statystyk: Array[Label] = []
var etykiety_wartosci_statystyk: Array[Label] = []
var podsumowanie_endless = false


func _ready() -> void:
	var przyciemnienie_konca = ColorRect.new()
	przyciemnienie_konca.name = "PrzyciemnienieKoniecGry"
	przyciemnienie_konca.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	przyciemnienie_konca.color = Color(0.015, 0.025, 0.06, 0.7)
	przyciemnienie_konca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	przyciemnienie_konca.z_index = 5
	add_child(przyciemnienie_konca)
	przyciemnienie_konca.hide()

	var karta = Panel.new()
	karta.name = "KartaKoniecGry"
	karta.custom_minimum_size = Vector2(620.0, 520.0)
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karta.z_index = 10
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#0c1628f7")
	styl.border_color = Color("#55e7ff", 0.48)
	styl.set_border_width_all(0)
	styl.set_corner_radius_all(16)
	styl.content_margin_left = 30.0
	styl.content_margin_right = 30.0
	styl.content_margin_top = 30.0
	styl.content_margin_bottom = 30.0
	styl.shadow_color = Color("#55e7ff30")
	styl.shadow_size = 0
	styl.shadow_offset = Vector2(0.0, 10.0)
	karta.add_theme_stylebox_override("panel", styl)
	add_child(karta)
	karta.hide()
	_utworz_podsumowanie_statystyk()

	var komunikat = Label.new()
	komunikat.name = "Komunikat"
	add_child(komunikat)
	komunikat.hide()
	komunikat.add_theme_font_override("font", FONT_ARCADE)
	komunikat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	komunikat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	komunikat.add_theme_font_size_override("font_size", 40)
	komunikat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	komunikat.add_theme_color_override("font_color", Color("#55e7ff"))
	komunikat.z_index = 11
	var wynik_koncowy = Label.new()
	wynik_koncowy.name = "WynikKoncowy"
	wynik_koncowy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wynik_koncowy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wynik_koncowy.add_theme_font_override("font", FONT_ARCADE)
	wynik_koncowy.add_theme_font_size_override("font_size", 35)
	wynik_koncowy.add_theme_color_override("font_color", Color("#e8f4ff"))
	wynik_koncowy.z_index = 11
	add_child(wynik_koncowy)
	wynik_koncowy.hide()

	var przycisk = Button.new()
	przycisk.name = "PrzyciskMenu"
	add_child(przycisk)
	przycisk.hide()
	przycisk.text = "Wróć do menu"
	przycisk.set_meta("neon_akcent", Color("#55e7ff"))
	StylMenu.styluj_przycisk(przycisk, Vector2(300.0, 56.0), Color("#55e7ff"), Color("#111e32"), Color("#344d64"), Color("#192d45"), Color("#102638"), Color("#35bcd5"), 20)
	przycisk.z_index = 11
	przycisk.pressed.connect(func(): menu_pressed.emit())
	var przycisk_ponownie = Button.new()
	przycisk_ponownie.name = "PrzyciskPonownie"
	przycisk_ponownie.text = "Zagraj ponownie"
	przycisk_ponownie.set_meta("neon_akcent", Color("#55e7ff"))
	StylMenu.styluj_przycisk(przycisk_ponownie, Vector2(300.0, 52.0), Color("#55e7ff"), Color("#102838"), Color("#258fa5"), Color("#123b4a"), Color("#0e2d39"), Color("#35bcd5"), 20)
	przycisk_ponownie.z_index = 11
	przycisk_ponownie.pressed.connect(func(): replay_pressed.emit())
	add_child(przycisk_ponownie)
	przycisk_ponownie.hide()
	get_viewport().size_changed.connect(_ustaw_pozycje_ekranu_konca)
	_ustaw_pozycje_ekranu_konca()


func _ustaw_pozycje_ekranu_konca():
	var wymiar = get_viewport().get_visible_rect().size
	var srodek = wymiar * 0.5
	var karta = $KartaKoniecGry
	if podsumowanie_endless:
		$PodsumowanieStatystyk.custom_minimum_size = Vector2(508.0, 306.0)
		karta.position = srodek - Vector2(310.0, 325.0)
		karta.size = Vector2(620.0, 650.0)
		$Komunikat.position = srodek + Vector2(-270.0, -287.0)
		$Komunikat.size = Vector2(540.0, 72.0)
		$WynikKoncowy.position = srodek + Vector2(-270.0, -207.0)
		$WynikKoncowy.size = Vector2(540.0, 48.0)
		$PodsumowanieStatystyk.position = srodek + Vector2(-255.0, -148.0)
		$PodsumowanieStatystyk.size = Vector2(508.0, 306.0)
		$PrzyciskPonownie.position = srodek + Vector2(-150.0, 171.0)
		$PrzyciskMenu.position = srodek + Vector2(-150.0, 229.0)
	else:
		$PodsumowanieStatystyk.custom_minimum_size = Vector2(508.0, 200.0)
		karta.position = srodek - Vector2(310.0, 280.0)
		karta.size = Vector2(620.0, 560.0)
		$Komunikat.position = srodek + Vector2(-270.0, -228.0)
		$Komunikat.size = Vector2(540.0, 96.0)
		$WynikKoncowy.position = srodek + Vector2(-270.0, -132.0)
		$WynikKoncowy.size = Vector2(540.0, 48.0)
		$PodsumowanieStatystyk.position = srodek + Vector2(-255.0, -70.0)
		$PodsumowanieStatystyk.size = Vector2(508.0, 200.0)
		$PrzyciskPonownie.position = srodek + Vector2(-150.0, 139.0)
		$PrzyciskMenu.position = srodek + Vector2(-150.0, 198.0)
	$PrzyciskPonownie.size = Vector2(300.0, 52.0)
	$PrzyciskMenu.size = Vector2(300.0, 52.0)
	# Całe podsumowanie mieści się również w niższym oknie.
	var wysokosc = 650.0 if podsumowanie_endless else 560.0
	var skala = clampf(minf((wymiar.x - 48.0) / 620.0, (wymiar.y - 48.0) / wysokosc), 0.1, 1.0)
	for element: Control in [karta, $Komunikat, $WynikKoncowy, $PodsumowanieStatystyk, $PrzyciskPonownie, $PrzyciskMenu]:
		element.scale = Vector2.ONE * skala
		element.position = srodek + (element.position - srodek) * skala - element.pivot_offset * (1.0 - skala)
		if element is Button:
			element.set_meta("neon_skala_bazowa", Vector2.ONE * skala)


func _utworz_podsumowanie_statystyk() -> void:
	var siatka = GridContainer.new()
	siatka.name = "PodsumowanieStatystyk"
	siatka.columns = 2
	siatka.custom_minimum_size = Vector2(508.0, 306.0)
	siatka.size = Vector2(508.0, 306.0)
	siatka.add_theme_constant_override("h_separation", 24)
	siatka.add_theme_constant_override("v_separation", 12)
	siatka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	siatka.z_index = 11
	add_child(siatka)
	siatka.hide()

	for i in range(6):
		var uklad_statystyki = VBoxContainer.new()
		uklad_statystyki.custom_minimum_size = Vector2(242.0, 94.0)
		uklad_statystyki.add_theme_constant_override("separation", 4)
		uklad_statystyki.mouse_filter = Control.MOUSE_FILTER_IGNORE
		siatka.add_child(uklad_statystyki)

		var nazwa = Label.new()
		nazwa.custom_minimum_size = Vector2(242.0, 28.0)
		nazwa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nazwa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nazwa.add_theme_font_size_override("font_size", 16)
		nazwa.add_theme_color_override("font_color", Color("#c5d8ed"))
		nazwa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		uklad_statystyki.add_child(nazwa)
		etykiety_nazw_statystyk.append(nazwa)

		var karta = PanelContainer.new()
		karta.custom_minimum_size = Vector2(242.0, 62.0)
		karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var styl = StyleBoxFlat.new()
		styl.bg_color = Color("#55e7ff", 0.035)
		styl.border_color = Color("#315270")
		styl.set_border_width_all(0)
		styl.set_corner_radius_all(12)
		styl.shadow_color = Color("#55e7ff12")
		styl.shadow_size = 0
		styl.content_margin_left = 10.0
		styl.content_margin_right = 10.0
		styl.content_margin_top = 4.0
		styl.content_margin_bottom = 4.0
		karta.add_theme_stylebox_override("panel", styl)
		uklad_statystyki.add_child(karta)

		var wartosc = Label.new()
		wartosc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wartosc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wartosc.add_theme_font_size_override("font_size", 31)
		wartosc.add_theme_font_override("font", FONT_ARCADE)
		wartosc.add_theme_color_override("font_color", Color("#55e7ff"))
		wartosc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		karta.add_child(wartosc)
		etykiety_wartosci_statystyk.append(wartosc)


func _odswiez_statystyki_koncowe(dane: PodsumowanieMeczu) -> void:
	podsumowanie_endless = dane.tryb == "endless"
	_ustaw_pozycje_ekranu_konca()
	var czas = maxi(0, roundi(dane.czas_meczu))
	var tekst_czasu = "%02d:%02d" % [floori(float(czas) / 60.0), czas % 60]
	var nazwy: Array[String]
	var wartosci: Array[String]
	if dane.tryb == "endless":
		$WynikKoncowy.text = "WYNIK - %d" % dane.wynik_gracza
	else:
		$WynikKoncowy.text = "%d     :     %d" % [dane.wynik_gracza, dane.wynik_ai]

	if dane.tryb == "endless":
		nazwy = [
			"Czas próby", "Odbicia łącznie", "Idealne odbicia",
			"Zdobyte ulepszenia",
			"Prędkość piłki", "Rozmiar paletki"
		]
		wartosci = [
			tekst_czasu,
			str(dane.odbicia_lacznie),
			str(dane.mocne_odbicia_lacznie),
			str(dane.ulepszenia_endless),
			"×%.2f" % dane.mnoznik_predkosci_endless,
			"%d%%" % dane.rozmiar_paletki_endless
		]
	else:
		nazwy = ["Czas meczu", "Odbicia łącznie", "Mocne odbicia łącznie", "Najdłuższa wymiana"]
		wartosci = [
			tekst_czasu,
			str(dane.odbicia_lacznie),
			str(dane.mocne_odbicia_lacznie),
			str(dane.najdluzsza_wymiana)
		]

	for i in range(6):
		$PodsumowanieStatystyk.get_child(i).visible = i < nazwy.size()
		if i >= nazwy.size():
			continue
		etykiety_nazw_statystyk[i].text = nazwy[i]
		etykiety_wartosci_statystyk[i].text = wartosci[i]
		var kolor_wartosci := Color("#55e7ff")
		etykiety_wartosci_statystyk[i].add_theme_color_override("font_color", kolor_wartosci)


func pokaz(tekst: String, dane: PodsumowanieMeczu) -> void:
	$Komunikat.text = tekst
	$Komunikat.show()
	$PrzyciskMenu.show()
	$PrzyciskPonownie.show()
	$PrzyciemnienieKoniecGry.show()
	$KartaKoniecGry.show()
	_odswiez_statystyki_koncowe(dane)
	$WynikKoncowy.show()
	$PodsumowanieStatystyk.show()
	_animuj_pokaz_podsumowania()


func _animuj_pokaz_podsumowania() -> void:
	var warstwy: Array[Control] = [
		$PrzyciemnienieKoniecGry,
		$KartaKoniecGry,
		$Komunikat,
		$WynikKoncowy,
		$PodsumowanieStatystyk,
		$PrzyciskPonownie,
		$PrzyciskMenu
	]
	for warstwa in warstwy:
		warstwa.modulate.a = 0.0
	var animacja = create_tween()
	animacja.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for warstwa in warstwy:
		animacja.parallel().tween_property(warstwa, "modulate:a", 1.0, 0.22)
