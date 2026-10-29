# Przebudowa wizualna bossów - weryfikacja

Zmieniony kod gry: `boss_run.gd`. Bez nowych tekstur, materiałów i scen bossów. Test: `docs/test_boss_wyglad.tscn`.

## Projekty

- Strażnik: pionowy szkielet z ciemnego metalu, sześć niezależnych bocznych płyt, osłony osiowe, widoczne łączniki i przeguby. Bursztynowy reaktor z obrotowymi segmentami, szczeliny energetyczne i boczna lufa z ładowaniem oraz odrzutem. Lekkie unoszenie i przechylenie odbywają się tylko w rysowaniu.
- Rdzeń: radialna konstrukcja sześciu segmentów wokół turkusowego reaktora. Satelity mają odrębne osłony i gniazda emiterów, które rozświetlają się przy przygotowaniu ataku i strzale. Zachowane oznaczenia podatnej zewnętrznej krawędzi, osłony, czasu odsłonięcia i bezpiecznej luki pulsu.

Oba typy mają cztery etapy HP (>75%, >50%, >25%, pozostałe), pęknięcia, ubytki pancerza, odsłonięte elementy mechaniczne, lokalne iskry i odłamki. Rozpad mieści przeciążenie, odrywanie płyt, błysk i wyrzut energii w dotychczasowych 0,5 s. Strażnik rozrzuca płyty odpowiadające jego konstrukcji; Rdzeń także rozłącza moduły satelitarne.

## Sprawdzenie

Godot 4.7.2, Windows, RTX 4070. Uruchomiono scenariusze ze źródeł w Mobile (D3D12) oraz Compatibility (OpenGL). Sprawdzono Strażnika i trzy konfiguracje Rdzenia (indeksy 1, 3, 5), cztery stany uszkodzeń, ataki, rozpad, cztery motywy tła oraz intensywność 0% i jakość tła 0. Końcowy scenariusz: **93 kontrole, 0 niepowodzeń**.

Kontrole obejmują: hitbox Strażnika 64x144, Rdzeń r30, satelity r18, liczebność satelitów, wszystkie cztery wzory Strażnika, salwy satelitów, blokowanie wewnętrznej strony satelity, 15 s odsłonięcia, regenerację, odwracanie orbit, dwie warstwy 70/102, bezpieczną lukę pulsu, wejście do walki i pojedyncze zakończenie po 0,5 s.

Porównanie z kopią sprzed przebudowy potwierdziło brak zmian w 13 funkcjach mechaniki: tworzeniu hitboxów, obrażeniach, wyborze wzorów, wystrzeleniu salwy, przygotowaniu Rdzenia, uszkodzeniach satelitów, odsłanianiu, regeneracji, pozycjonowaniu orbit i zapowiedziach Rdzenia. Zmiany w pętli fizyki ograniczają się do czasu życia błysków. Dodawanie pocisku jedynie rejestruje błysk. Parametry pocisków, ruch, trudność, punktacja i nagrody pozostały bez zmian.

To scenariusze runtime i oględziny zrzutów, bez ręcznego rozgrywania pełnego runu. Nie wykonano benchmarku słabszego GPU. Komunikaty silnika obejmują istniejący nieaktualny UID `wskazniki_dasha.gd` (działa odczyt po ścieżce); wcześniejsze headless zakończenie zgłaszało pozostające zasoby ObjectDB. Nie zmieniano tych niezależnych elementów.

Istniejący EXE wymaga nowego eksportu.
