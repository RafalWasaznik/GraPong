# Drony, kryształy i paletki - 29.10.2026

## Implementacja

- `dron_run.gd`: parametry w jednym miejscu, 35% szansy zastąpienia kamienia, maksymalnie dwa żywe drony, standardowe HP, bazowa nagroda 2 z istniejącymi mnożnikami. Mechaniczny korpus, boczne silniki, działko, animacja energii, rozświetlenie ładowania i błysk lufy. Ostrzeżenie trwa 0,5 s, kierunek jest blokowany od początku. Cienka czerwona linia ma ciemną obwódkę dla kontrastu.
- `pocisk_drona_run.gd`: pocisk 300 px/s, kolizja ciągła przez move_and_collide, maska wyłącznie paletki gracza w Nieskończonym, jedno trafienie i usunięcie. Nie trafia kamieni ani dronów; znika poza planszą.
- `przebieg_meczu.gd`: generowanie, nagrody, obsługa pocisków przez istniejące życia/tarczę/dash/nietykalność; wspólne rozstrzyganie utraty życia. Czyszczenie pocisków przy przejściu do bossa, stracie życia i zakończeniu. Klasyczne tryby pozostają bez dronów.
- `krysztal_run.gd`, `shaders/rdzen_mechaniczny.gdshader`: warstwy mechanicznego pancerza, rdzeń, pęknięcia i rozpad; zachowane HP, geometria kolizji i warianty.
- `paletka_bazowa.gd`: obudowa, animowany przepływ energii, wyróżnione segmenty końcowe i reakcja na obrażenia. Zachowane rozmiary oraz mechanika odbić i dashu.
- `docs/test_dron_run.gd`, `.tscn`: pomocnicza scena kontroli integracji.

## Wykonane sprawdzenia

Godot 4.7.2, izolowane APPDATA/LOCALAPPDATA w `.godot/dron-test`, bez zmiany ustawień gracza.

21 asercji integracyjnych zakończyło się poprawnie: 3501 dronów na 10000 losowań, limit RNG i rzeczywistego spawnu, zgodność HP, półsekundowe ostrzeżenie, blokada kierunku mimo ruchu paletki, wystrzał i błysk, zakres interwału, unik ruchem, pojedyncze trafienie, tarcza, dash, nietykalność, jednoczesna strata piłki i trafienie z jedną utratą życia, nagroda z mnożnikami i zwolnienie limitu, geometria paletki, regeneracja, pauza, wybór ulepszeń, czyszczenie i izolacja klasycznego trybu dwóch graczy. Końcowy log: `WYNIK: 0 bledow`, kod wyjścia 0.

W rendererze Mobile/D3D12 na RTX 4070 wyrenderowano scenę z czterema kryształami, dronem w fazie ostrzegania i nową paletką na czterech tłach. Obejrzano zrzuty; shader rdzenia kompiluje się poprawnie.

Podglądy: [Cyberpunk](drony/motyw_1.png), [Kosmos](drony/motyw_2.png), [Synthwave](drony/motyw_3.png), [Matrix](drony/motyw_4.png).

Logi: `.godot/dron-test/runtime.log`, `visual.log`. Headless zgłasza przy zamykaniu dwa obiekty ObjectDB i jeden zasób pozostający w użyciu; renderowany przebieg zakończył się bez tych komunikatów. Poprawiono błędny znak procenta wyłącznie w wydruku pomocniczego testu i powtórzono testy.

Nie wykonano długiego pełnego meczu, kontrolowanego porównania FPS ze stanem sprzed zmian ani testu dwóch komputerów. Nie zmieniono pakietów sieciowych i nie wykonano eksportu EXE.
