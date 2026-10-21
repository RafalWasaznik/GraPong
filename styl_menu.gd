class_name StylMenu
extends RefCounted

static func styl_przycisku_karty(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var wynik := styl(tlo, obramowanie)
	wynik.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	wynik.shadow_size = 5
	wynik.shadow_offset = Vector2(0.0, 2.0)
	return wynik


static func styl_pola(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var wynik := StyleBoxFlat.new()
	wynik.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.82))
	wynik.border_color = obramowanie
	wynik.set_border_width_all(1)
	wynik.set_corner_radius_all(9)
	wynik.content_margin_left = 14.0
	wynik.content_margin_right = 14.0
	wynik.content_margin_top = 8.0
	wynik.content_margin_bottom = 8.0
	return wynik


static func dodaj_opis_trybu(przycisk: Button, tytul: String, opis: String, akcent: Color, font_arcade: Font) -> void:
	przycisk.text = ""
	przycisk.custom_minimum_size = Vector2(420.0, 72.0 if opis.is_empty() else 88.0)
	przycisk.tooltip_text = opis
	przycisk.set_meta("neon_akcent", akcent)
	var styl_karty := styl_przycisku_karty(Color("#101d31"), Color(akcent, 0.42))
	przycisk.add_theme_stylebox_override("normal", styl_karty)
	var styl_hover := styl_przycisku_karty(Color("#1a2d47"), akcent)
	styl_hover.set_border_width_all(2)
	styl_hover.shadow_color = Color(akcent, 0.38)
	styl_hover.shadow_size = 15
	styl_hover.shadow_offset = Vector2.ZERO
	przycisk.add_theme_stylebox_override("hover", styl_hover)
	var pasek := ColorRect.new()
	pasek.color = akcent
	pasek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pasek.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	pasek.offset_left = 0.0
	pasek.offset_right = 5.0
	przycisk.add_child(pasek)
	if opis.is_empty():
		var etykieta := Label.new()
		etykieta.text = tytul
		etykieta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etykieta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		etykieta.add_theme_font_override("font", font_arcade)
		etykieta.add_theme_font_size_override("font_size", 26)
		etykieta.add_theme_color_override("font_color", Color("#f2f8ff"))
		przycisk.add_child(etykieta)
		return
	var uklad := VBoxContainer.new()
	uklad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uklad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	uklad.offset_left = 22.0
	uklad.offset_right = -12.0
	uklad.offset_top = 11.0
	uklad.offset_bottom = -9.0
	uklad.add_theme_constant_override("separation", 2)
	przycisk.add_child(uklad)
	var etykieta_tytulu := Label.new()
	etykieta_tytulu.text = tytul
	etykieta_tytulu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_tytulu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta_tytulu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta_tytulu.add_theme_font_size_override("font_size", 22)
	etykieta_tytulu.add_theme_color_override("font_color", Color("#f2f8ff"))
	uklad.add_child(etykieta_tytulu)
	var etykieta_opisu := Label.new()
	etykieta_opisu.text = opis
	etykieta_opisu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_opisu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta_opisu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta_opisu.add_theme_font_size_override("font_size", 15)
	etykieta_opisu.add_theme_color_override("font_color", Color("#b9cde2"))
	uklad.add_child(etykieta_opisu)

static func styluj_przycisk(
	przycisk: Button,
	minimalny_rozmiar: Vector2,
	akcent: Color,
	tlo_normalne: Color,
	obramowanie_normalne: Color,
	tlo_najechane: Color,
	tlo_wcisniete: Color,
	obramowanie_wcisniete: Color,
	rozmiar_czcionki: int = 20
) -> void:
	przycisk.custom_minimum_size = minimalny_rozmiar
	przycisk.alignment = HORIZONTAL_ALIGNMENT_CENTER
	przycisk.add_theme_font_size_override("font_size", rozmiar_czcionki)
	przycisk.add_theme_color_override("font_color", Color("#e8f4ff"))
	przycisk.add_theme_color_override("font_hover_color", Color.WHITE)
	przycisk.add_theme_color_override("font_pressed_color", Color("#b8f5ff"))
	przycisk.add_theme_stylebox_override("normal", styl(tlo_normalne, obramowanie_normalne))
	przycisk.add_theme_stylebox_override("hover", styl(tlo_najechane, akcent))
	przycisk.add_theme_stylebox_override("pressed", styl(tlo_wcisniete, obramowanie_wcisniete))
	przycisk.add_theme_stylebox_override("focus", styl(tlo_normalne, akcent))
	przycisk.add_theme_stylebox_override("disabled", styl(Color("#151d2b"), Color("#293a4e")))
	przycisk.pivot_offset = minimalny_rozmiar * 0.5
	przycisk.resized.connect(func(): przycisk.pivot_offset = przycisk.size * 0.5)
	przycisk.mouse_entered.connect(animuj_najechanie.bind(przycisk, true))
	przycisk.mouse_exited.connect(animuj_najechanie.bind(przycisk, false))


static func animuj_najechanie(przycisk: Control, aktywne: bool) -> void:
	if aktywne and przycisk.has_meta("neon_akcent"):
		var akcent: Color = przycisk.get_meta("neon_akcent")
		var styl_hover = styl(Color("#1a2d47"), akcent)
		styl_hover.set_border_width_all(2)
		styl_hover.shadow_color = Color(akcent, 0.38)
		styl_hover.shadow_size = 15
		styl_hover.shadow_offset = Vector2.ZERO
		przycisk.add_theme_stylebox_override("hover", styl_hover)
	if przycisk.has_meta("animacja_najechania"):
		var poprzednia: Variant = przycisk.get_meta("animacja_najechania")
		if is_instance_valid(poprzednia):
			poprzednia.kill()
	var animacja = przycisk.create_tween()
	przycisk.set_meta("animacja_najechania", animacja)
	animacja.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacja.tween_property(przycisk, "scale", Vector2(1.035, 1.035) if aktywne else Vector2.ONE, 0.14)


static func styl(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.78))
	styl.border_color = obramowanie
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 18.0
	styl.content_margin_right = 18.0
	styl.content_margin_top = 8.0
	styl.content_margin_bottom = 8.0
	return styl
