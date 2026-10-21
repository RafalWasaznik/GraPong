extends Node

signal polaczono_z_hostem
signal blad_polaczenia
signal host_rozlaczyl
signal gracz_polaczyl(id: int)
signal gracz_rozlaczyl(id: int)
signal otrzymano_ustawienia_meczu(ustawienia: UstawieniaMeczuOnline)
signal nazwa_gracza_2_zmieniona(nazwa: String)

const PORT = 24567
const LIMIT_GRACZY = 2

var rola = ""
var pauza_lokalna = false
var runda_online = 0
var tryb_online = "klasyczny"
var nazwa_gracza_1 = "Gracz 1"
var nazwa_gracza_2 = "Gracz 2"
var warunek_meczu = "punkty"
var limit_punktow_meczu = 5
var limit_czasu_meczu = 180.0
var pozostaly_czas_meczu = 180.0


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id): gracz_polaczyl.emit(id))
	multiplayer.peer_disconnected.connect(func(id): gracz_rozlaczyl.emit(id))
	multiplayer.connected_to_server.connect(func(): polaczono_z_hostem.emit())
	multiplayer.connection_failed.connect(func(): blad_polaczenia.emit())
	multiplayer.server_disconnected.connect(func(): host_rozlaczyl.emit())


func utworz_serwer(wybrany_tryb: String = "klasyczny", nazwa_hosta: String = "Gracz 1", warunek: String = "punkty", wartosc_warunku: int = 5) -> Error:
	rozlacz()
	runda_online = 0
	tryb_online = "arena" if wybrany_tryb == "arena" else "klasyczny"
	nazwa_gracza_1 = _oczysc_nazwe(nazwa_hosta, "Gracz 1")
	nazwa_gracza_2 = "Gracz 2"
	warunek_meczu = "czas" if warunek == "czas" else "punkty"
	limit_punktow_meczu = clampi(wartosc_warunku, 1, 50) if warunek_meczu == "punkty" else 5
	limit_czasu_meczu = float(clampi(wartosc_warunku, 1, 60) * 60) if warunek_meczu == "czas" else 180.0
	pozostaly_czas_meczu = limit_czasu_meczu
	var peer = ENetMultiplayerPeer.new()
	var blad = peer.create_server(PORT, LIMIT_GRACZY - 1)
	if blad != OK:
		return blad
	multiplayer.multiplayer_peer = peer
	rola = "host"
	return OK


func dolacz_do_serwera(adres: String) -> Error:
	rozlacz()
	runda_online = 0
	var docelowy_adres = adres.strip_edges()
	if docelowy_adres.is_empty():
		return ERR_INVALID_PARAMETER
	var peer = ENetMultiplayerPeer.new()
	var blad = peer.create_client(docelowy_adres, PORT)
	if blad != OK:
		return blad
	multiplayer.multiplayer_peer = peer
	rola = "klient"
	return OK


func rozlacz() -> void:
	rola = ""
	pauza_lokalna = false
	multiplayer.multiplayer_peer = null


func czy_host() -> bool:
	return rola == "host" and multiplayer.is_server()


func czy_klient() -> bool:
	return rola == "klient" and multiplayer.multiplayer_peer != null


func popros_o_ustawienia_meczu(nazwa_gracza: String) -> void:
	if czy_klient() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		nazwa_gracza_2 = _oczysc_nazwe(nazwa_gracza, "Gracz 2")
		rpc_id(1, "online_wyslij_ustawienia_meczu", nazwa_gracza_2)


@rpc("any_peer", "call_remote", "reliable")
func online_wyslij_ustawienia_meczu(nazwa_gracza: String) -> void:
	if not czy_host():
		return
	var nadawca = multiplayer.get_remote_sender_id()
	if nadawca <= 0 or not multiplayer.get_peers().has(nadawca):
		return
	nazwa_gracza_2 = _oczysc_nazwe(nazwa_gracza, "Gracz 2")
	nazwa_gracza_2_zmieniona.emit(nazwa_gracza_2)
	var ustawienia := UstawieniaMeczuOnline.new()
	ustawienia.tryb = tryb_online
	ustawienia.nazwa_gracza_1 = nazwa_gracza_1
	ustawienia.nazwa_gracza_2 = nazwa_gracza_2
	ustawienia.warunek = warunek_meczu
	ustawienia.limit_punktow = limit_punktow_meczu
	ustawienia.limit_czasu = limit_czasu_meczu
	rpc_id(nadawca, "online_odbierz_ustawienia_meczu", ustawienia.do_json())


@rpc("authority", "call_remote", "reliable")
func online_odbierz_ustawienia_meczu(pakiet_json: String) -> void:
	if not czy_klient():
		return
	var ustawienia := UstawieniaMeczuOnline.z_jsonu(pakiet_json)
	if ustawienia == null:
		push_warning("Odrzucono ustawienia meczu online: niezgodna wersja schematu lub nieprawidłowe dane.")
		blad_polaczenia.emit()
		return
	tryb_online = ustawienia.tryb
	nazwa_gracza_1 = ustawienia.nazwa_gracza_1
	nazwa_gracza_2 = ustawienia.nazwa_gracza_2
	warunek_meczu = ustawienia.warunek
	limit_punktow_meczu = ustawienia.limit_punktow
	limit_czasu_meczu = ustawienia.limit_czasu
	pozostaly_czas_meczu = limit_czasu_meczu
	otrzymano_ustawienia_meczu.emit(ustawienia)


func _oczysc_nazwe(nazwa: String, domyslna: String) -> String:
	var oczyszczona = nazwa.strip_edges().replace("\n", " ").replace("\r", " ")
	if oczyszczona.is_empty():
		return domyslna
	return oczyszczona.substr(0, 16)


func adresy_ipv4_lokalne() -> PackedStringArray:
	var wynik: PackedStringArray = []
	var tailscale = adresy_tailscale()
	for adres in IP.get_local_addresses():
		if adres.split(".").size() == 4 and not adres.begins_with("127.") and not adres.begins_with("169.254.") and not tailscale.has(adres):
			wynik.append(adres)
	return wynik


func adresy_tailscale() -> PackedStringArray:
	var wynik: PackedStringArray = []
	for adres in IP.get_local_addresses():
		var oktety = adres.split(".")
		if oktety.size() != 4 or oktety[0] != "100" or not oktety[1].is_valid_int():
			continue
		var drugi_oktet = oktety[1].to_int()
		if drugi_oktet < 64 or drugi_oktet > 127:
			continue
		var poprawny_ipv4 = true
		for oktet in oktety:
			if not oktet.is_valid_int() or oktet.to_int() < 0 or oktet.to_int() > 255:
				poprawny_ipv4 = false
				break
		if poprawny_ipv4:
			wynik.append(adres)
	return wynik
