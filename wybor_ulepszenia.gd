class_name WyborUlepszenia
extends CanvasLayer

signal wybrano

var stan: RunState
var oferty: Array[UlepszenieRun] = []
var tlo: ColorRect
var kolumna: VBoxContainer
var tytul: Label
var przyciski: Array[Button] = []
var odliczanie: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	tlo = ColorRect.new()
	tlo.color = Color("#07111bea")
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tlo)
	var srodek := CenterContainer.new()
	srodek.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tlo.add_child(srodek)
	kolumna = VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 18)
	srodek.add_child(kolumna)
	tytul = Label.new()
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tytul.add_theme_font_size_override("font_size", 26)
	tytul.add_theme_color_override("font_color", Color("#55e7ff"))
	kolumna.add_child(tytul)
	hide()


func pokaz(nowy_stan: RunState, nowe_oferty: Array[UlepszenieRun]) -> void:
	stan = nowy_stan
	oferty = nowe_oferty
	if oferty.is_empty():
		return
	stan.wybor_aktywny = true
	odliczanie = false
	for przycisk in przyciski:
		przycisk.queue_free()
	przyciski.clear()
	tytul.text = "WYBIERZ ULEPSZENIE - %d ODBIĆ" % stan.hits
	for i in range(oferty.size()):
		var oferta := oferty[i]
		var przycisk := Button.new()
		var rzadkosc := "Rzadkie" if oferta.rarity == UlepszenieRun.Rzadkosc.RZADKIE else "Zwykłe"
		if oferta.rarity == UlepszenieRun.Rzadkosc.PRZEKLETE:
			rzadkosc = "Przeklęte"
		przycisk.text = "%d. %s\n%s - %s (%d/%d)" % [i + 1, oferta.nazwa, oferta.opis, rzadkosc, stan.liczba_stosow(oferta.id), oferta.maxStacks]
		StylMenu.styluj_przycisk(przycisk, Vector2(540.0, 90.0), Color("#55e7ff"), Color("#111e32"), Color("#344d64"), Color("#192d45"), Color("#102638"), Color("#399bad"), 18)
		przycisk.pressed.connect(_wybierz.bind(i))
		kolumna.add_child(przycisk)
		przyciski.append(przycisk)
	show()
	get_tree().paused = true
	przyciski[0].grab_focus()


func _input(event: InputEvent) -> void:
	if not visible or stan == null or not stan.wybor_aktywny:
		return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo and not odliczanie:
			var indeks: int = -1
			match event.physical_keycode:
				KEY_1, KEY_KP_1: indeks = 0
				KEY_2, KEY_KP_2: indeks = 1
				KEY_3, KEY_KP_3: indeks = 2
			if indeks >= 0 and indeks < oferty.size():
				_wybierz(indeks)


func _wybierz(indeks: int) -> void:
	if odliczanie or not stan.wybor_aktywny:
		return
	odliczanie = true
	oferty[indeks].apply(stan)
	wybrano.emit()
	for przycisk in przyciski:
		przycisk.disabled = true
		przycisk.hide()
	for liczba in [3, 2, 1]:
		tytul.text = "WRACAMY DO GRY ZA %d" % liczba
		await get_tree().create_timer(1.0).timeout
	hide()
	stan.wybor_aktywny = false
	get_tree().paused = false
