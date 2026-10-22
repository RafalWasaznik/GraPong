extends RefCounted


static func utworz_dzwiek_bonusu() -> AudioStreamWAV:
	return _utworz_dwutonowy_dzwiek(760.0, 980.0, 0.12, 22.0, 0.3)


static func utworz_dzwiek_modyfikatora() -> AudioStreamWAV:
	return _utworz_dwutonowy_dzwiek(620.0, 480.0, 0.15, 17.0, 0.24)


static func utworz_dzwiek_kamienia_milowego() -> AudioStreamWAV:
	return _utworz_dwutonowy_dzwiek(740.0, 1110.0, 0.2, 12.0, 0.38)


static func utworz_dzwiek_rekordu() -> AudioStreamWAV:
	return _utworz_dwutonowy_dzwiek(880.0, 1320.0, 0.34, 7.0, 0.52)


static func _utworz_dwutonowy_dzwiek(pierwszy_ton: float, drugi_ton: float, czas: float, tempo_wygaszania: float, glosnosc: float) -> AudioStreamWAV:
	const CZESTOTLIWOSC = 22050
	var liczba_probek = int(CZESTOTLIWOSC * czas)
	var dane = PackedByteArray()
	dane.resize(liczba_probek * 2)
	var faza = 0.0
	var indeks_drugiej_nuty = int(liczba_probek * 0.48)

	for indeks in range(liczba_probek):
		var czas_proby = float(indeks) / float(CZESTOTLIWOSC)
		var druga_nuta = indeks >= indeks_drugiej_nuty
		if indeks == indeks_drugiej_nuty:
			faza = 0.0
		var czas_nuty = float(indeks - (indeks_drugiej_nuty if druga_nuta else 0)) / float(CZESTOTLIWOSC)
		var czestotliwosc = drugi_ton if druga_nuta else pierwszy_ton
		faza += TAU * czestotliwosc / float(CZESTOTLIWOSC)
		var obwiednia = clampf(czas_nuty / 0.002, 0.0, 1.0) * exp(-czas_nuty * tempo_wygaszania)
		var probka = (sin(faza) * 0.82 + sin(faza * 2.0) * 0.18) * obwiednia * glosnosc
		dane.encode_s16(indeks * 2, clampi(roundi(probka * 32767.0), -32768, 32767))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CZESTOTLIWOSC
	stream.stereo = false
	stream.data = dane
	return stream
