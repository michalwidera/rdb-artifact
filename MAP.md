# MAPA KAMPANII — co która odpowiada i czy nadal obowiązuje

Ten plik istnieje po to, żeby czterdzieści dwa katalogi `results_*`
w `rdb-experiment` dały się przeczytać przez osobę, która ich nie tworzyła.
Manifest mówi, **na czym** mierzono; mapa mówi, **co** mierzono i **czy odczyt
nadal obowiązuje**.

Status ma trzy wartości:

* **obowiązujący** — wynik niesiony przez artykuł albo aktualny zapis projektu;
* **zastąpiony przez X** — wynik poprawny w swoim czasie albo diagnostyczny,
  którego rolę przejął późniejszy przebieg;
* **kontrola** — badanie higieniczne albo diagnostyka aparatury, nigdy nie było
  samodzielnym wynikiem artykułu.

Każdy z 42 katalogów `results_*` ma niżej osobny wiersz. Źródłem klasyfikacji
są `paper-arXiv/debs/research_plan.md` §3.6 i §14 oraz `rdb-experiment/JOURNAL.md`.

## Kampanie niosące bieżącą treść artykułu

| Katalog | Kryptonim | Pytanie, na które odpowiada | Status |
|---|---|---|---|
| `results_20260818_K24e` | K24e / H10 — *plan-derived startup boundaries* | Czy statyczny rachunek początku logicznego i ogona startowego jest dokładny w każdej klasie operatorów? | **obowiązujący** — dziewięć klas dokładnych na dziewięć, na obu ziarnach; źródło `tab:tail-exactness` |
| `results_20260814_K26v3` | K26v3 / H9 — *equivalence-guarded materialization sharing* | Czy kompilator, dopuściwszy dzielenie dopiero po dowodzie równoważności podplanów, dochodzi sam do wspólnego materializowanego podplanu — i czy redukcja **utrzymywanego stanu** przychodzi bez ceny czasowej? | **obowiązujący w klasie `Q=8`**, 3/3 rodziny; miarą pierwotną są bajty substratu na rekord publiczny (50,0–58,3% wobec ablacji, 84,4–87,5% wobec naturalnego planu Flinka), cena czasowa poniżej progu 1,05; upoważnienie nie rozciąga się na ogólną przewagę wydajnościową; źródło `tab:h9-primary` |
| `results_20260801_K22v5` | K22v5 / H8 | Jaki jest koszt specyfikacji i modyfikacji zapytania wobec rozwiązań proceduralnych? | **obowiązujący** — wynik opisowy `C1=C3=C4=0`; metryka ma podłogę jednostkową i tak jest opisana; źródło `tab:k22-constructs` |
| `results_20260730_K6c` | K6c | Gdzie leży granica zasobowa planu wielozapytaniowego? | **obowiązujący** — granica zmierzona; model kosztu slotu nieudany (`MAE_test=258%`) i tak opisany; źródło `tab:k6-primary` |
| `results_20260728_K18` | K18 | Czy powtórzenie nagrania daje bitowo identyczne artefakty i czy przeplot/rozplot jest tożsamością? | **obowiązujący** — 67 plików bez różnicy poza 8-bajtowym znacznikiem czasu; 13 sprawdzeń tożsamości |
| `results_20260728_K19` | K19 | Czy wzory fazowe `SUBTRACT` i AGSE oraz ich granice zgadzają się z silnikiem? | **obowiązujący** — 468 220 + 2 239 488 faz; luka pokrycia pojemności została później zmierzona w `results_20260728_extend` |
| `results_20260728_K4` | K4 | Która reguła R1/R2 odpala się w istniejącym korpusie i ile razy? | **obowiązujący** — pięć profili, 400 wyników; ograniczenie nieodtwarzalnej ścieżki jest jawne |
| `results_20260728_extend` | extend | Czy defekt pojemności AGSE unieważnił K18/K19/K4 i czy poprawiona rewizja zachowuje determinizm? | **obowiązujący jako audyt** — wyników nie unieważniono; etap czasowy 360 Hz powtórzono, exactness potwierdzono bajtowo |
| `results_20260726_G3` | K2 / G3 | Czy oracle R1 i most do silnika zgadzają się na pełnym korpusie? | **obowiązujący** — 75 548 przypadków / 143 065 922 pozycji oraz most 13/13 |
| `results_20260725` | oś SDF/CSDF | Czy cztery reprezentacje przeplotu mają ten sam ślad i jaki jest ich koszt strukturalny? | **obowiązujący** — podstawa `tab:repr`; późniejszy K2/G3 rozszerza most do bieżącej semantyki, ale nie zastępuje porównania reprezentacji |

## Historyczny kontekst nadal przywoływany w artykule

Te kampanie poprzedzają G1. Artykuł używa ich wyłącznie jako jawnie
historycznego kontekstu, nie jako dowodu bieżącej granicy wydajności.

| Katalog | Pytanie | Status |
|---|---|---|
| `results_20260716` | Pierwsza kampania rate/clients/FIR: gdzie leżą koszty wykonania i emisji? | **obowiązujący wyłącznie jako kontekst historyczny** — zastąpiony dla twierdzeń bieżącej rewizji przez K6c i K18 |
| `results_20260717` | Jak wypadają historyczne baseline'y NumPy i jedna konfiguracja Flink? | **obowiązujący wyłącznie jako kontekst historyczny** — nie ustanawia rankingu między systemami |
| `results_20260718` | Czy artefakty są deterministyczne i zgodne między architekturami? | **obowiązujący wyłącznie jako historyczny wynik cross-architecture**; bieżący replay sprawdza K18 |
| `results_20260719` | Czy izolacja kosztu 40 ms i kolejne pomiary rate/clients lokalizują źródło ogona? | **zastąpiony dla bieżących twierdzeń przez `results_20260721_bufferfix` i K18** |
| `results_20260721` | Jaki jest próg rate oraz wpływ klientów i głębokości FIR przed naprawą bufora? | **zastąpiony przez `results_20260721_bufferfix`**, zachowany jako punkt odniesienia |
| `results_20260722_thick_mesh` | Gdzie w gęstym sweepie leży historyczny próg między 480 a 510 Hz? | **obowiązujący wyłącznie jako kontekst historyczny** — nie jest bieżącym sufitem |

## Kampanie zastąpione — zapis historyczny

| Katalog | Kryptonim | Czym był | Status |
|---|---|---|---|
| `results_20260807_K24d` | K24d | Pomiar H10 na silniku `34db1a2`: sześć klas dokładnych z dziewięciu | **zastąpiony przez K24e** |
| `results_20260807_K24p` | K24p | Powtórzenie po zmianie silnika, opisuje `db4a360` | **zastąpiony przez K24d** |
| `results_20260804_K24r` | K24r | Potwierdzenie poza próbą członu (a) | **zastąpiony przez K24d** |
| `results_20260804_K24b` | K24b | Domknięcie członu (b), ziarno `20260805` | **zastąpiony przez K24d** |
| `results_20260803_K24` | K24 | Pierwsza kampania łuku; ujawniła pięć defektów silnika | **zastąpiony przez K24p** |
| `results_20260810_K26v2` | K26v2 | Iteracja H9 bez werdyktu | **zastąpiony przez K26v3** |
| `results_20260809_K26` | K26 | Iteracja H9 zamknięta jako `apparatus` | **zastąpiony przez K26v3** |
| `results_20260808_K23v2` | K23 iter. 2 | Iteracja H9; dwie rodziny odpadły na bramce poprawności | **zastąpiony przez K26v3** |
| `results_20260808_K23` | K23 iter. 1 | Pierwsza iteracja łuku H9 | **zastąpiony przez K23v2** |
| `results_20260801_K22v4` | K22 v4 | Zatrzymana iteracja kosztu specyfikacji | **zastąpiony przez K22v5** |
| `results_20260801_K22v3` | K22 v3 | Zatrzymana iteracja kosztu specyfikacji | **zastąpiony przez K22v4** |
| `results_20260801_K22v2` | K22 v2 | Zatrzymana iteracja kosztu specyfikacji | **zastąpiony przez K22v3** |
| `results_20260801_K22` | K22 v1 | Pilot i zapis rozwoju aparatury bez werdyktu H8 | **zastąpiony przez K22v2** |
| `results_20260730_K6b` | K6 v2 | Kampania kosztowa zatrzymana na defekcie klienta i błędnej definicji slotu | **zastąpiony przez K6c** |
| `results_20260730_K6` | K6 v1 | Pierwsza predeklaracja kampanii kosztowej | **zastąpiony przez K6b** |
| `results_20260729_K5_rerun` | K5 | Powtórzony punkt go/no-go po naprawie interwałów | **zastąpiony jako wynik strukturalny przez K6c**, zachowuje werdykt GO |
| `results_20260729_K5` | K5 iter. 1 | Kampania semantyczna zatrzymana po wykryciu defektu F9 | **zastąpiony przez `results_20260729_K5_rerun`** |
| `results_20260726_G1` | G1 / K1 | Sonda obserwowalności, która ujawniła zależność semantyki od planu i otworzyła naprawy G1 | **zastąpiony dla bieżącej semantyki przez K2/G3 i K18** |

## Kontrole i diagnostyka aparatury

| Katalog | Czym jest | Status |
|---|---|---|
| `results_20260731_instrument` | sonda pracy na slot, 43 komórko-skale | **kontrola** — K20 etap 1b, układ osobliwy, bez werdyktu |
| `results_20260731_hygiene220` | higiena sondy E4 na `abe075e` | **kontrola** — brak wpływu, warunek etapów 1b/1c |
| `results_20260731_hygiene217` | higiena naprawy klienta na `1bb2d2c` | **kontrola** — brak wpływu, ujawnia bias ilorazu |
| `results_20260731_hygiene` | higiena poprawki klienta na `e1e5181` | **kontrola** — brak wpływu |
| `results_20260731_costmodel3` | trzecia próba modelu kosztu slotu | **kontrola** — cecha rodziny okiennej nic nie wnosi |
| `results_20260730_hygiene` | higiena sondy pomiarowej | **kontrola** — brak wpływu |
| `results_20260729_hygiene` | higiena poprawki interwałów i deterministyczności aparatury | **kontrola** — brak wpływu; wykryła puste porównania jako fałszywy sukces |
| `results_20260721_bufferfix` | powtórka rate/clients/FIR po przywróceniu buforowania `facctxtsrc` | **kontrola naprawy aparatury** — źródło historycznego kontekstu, nie bieżący sufit |

## Hipotezy — stan

Numery `H*` są identyfikatorami hipotez w planie badawczym i w nazwach
katalogów kampanii. **Tekst artykułu widoczny dla recenzenta ich nie używa** —
od 2026-08-25 obie hipotezy niosące bieżącą treść występują tam pod nazwami
opisującymi wynik. Tabela niżej podaje oba brzmienia, żeby przejście z artykułu
do tego pakietu nie wymagało zgadywania:

| Numer | Nazwa w artykule (EN) | Nazwa w artykule (PL) | Kotwica w składzie |
|---|---|---|---|
| **H9** | `equivalence-guarded materialization sharing` | współdzielenie materializacji warunkowane równoważnością | `tab:h9-primary`, sekcja `sec:eval-sharing` |
| **H10** | `plan-derived startup boundaries` | granice startowe wyprowadzane z planu | `tab:tail-exactness`, sekcja `sec:foundations` |

| Hipoteza | Treść | Werdykt |
|---|---|---|
| **H8** | koszt specyfikacji i modyfikacji niższy niż w rozwiązaniach proceduralnych | **podzielona**; wynik opisowy, nigdzie nie pada „H8 obalona” (K22v5) |
| **H9** | dzielenie materializacji dopuszczone dopiero po dowodzie równoważności podplanów redukuje **bajty substratu na rekord publiczny** bez ceny czasowej | **wsparta w klasie `Q=8`**, 3/3 rodziny (K26v3, 2026-08-16) |
| **H10a** | statyczny rachunek ogona jest dokładny | **wsparta**, dziewięć klas na dziewięć (K24e, 2026-08-18) |
| **H10b** | rachunek jest **nielokalny** dla węzłów `#` o obu składowych deklarowanych: naturalna reguła lokalna niedomiarowuje, a niedomiar ma predeklarowaną postać zamkniętą `ceil((p+q-1)/p)` | **wsparta**, 2310/2310 rozjazdów o tej postaci (K24b, potwierdzenie K24d) |

**Treść H9 nie jest twierdzeniem o rozmiarze planu** i wcześniejsze brzmienie
tego wiersza („redukuje plan") było w tym miejscu mylące. Mierzoną wielkością
pierwotną są bajty utrzymywanego substratu na rekord publiczny; sam rozmiar
planu jako miara kosztu **odpadł** — pokazała to K6c (0/13 komórek, tokeny
mniejsze o 8–28% bez poprawy kosztu slotu). Obie kampanie mówią więc razem,
gdzie leży koszt: w utrzymywanym stanie, a nie w liczbie węzłów. Poprawione
2026-08-25.

**Treść H10b była zapisana odwrotnie do hipotezy** — wiersz orzekał lokalność
rachunku, podczas gdy zmierzono jej **brak**. H10 nazywa się w planie „dokładna
i **nielokalna** granica określoności planu wielotaktowego", a kryterium członu
(b) brzmi: wsparta, gdy naturalna reguła lokalna **rozjeżdża się** z dokładną
w co najmniej 5% korpusu i rozjazd ma postać `ceil((p+q-1)/p)` w 100%
przypadków (`paper-arXiv/debs/research_plan.md`, kryterium H10b). Liczba
2310/2310 to węzły, w których reguła lokalna **niedomiarowała**, a nie te,
w których wystarczyła; artykuł niesie to samo w akapicie *„Why the interleave
tail is not local"*. Werdykt bez zmian. Poprawione 2026-08-25.
