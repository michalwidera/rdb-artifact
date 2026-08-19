#!/usr/bin/env bash
# Klonuje repozytoria pakietu do jawnego ukladu i przelacza je na przypiecia
# wskazane w MANIFEST.md. Kazde repozytorium osobno - bez submodulow.
#
#   ./bin/checkout.sh [katalog-docelowy] [tag-kampanii]
#
# Domyslnie: ./artifact-workspace, tag campaign/H10-K24e.
# Po zakonczeniu uruchom bin/verify_pins.sh.

set -euo pipefail

CEL="${1:-./artifact-workspace}"
TAG="${2:-campaign/H10-K24e}"
ENGINE_URL="https://github.com/michalwidera/retractordb.git"
EXPERIMENT_URL="https://github.com/michalwidera/rdb-experiment.git"

mkdir -p "$CEL"
cd "$CEL"

klon() {
  local url="$1" kat="$2"
  if [ -d "$kat/.git" ]; then
    echo "== $kat juz istnieje, pobieram tagi"
    git -C "$kat" fetch --tags --prune
  else
    echo "== klonuje $kat"
    git clone "$url" "$kat"
  fi
}

klon "$ENGINE_URL" retractordb
klon "$EXPERIMENT_URL" rdb-experiment

echo "== przelaczam na $TAG"
git -C retractordb checkout --detach "$TAG"
# Strona eksperymentu: K6c ma tag o innej nazwie niz strona silnika.
if git -C rdb-experiment rev-parse -q --verify "${TAG}^{commit}" >/dev/null; then
  git -C rdb-experiment checkout --detach "$TAG"
else
  echo "   uwaga: brak $TAG w rdb-experiment - patrz MANIFEST.md sekcja 2.2"
fi

echo
echo "== stan"
printf "retractordb    HEAD = %s\n" "$(git -C retractordb rev-parse HEAD)"
printf "rdb-experiment HEAD = %s\n" "$(git -C rdb-experiment rev-parse HEAD)"
echo
echo "Nastepny krok: RDB_ENGINE=$CEL/retractordb RDB_EXPERIMENT=$CEL/rdb-experiment \\"
echo "               <sciezka-do-rdb-artifact>/bin/verify_pins.sh"
