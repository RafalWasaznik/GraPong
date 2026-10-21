class_name KonfiguracjaOnline
extends Node

signal pokaz_ekran_requested(ekran: Control)
signal pokaz_wybor_trybu_requested

var ekran_online: VBoxContainer
var wybor_online: VBoxContainer
var ekran_host_online: VBoxContainer
var ekran_dolacz_online: VBoxContainer
var tytul_online: Label
var instrukcje_polaczenia: Label
var status_online: Label
var adres_online: LineEdit
var nazwa_hosta_online: LineEdit
var nazwa_dolaczajacego_online: LineEdit
var warunek_online: OptionButton
var wartosc_warunku_online: SpinBox
var etykieta_warunku_online: Label
var wskazowka_warunku_online: Label
var adresy_hosta_label: Label
var kopiuj_adres_hosta: Button
var przycisk_tryb_online_arena: Button
var adres_hosta_do_skopiowania = ""
var tryb_ekranu = "wybor"


func inicjalizuj(kontrole: KontrolkiKonfiguracjiOnline) -> void:
	ekran_online = kontrole.ekran
	wybor_online = kontrole.wybor
	ekran_host_online = kontrole.host
	ekran_dolacz_online = kontrole.dolacz
	tytul_online = kontrole.tytul
	instrukcje_polaczenia = kontrole.instrukcje
	status_online = kontrole.status
	adres_online = kontrole.adres
	nazwa_hosta_online = kontrole.nazwa_hosta
	nazwa_dolaczajacego_online = kontrole.nazwa_dolaczajacego
	warunek_online = kontrole.warunek
	wartosc_warunku_online = kontrole.wartosc_warunku
	etykieta_warunku_online = kontrole.etykieta_warunku
	wskazowka_warunku_online = kontrole.wskazowka_warunku
	adresy_hosta_label = kontrole.adresy_hosta
	kopiuj_adres_hosta = kontrole.kopiuj_adres
	przycisk_tryb_online_arena = kontrole.tryb_arena

	warunek_online.item_selected.connect(_zmien_warunek)
	kopiuj_adres_hosta.pressed.connect(_kopiuj_adres_hosta)
	Siec.polaczono_z_hostem.connect(_online_polaczono_z_hostem)
	Siec.otrzymano_ustawienia_meczu.connect(_online_tryb_meczu_otrzymany)
	Siec.blad_polaczenia.connect(_online_blad_polaczenia)


func pokaz() -> void:
	status_online.text = ""
	tryb_ekranu = "wybor"
	wybor_online.show()
	ekran_host_online.hide()
	ekran_dolacz_online.hide()
	tytul_online.text = "Gra online"
	instrukcje_polaczenia.text = "Obaj gracze muszą być połączeni przez Tailscale. Wybierz swoją rolę."
	_odswiez_adresy_hosta()
	pokaz_ekran_requested.emit(ekran_online)


func pokaz_ustawienia_hosta() -> void:
	tryb_ekranu = "host"
	status_online.text = ""
	wybor_online.hide()
	ekran_dolacz_online.hide()
	ekran_host_online.show()
	tytul_online.text = "Utwórz mecz"
	instrukcje_polaczenia.text = "Wybierz tryb, utwórz mecz i wyślij adres drugiemu graczowi."
	_odswiez_adresy_hosta()


func pokaz_ustawienia_dolaczania() -> void:
	tryb_ekranu = "dolacz"
	status_online.text = ""
	wybor_online.hide()
	ekran_host_online.hide()
	ekran_dolacz_online.show()
	tytul_online.text = "Dołącz do meczu"
	instrukcje_polaczenia.text = "Wpisz adres Tailscale hosta, aby dołączyć do jego meczu."
	adres_online.grab_focus()


func wroc() -> void:
	if tryb_ekranu != "wybor":
		if Siec.czy_klient():
			Siec.rozlacz()
		status_online.text = ""
		tryb_ekranu = "wybor"
		wybor_online.show()
		ekran_host_online.hide()
		ekran_dolacz_online.hide()
		tytul_online.text = "Gra online"
		instrukcje_polaczenia.text = "Obaj gracze muszą być połączeni przez Tailscale. Wybierz swoją rolę."
		return
	if Siec.czy_klient():
		Siec.rozlacz()
	pokaz_wybor_trybu_requested.emit()


func _zmien_warunek(indeks: int) -> void:
	if indeks == 1:
		etykieta_warunku_online.text = "Czas gry"
		wartosc_warunku_online.min_value = 1
		wartosc_warunku_online.max_value = 60
		wartosc_warunku_online.value = 3
		wartosc_warunku_online.suffix = " min"
		wskazowka_warunku_online.show()
	else:
		etykieta_warunku_online.text = "Limit punktów"
		wartosc_warunku_online.min_value = 1
		wartosc_warunku_online.max_value = 50
		wartosc_warunku_online.value = 5
		wartosc_warunku_online.suffix = " pkt"
		wskazowka_warunku_online.hide()


func _odswiez_adresy_hosta() -> void:
	var adresy_tailscale = Siec.adresy_tailscale()
	var adresy_lokalne = Siec.adresy_ipv4_lokalne()
	kopiuj_adres_hosta.disabled = false
	var tekst_tailscale = ", ".join(adresy_tailscale) if not adresy_tailscale.is_empty() else "niedostępny — uruchom Tailscale"
	var tekst_lokalny = ", ".join(adresy_lokalne) if not adresy_lokalne.is_empty() else "brak"
	adresy_hosta_label.text = "Adresy do udostępnienia jako host\nTailscale: %s\nSieć lokalna: %s" % [tekst_tailscale, tekst_lokalny]
	if not adresy_tailscale.is_empty():
		adres_hosta_do_skopiowania = adresy_tailscale[0]
		kopiuj_adres_hosta.text = "Kopiuj adres Tailscale"
	elif not adresy_lokalne.is_empty():
		adres_hosta_do_skopiowania = adresy_lokalne[0]
		kopiuj_adres_hosta.text = "Kopiuj adres lokalny"
	else:
		adres_hosta_do_skopiowania = ""
		kopiuj_adres_hosta.text = "Brak adresu do skopiowania"
		kopiuj_adres_hosta.disabled = true


func _kopiuj_adres_hosta() -> void:
	if adres_hosta_do_skopiowania.is_empty():
		return
	DisplayServer.clipboard_set(adres_hosta_do_skopiowania)
	status_online.text = "Skopiowano adres: %s" % adres_hosta_do_skopiowania


func utworz_mecz() -> void:
	var arena = przycisk_tryb_online_arena.button_pressed
	var tryb = "arena" if arena else "klasyczny"
	var warunek = "czas" if warunek_online.selected == 1 else "punkty"
	var blad = Siec.utworz_serwer(tryb, nazwa_hosta_online.text, warunek, int(wartosc_warunku_online.value))
	if blad != OK:
		status_online.text = "Nie udało się uruchomić hosta. Zamknij inne uruchomione mecze i spróbuj ponownie."
		return
	_przygotuj_tryb_online(arena)
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func dolacz_do_meczu() -> void:
	Siec.nazwa_gracza_2 = nazwa_dolaczajacego_online.text.strip_edges()
	var blad = Siec.dolacz_do_serwera(adres_online.text)
	if blad != OK:
		status_online.text = "Nie udało się rozpocząć połączenia. Sprawdź adres IP."
		return
	status_online.text = "Łączenie z hostem…"


func _online_polaczono_z_hostem() -> void:
	if not is_inside_tree() or not ekran_online.visible:
		return
	status_online.text = "Pobieranie ustawień meczu…"
	Siec.popros_o_ustawienia_meczu(nazwa_dolaczajacego_online.text)


func _online_tryb_meczu_otrzymany(ustawienia: Dictionary) -> void:
	if not is_inside_tree() or not ekran_online.visible:
		return
	_przygotuj_tryb_online(str(ustawienia.get("tryb", "klasyczny")) == "arena")
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _online_blad_polaczenia() -> void:
	if not is_inside_tree():
		return
	Siec.rozlacz()
	if is_instance_valid(status_online):
		status_online.text = "Nie udało się połączyć. Sprawdź IP, zaporę i dostępność hosta."


func _przygotuj_tryb_online(arena: bool) -> void:
	Ustawienia.tryb = "online"
	Ustawienia.arena_dwoch_graczy = false
	Ustawienia.online_arena = arena
	Ustawienia.rozmiar_planszy = "standardowa"
	Ustawienia.limit_punktow = Siec.limit_punktow_meczu
	Ustawienia.ustaw_geometrie_planszy()
	Siec.pauza_lokalna = false
