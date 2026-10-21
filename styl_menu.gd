class_name StylMenu
extends RefCounted

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
