# Kielitarkistus 10.9.2026

Tarkistettu englanninkieliset lähdetekstit sekä suomi, saksa, ranska, espanja, italia ja Brasilian portugali. Arvio koskee nykyisiä iOS- ja Watch-merkkijonoja Clauden 10.9. tekemien korjausten jälkeen. Tämä on kielellinen ja käyttöyhteyteen perustuva arvio, ei äidinkielisten käyttäjätesti.

Käännökset ovat pääosin ymmärrettäviä. Kaikkia ei vielä kannata merkitä valmiiksi: jäljellä on yksi selvä saksan sijamuotovirhe, monikkomuotojen ongelma, useita merkitysongelmia ja paikoin kirjaimellista pelikieltä. Tyylisuositukset on eroteltu varsinaisista virheistä.

## Korjattavat virheet ja merkitykset

| Kieli / avain | Nykyinen | Ehdotus ja peruste |
|---|---|---|
| de / `Use one die when only tiles 1–6 remain open` | Nur ein Würfel verwenden, wenn nur die Felder 1–6 offen sind | **Nur einen Würfel verwenden, wenn nur noch die Felder 1–6 offen sind.** Verbi verwenden vaatii tässä akkusatiivin. |
| fi / `Show Dice Total` | Näytä silmäluku | **Näytä noppien summa**. Asetus näyttää summan, ei yhden nopan silmälukua. |
| Kaikki / `%d turns` | mm. 1 turns, 1 vuoroa, 1 Runden, 1 tours, 1 turnos, 1 turni | Toteuta yksikkö/monikko lokalisoidulla plural-resurssilla. Vaihtoehtoisesti käytä lukumäärästä riippumatonta rakennetta, esim. **Siirtoja: %d**, ja tarkista sen sopivuus jokaiseen käyttöpaikkaan. Tämä on käyttäjälle näkyvä kielioppivirhe riippumatta siitä, johtuuko se resurssirakenteesta. |
| fi/de/fr/es/it/pt-BR / `Shortest clear` | Nopein tyhjennys / Schnellste Leerung / Vidage le plus rapide / Vaciado más rápido / Svuotamento più rapido / Limpeza mais rápida | Arvo on **siirtojen lukumäärä**, ei aika (`StatsView.shortestClearTurns`). Käännösten pitää kertoa vähimmistä siirroista. |
| Kaikki / `Tiles: …` ja `Tiles …` | Laattoihin viittaava otsikko pisteluvun edessä | Käyttöpaikassa luku on avoimien laattojen **summa**, ei kappalemäärä. Aikapelissä esim. **Laattapisteet: …**, muussa pelissä **Jäljellä: …**. Muuta lähdeavaimet ja käännökset yhdessä. |

Ehdotukset `Shortest clear` -otsikoksi:

| en | fi | de | fr | es | it | pt-BR |
|---|---|---|---|---|---|---|
| Fewest moves to clear | Tyhjennys vähimmillä siirroilla | Wenigste Züge bis zum Sieg | Victoire en un minimum de coups | Victoria en menos turnos | Vittoria con meno mosse | Vitória com menos jogadas |

Tarkista pitkien otsikoiden mahtuminen etenkin Watchissa. Saksassa `%d Runden` kannattaa samalla vaihtaa siirtoihin viittaavaan sanaan **Züge**, jos laskuri tarkoittaa heitto-/sulkusiirtoja eikä kokonaisia kierroksia.

## Luontevuuden parantaminen

Nämä eivät kaikki ole kielioppivirheitä. Nykyinen teksti yleensä ymmärretään, mutta ehdotus kuvaa peliä paremmin.

- **en:** `Select tiles matching the dice` → **Select tiles that add up to the dice total.** Myös muiden kielten ohjeessa kannattaa mainita summa. `Selected …` → **Selected total: …**, jos tilaa on.
- **fi:** ”vain pienet laatat jäljellä” voi tarkoittaa laatan kokoa. **Nyt yksi noppa — jäljellä vain numeroita 1–6.** ”Noppalauta -pelissä” on tarkistuksen aikana jo korjattu muotoon **Noppalauta-pelissä**. Jos tuotteen nimeksi yhtenäistetään Box of Dice, oikea yhdyssanarakenne on **Box of Dice -pelissä**.
- **de:** `Perfekte Leerung!` on kirjaimellinen. **Perfekt! Alle Felder geschlossen!** sopii peliin paremmin. `Große Box Speed` on sekakielinen nimi; esim. **Große Box auf Zeit**. Keskiarvo-ohje: **Die Durchschnittswerte basieren auf den seit diesem Update gespielten Partien.**
- **fr:** `Plateau parfaitement vidé !` -tyyppisen tyhjennysilmauksen vaihtoehto: **Parfait ! Toutes les cases sont fermées !** Keskiarvo-ohje: **Les moyennes sont calculées à partir des parties jouées depuis cette mise à jour.**
- **es:** `¡Vaciado perfecto!` → **¡Perfecto! ¡Todas las casillas cerradas!** Keskiarvo-ohje: **Los promedios se calculan con las partidas jugadas desde esta actualización.**
- **it:** `Svuotamento perfetto!` → **Perfetto! Tutte le caselle sono chiuse!** Keskiarvo-ohje: **Le medie si basano sulle partite giocate dopo questo aggiornamento.**
- **pt-BR:** `Limpeza perfeita!` kuulostaa puhdistamiselta. **Perfeito! Todas as casas fechadas!** Keskiarvo-ohje: **As médias são calculadas com base nas partidas jogadas após esta atualização.**

Yhden nopan ohjeen ”pienet/matalat laatat” kannattaa kaikissa kielissä ilmaista numeroina. Pikapelin täsmälliset vaihtoehdot:

| Kieli | Teksti |
|---|---|
| de | Jetzt ein Würfel — nur noch Zahlen von 1 bis 6 offen. |
| fr | Un seul dé : les cases 7 à 9 sont fermées. |
| es | Un solo dado: las casillas del 7 al 9 están cerradas. |
| it | Un solo dado: le caselle dal 7 al 9 sono chiuse. |
| pt-BR | Um só dado: as casas de 7 a 9 estão fechadas. |

**Rajaus:** 7–9-muotoilu käy vain Pikapelin omaan avaimeen. Yhteisessä, myös 12/18 laatan pelien tekstissä on puhuttava jäljellä olevista numeroista 1–6.

## Käännös löytyy tiedostosta mutta ei käyttöliittymän kutsusta

`BoxOfDice/TileView.swift:49` käyttää VoiceOver-nimenä `Tile \(number)` / `Closed tile \(number)`. Resurssien avaimet ovat muotoa `Tile %lld, open` / `Tile %lld, closed` (myös %d-versioita). Kutsut eivät vastaa käännettyjä avaimia, joten iOS:n normaalin pelin ja opastuksen laattojen lukutekstit jäävät englanniksi. Käytä eksplisiittisesti oikeita `L10n.format`-avaimia ja tarkista avoin/suljettu/valittu laatta VoiceOverilla. Pelkkä kaikkien kielten avainjoukkojen vertailu ei havaitse tätä.

## Jo korjatut kohdat

Uusimmassa koodissa ovat jo mukana Clauden korjaukset muun muassa pelaaja-artikkeleihin, espanjan ja portugalin kahden nopan verbimuotoihin, viimeisen siirron listateksteihin sekä saksan Spiel­feld/Feld-erotteluun. Italian moninpeliohje kertoo nyt kokonaisesta pelistä. Kauppatekstien aiemmat saksan ajattomuus-/lautaongelmat ja italian `senza tempo` on myös korjattu uusimpaan dokumenttiin. Näitä ei pidä korjata uudelleen vanhan version perusteella.

## Tekninen tarkistus

- Luettu 12 Localizable.strings-tiedostoa: kuusi käännöskieltä × kaksi alustaa; englanti käyttää lähdeavaimia.
- iOS: 183 avainta/kieli, Watch: 161 avainta/kieli. Alustojen avainjoukot saavat erota, yhteisten avainten käännökset täsmäävät.
- Kaikkien 12 tiedoston `plutil -lint`, duplikaattiavaimet ja formaattiparametrien tyypit/järjestys: ei virheitä.
- Projektin 62 XCTest-testiä läpi, mukana kolme lokalisaatioresurssitestiä.
- Nämä tarkistukset eivät todista kielioppia, puuttuvien käyttöliittymäavainten kattavuutta tai tekstien mahtumista näytölle.

## Ohje Claudelle

Korjaa ensin taulukon varsinaiset virheet ja VoiceOver-avaimet molempiin alustoihin. Toteuta monikot oikeissa kutsukohdissa ja tarkista arvot 1, 2 ja 5. Käytä tyylisuosituksia harkiten ja yhdenmukaista termit koko kielessä. Älä muuta pelisääntöjä tai formaattiparametrien tyyppejä. Tarkista pitkät tekstit iPhonessa, iPadissa ja Watchissa; kirjaa erikseen ajamatta jäävät tarkistukset. Päivitä KORJAUSSEURANTA.md, mutta älä merkitse tekoälyarviota äidinkielisen ihmisen tarkistukseksi.

Viimeinen tarkistus: Claude muutti suomen sanajärjestystä ja Valinta-otsikkoa sekä korjasi Noppalauta-pelissä-yhdyssanan tämän katselmuksen aikana. Muutokset luettiin erikseen; yllä luetellut summan nimitys ja nopeus-/siirtomääräero ovat edelleen avoinna.
