# Zasoby oprawy Neon Arcade

## VFX 2D Free

Źródła lokalne: `addons/vfx_2d/README.md`, `vfx_2d.gd`, `demo/demo.gd`, `LICENSE.txt`.
Biblioteka deklaruje Godot 4.3+ i renderery Forward+, Mobile oraz Compatibility. Projekt używa Godot 4.7/Mobile. Zgodność deklarowana i przegląd kodu nie zastępują uruchomienia na docelowym rendererze.

W tej kopii są cztery efekty: `spark`, `explosion`, `smoke`, `fire`. Lista 16 nazw w README i stałej `EFFECTS` opisuje pełny pakiet; pozostałych plików shaderów nie ma. `VFX2D.effects()` filtruje listę według rzeczywistych zasobów. W grze należy korzystać wyłącznie z zainstalowanych efektów. Efekty są prostokątami renderowanymi shaderem, nie systemami cząsteczek.

Sprawdzone API biblioteki:

- `VFX2D.spawn(parent, name, global_position, options)` tworzy efekt; opcje to właściwości węzła albo uniformy.
- W kodzie gry preferowane jest jawne `VFX2D.new()`, ustawienie `effect`, `size`, `duration`, `z_index` i `set_param()`, następnie dodanie węzła do drzewa.
- `color_core`, `color_mid`, `color_edge` sterują paletą. `intensity` steruje jasnością/przezroczystością, `pixel_size = 0` daje gładką wersję.
- Jednorazowe efekty kończą się same. `free_when_done = false` pozwala ponawiać `play()`; pętle trzeba kończyć przez `stop()`.
- Efekt kontaktu powinien być mały i krótki. `spark` pasuje do odbić, a stonowana `explosion` do punktów/rozbicia. Dym i ogień nie są potrzebne na co dzień: zasłaniałyby tor piłki.

Wymagana informacja o autorze (CC BY 4.0):

> VFX 2D Free by heyheythere - https://heyheythere.itch.io/vfx-2d-free - CC BY 4.0

Copyright (c) 2026 heyheythere. Informacja o autorze i licencji jest dostępna także w ustawieniach, zakładka Inne, z adresem źródła w podpowiedzi. Pełna licencja pozostaje w `addons/vfx_2d/LICENSE.txt`. Integracja zmienia sposób wywoływania, kolor, skalę, intensywność i czas trwania efektów; źródła biblioteki pozostają zachowane.

## Shadery projektu

Wszystkie trzy mają `shader_type canvas_item` i `render_mode unshaded`. Nie potrzebują postprocessingu ani WorldEnvironment do podstawowego działania.

| Zasób | Użycie i poprawki |
| --- | --- |
| `background_grid_scroller.gdshader` | Ciemna, delikatna siatka. `rect_size` należy ustawić na rozmiar prostokąta, żeby komórki nie były rozciągnięte. Zachowano nazwy istniejących uniformów. Poprawiono odwrócone argumenty `smoothstep`, wygładzono krawędzie, zachowano modulację i alpha tła. `line_color.a` oraz `glow_color.a` wyznaczają siłę dekoracji. |
| `glow_effect_2d.gdshader` | Delikatnie rozjaśnia wybrane kolory istniejącej tekstury. Nie generuje poświaty poza obrysem. Dodano bezpieczne wartości domyślne, miękki próg, zachowanie alpha i modulacji. |
| `2D Outline Shader.gdshader` | Kontur dla tekstur z przezroczystym marginesem, nie dla proceduralnych wielokątów. Naprawiono niezainicjalizowany wynik, próbkowanie poza UV, obsługę częściowej alpha i tint. Domyślnie brak migotania. |

Shadery glow/outline wymagają tekstury i nie powinny być nakładane na cały proceduralny węzeł piłki/paletki. Takie użycie mogłoby zepsuć obecne rysowanie. Używamy ich tylko tam, gdzie ma to uzasadnienie; sama dostępność pliku nie oznacza obowiązku użycia.

Dwa dostarczone UID pozostawiono bez zmian. Dla shadera glow UID ma wygenerować Godot przy imporcie; nie wpisano ręcznie nowego identyfikatora. W folderze shaderów nie ma informacji o pierwotnym autorze ani licencji. Zachowano pliki użytkownika, a przed zewnętrzną dystrybucją trzeba zachować informacje z ich oryginalnego źródła.

## Kenney UI

Pakiet jest dostępny w `assets/kenney_ui/`: 868 PNG, 434 SVG, 6 OGG i 2 TTF. Zawiera warianty Blue/Green/Grey/Red/Yellow, dźwięki click/switch/tap i fonty Kenney Future oraz Kenney Future Narrow.

Obejrzany `PNG/Blue/Double/button_rectangle_border.png` ma jasne wypełnienie i mocną, podwójną fazowaną ramkę. Nie pasuje do oszczędnego ciemnego interfejsu tak dobrze jak obecne motywy. Zachowano Oxanium dla spójności i polskich znaków. Nie zastępujemy automatycznie wszystkich przycisków grafikami z pakietu.

Dołączony `assets/kenney_ui/License.txt` identyfikuje UI Pack (2.0), Kenney, 12-06-2024, Creative Commons Zero (CC0): http://creativecommons.org/publicdomain/zero/1.0/. Licencja dopuszcza użycie osobiste, edukacyjne i komercyjne; credit Kenney jest dobrowolny. Plik licencji pozostaje przy zasobach. Integracja wykorzystuje krótkie dźwięki UI z tego pakietu; jasne grafiki przycisków i nowe fonty pominięto ze względu na spójność stylistyczną.

## Weryfikacja

Przegląd obejmował rzeczywiste pliki, przykłady, licencje VFX i Kenney oraz dokumentację CanvasItem Shader Godot 4.7 (COLOR/modulate, TEXTURE_PIXEL_SIZE). Integracja na Godot 4.7.2: import projektu zakończony poprawnie; uruchomienie czterech trybów na rendererze Compatibility bez błędów kompilacji shaderów. Przy zamykaniu zgłoszono dwa wycieki GLES texture RID; wymaga to dalszej oceny w integracji. To sprawdzenie uruchomienia nie dowodzi poprawności całej rozgrywki ani multiplayera na dwóch komputerach. Audyt zasobów nie uruchamiał drugiej instancji Godota.


## Wynik wdrożenia i kontroli 2026-10-29

- Wspólny `EfektyMeczu`: VFX spark/explosion, limit 20 efektów, cztery ponownie używane emitery GPUParticles2D po 8 cząsteczek. Kolizje, punkty i odebrane wydarzenia online uruchamiają wyłącznie oprawę, bez zmiany pakietów sieciowych.
- Piłka: smuga i poświata zależne od prędkości, wizualna deformacja przy uderzeniu bez zmiany kolizji. Paletki: kolor gracza, impulsy energii, buforowane style zamiast nowych StyleBoxów przy każdym rysowaniu.
- Siatka: osobne tempo, gęstość i akcent dla Klasycznego, Nieskończonego i Areny; akcent Areny reaguje na strefę przyspieszenia i ścianę środka. Zachowane oznaczenia mechanik i granice.
- UI: menu, wybór trybów, pauza, wspólne ustawienia, wybór ulepszeń, wyniki i statystyki; płynne przejścia, czytelny fokus i spójne panele. Krótkie teksty oraz brak podtytułu Nieskończonego pozostają.
- Suwak 0–100% w ustawieniach Ekran, zapis do ustawienia użytkownika, wspólny dla menu i pauzy. Brak hit-stopu i drżenia przy idealnym odbiciu.
- Import Godot 4.7.2 headless: zakończony. Kontrola diff: bez błędów whitespace.
- Kontrola z rendererem Mobile/D3D12: uruchomione bot, 2graczy, Arena, Nieskończony; renderowane VFX, pauza, ustawienia i ekran końca. W Nieskończonym wybrane ulepszenie, potwierdzone zastosowanie i wznowienie po pauzie. Sprawdzone podłączenia przycisków menu i ponownej gry. Zrzuty zapisane w `.godot/visual-review/`.
- Końcowy log Mobile: cztery `VISUAL_SMOKE_OK`, bez błędów i ostrzeżeń. Wcześniejszy problem zwalniania tekstur kursora przy zamknięciu został poprawiony; usunięto też przestarzałą właściwość all_tabs_in_front.
- Compatibility/OpenGL: wcześniejsza kontrola uruchomienia i shaderów VFX/siatki przeszła; po poprawce zwalniania kursora końcową pełną kontrolę wykonano w Mobile.
- Nie ma skonfigurowanych automatycznych testów projektu. Pomocnicza scena kontrolna znajduje się tylko w ignorowanym `.godot/`; nie wchodzi do gry ani eksportu.
- Nadal wymagane: dłuższa rozgrywka, wszystkie kombinacje wydarzeń Areny i bossów oraz mecz online na dwóch komputerach. Lokalny test nie potwierdza multiplayera end-to-end.
- Glow i outline zostały naprawione i przygotowane dla teksturowanych obiektów; nie nakładano ich na proceduralnie rysowane piłkę i paletki. Nie dodawano efektów tylko po to, aby wykorzystać każdy shader.
