]633;E;{   echo "# hf05 - logtool.sh"\x3b   echo ""\x3b   echo "## --help kimenete"\x3b   echo '```'\x3b   ./logtool.sh --help\x3b   echo '```'\x3b   echo ""\x3b   echo "## Peldafuttatas 1: ./logtool.sh -f access.log -t 3"\x3b   echo '```'\x3b   ./logtool.sh -f access.log -t 3\x3b   echo '```'\x3b   echo ""\x3b   echo "## Peldafuttatas 2: ./logtool.sh -f access.log -s 404 -q"\x3b   echo '```'\x3b   ./logtool.sh -f access.log -s 404 -q\x3b   echo '```'\x3b } > README.md;1210a885-33ec-4851-b4c5-f657e43d9fcb]633;C# hf05 - logtool.sh

## --help kimenete
```
logtool.sh - webszerver access-log elemzo

Hasznalat:
  logtool.sh -f LOGFAJL [-t N] [-s KOD] [-o FAJL] [-q]
  logtool.sh -h

Kapcsolok:
  -h, --help          kiirja ezt a sugot, majd kilep 0-val
  -f, --file FAJL     a feldolgozando log (KOTELEZO)
  -t, --top N         hany elem legyen a toplistakban (alapertelmezes: 10)
  -s, --status KOD    csak az adott statuszkodu sorokat nezi (pl. 404)
  -o, --output FAJL   a riportot fajlba irja a kepernyo helyett
  -q, --quiet         csak a vegso osszefoglalo sort irja ki

Kimenet: top IP-k, statuszkod-megoszlas, egy mondatos osszefoglalo.

Kilepesi kodok:
  0  rendben    2  hibas hasznalat    3  a logfajl nem olvashato
  4  a kimeneti fajlba nem lehet irni

Pelda:
  logtool.sh -f access.log -s 404 -t 3
```

## Peldafuttatas 1: ./logtool.sh -f access.log -t 3
```
=== Top 3 IP ===
758    193.224.41.77
1      10.0.187.179
1      10.1.165.177

=== Statuszkod-megoszlas ===
200    2015    50.4%
301    387      9.7%
403    402     10.1%
404    372      9.3%
500    398      9.9%
502    426     10.7%

=== Osszefoglalo ===
Osszesen 4000 keres, 3243 egyedi IP. A legaktivabb IP a 193.224.41.77, ami az osszes keres 18.9%-at adta.
```

## Peldafuttatas 2: ./logtool.sh -f access.log -s 404 -q
```
[404-es keresek] Osszesen 372 keres, 304 egyedi IP. A legaktivabb IP a 193.224.41.77, ami az osszes keres 18.5%-at adta.
```
