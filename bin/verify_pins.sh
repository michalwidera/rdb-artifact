#!/usr/bin/env bash
# Sprawdza, czy przypiecia z MANIFEST.md zgadzaja sie ze stanem repozytoriow.
# Uruchamiac z katalogu, w ktorym leza sklonowane repozytoria, albo podac je
# zmiennymi RDB_ENGINE / RDB_EXPERIMENT.
#
#   ./bin/verify_pins.sh
#   RDB_ENGINE=~/github/retractordb RDB_EXPERIMENT=~/github/rdb-experiment ./bin/verify_pins.sh
#
# Kod wyjscia: 0 = wszystko zgodne, 1 = rozjazd.

set -uo pipefail

ENGINE="${RDB_ENGINE:-./retractordb}"
EXPERIMENT="${RDB_EXPERIMENT:-./rdb-experiment}"
SRC_TREE_K24E="5ddad0fc7d56fb9b468d31905a6689e9896ddb39"

blad=0
zle() { echo "BLAD $*"; blad=1; }
ok()  { echo "OK   $*"; }

# Przypiecia z MANIFEST.md, sekcja 2.2. Format: tag engine_sha experiment_sha
PRZYPIECIA=$(cat <<'TAB'
campaign/K6c-W2-W7 e1e5181141f96965da4a092f7e7191f8cb0b2748 f4483ef20c3bb3b6936f96709a593d1922943ada
campaign/K6c-W8-W9 1bb2d2ce8bec35cd0ab46d168249b706ccbaf303 -
campaign/K18       bc37186ac87cb944d76cf74c7be92706a4a3a87f e1e38ebe650d4c2752b98e78b463f93fe81b3d0e
campaign/K22v5     dd733e3792fbcd5727db244b802610a6d710b8dc 0390a8910d72ecaa80772f3fd31a5f18a05369aa
campaign/H9-K26v3  856ee54b0f4ab450a6b61e3c08e045f404a79488 81bf4bea00efb922678862c90462fb3c0dfe5fda
campaign/H10-K24d  34db1a291fff686d63402270722edf9c772bd4b6 15ee150a779e5374248f8172d197b976d604416d
campaign/H10-K24e  ef18105701158db9986d57fd74defdda72920871 a9d5e18e75ef7cf5dd8a63619f469517e13aa4af
TAB
)

for r in "$ENGINE" "$EXPERIMENT"; do
  [ -d "$r/.git" ] || { echo "BLAD brak repozytorium: $r"; exit 1; }
done

echo "=== 1. Tagi kampanii wskazuja SHA z manifestu ==="
while read -r tag esha xsha; do
  [ -z "$tag" ] && continue
  m=$(git -C "$ENGINE" rev-parse -q --verify "${tag}^{commit}" 2>/dev/null)
  if [ -z "$m" ]; then zle "$tag brak w silniku"
  elif [ "$m" != "$esha" ]; then zle "$tag silnik = $m, manifest = $esha"
  else ok "$tag silnik"; fi

  # Tag K6c-W8-W9 nie ma jeszcze odpowiednika po stronie eksperymentu (K9b/Krok 2).
  [ "$xsha" = "-" ] && { echo "     (pominieto strone eksperymentu - K9b/Krok 2)"; continue; }
  m=$(git -C "$EXPERIMENT" rev-parse -q --verify "${tag}^{commit}" 2>/dev/null)
  if [ -z "$m" ]; then
    # Kampania K6c ma po stronie eksperymentu tag o innej nazwie.
    m=$(git -C "$EXPERIMENT" rev-parse -q --verify "campaign/K6c^{commit}" 2>/dev/null)
  fi
  if [ -z "$m" ]; then zle "$tag brak w eksperymencie"
  elif [ "$m" != "$xsha" ]; then zle "$tag eksperyment = $m, manifest = $xsha"
  else ok "$tag eksperyment"; fi
done <<< "$PRZYPIECIA"

echo
echo "=== 2. Kazde przypiecie lezy na galezi glownej ==="
for t in $(git -C "$ENGINE" tag -l 'campaign/*'); do
  git -C "$ENGINE" merge-base --is-ancestor "${t}^{commit}" master 2>/dev/null \
    && ok "$t na master" || zle "$t POZA master"
done

echo
echo "=== 3. Dowod rownowaznosci K24e (drzewo src/) ==="
m=$(git -C "$ENGINE" rev-parse -q --verify "campaign/H10-K24e^{}:src" 2>/dev/null)
if [ "$m" = "$SRC_TREE_K24E" ]; then ok "src drzewa K24e = $m"
else zle "src drzewa K24e = ${m:-brak}, manifest = $SRC_TREE_K24E"; fi

echo
echo "=== 4. Parzystosc archiwow raw ==="
obecne=0; brak=0
while read -r i; do
  [ -z "$i" ] && continue
  d=$(dirname "$i"); b=$(basename "$i" .index.tsv)
  if [ -f "$EXPERIMENT/$d/$b.tar.gz" ]; then obecne=$((obecne+1)); else brak=$((brak+1)); fi
done <<< "$(git -C "$EXPERIMENT" ls-files | grep -i 'raw.index.tsv')"
echo "     indeksow: $((obecne+brak))  obecnych: $obecne  nieobecnych: $brak"
[ "$brak" -eq 4 ] && ok "zgodne z MANIFEST.md sekcja 4 (cztery nieobecne)" \
                  || echo "UWAGA manifest opisuje cztery nieobecne, znaleziono $brak"

echo
[ "$blad" -eq 0 ] && echo "WYNIK: wszystkie przypiecia zgodne z manifestem" \
                  || echo "WYNIK: ROZJAZD - patrz linie BLAD wyzej"
exit "$blad"
