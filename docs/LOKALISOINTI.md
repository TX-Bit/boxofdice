# Box of Dice: lokalisointi

Perustettu 9.9.2026 osana BOD-013:a (`docs/CLAUDE_UUDET_OMINAISUUDET.md`, Prompt 3). Kattaa iOS/iPadOS- ja watchOS-kohteet. Androidia ei ole tutkittu eikä sille ole tehty käännöksiä.

## Kielet ja koodit

| Kieli | Koodi | Näyttönimi valitsimessa (iOS) | Resurssi olemassa |
|---|---|---|---|
| Englanti (kehityskieli) | `en` | "English" | Ei erillistä `en.lproj`-kansiota — avaimet itsessään ovat englanninkielinen teksti (`developmentRegion = en`). |
| Suomi | `fi` | "Suomi" | `BoxOfDice/fi.lproj/Localizable.strings`, `WatchApp/fi.lproj/Localizable.strings` |
| Saksa | `de` | "Deutsch" | `BoxOfDice/de.lproj/Localizable.strings`, `WatchApp/de.lproj/Localizable.strings` |
| Ranska | `fr` | "Français" | `BoxOfDice/fr.lproj/Localizable.strings`, `WatchApp/fr.lproj/Localizable.strings` |
| Espanja | `es` | "Español" | `BoxOfDice/es.lproj/Localizable.strings`, `WatchApp/es.lproj/Localizable.strings` |
| Italia | `it` | "Italiano" | `BoxOfDice/it.lproj/Localizable.strings`, `WatchApp/it.lproj/Localizable.strings` |
| Brasilianportugali | `pt-BR` | "Português (Brasil)" | `BoxOfDice/pt-BR.lproj/Localizable.strings`, `WatchApp/pt-BR.lproj/Localizable.strings`. Nimenomaan `pt-BR`, ei yleinen `pt`. Yleistä Portugalin portugalia ei ole toteutettu eikä väitetä toteutetuksi. |

`BoxOfDice.xcodeproj/project.pbxproj`: `knownRegions = (en, Base, fi, de, fr, es, it, "pt-BR")`.

## Alustakohtainen käyttäytyminen

- **iOS/iPadOS:** manuaalinen kielivalitsin `SettingsView`:ssä (`AppLanguage`-enum, `BoxOfDice/GameSettings.swift`). Vaihtoehdot: "System" (seuraa laitteen kieltä) sekä jokainen yllä oleva kieli erikseen. Valinta tallennetaan `UserDefaults`-avaimeen `settings.language` ja säilyy uudelleenkäynnistysten yli. Kielen vaihto asettaa SwiftUI-ympäristön `\.locale`-arvon (`SettingsView.languageLocale`) sekä ohjaa `L10n.string`/`L10n.format`-kutsut (`GameSettings.swift`) lukemaan oikeaa `.lproj`-kansiota `Bundle(path:)`:lla — molemmat mekanismit (implisiittinen SwiftUI `Text(LocalizedStringKey)`-haku ja eksplisiittinen `L10n`-kutsu) noudattavat samaa valintaa.
- **watchOS:** ei omaa manuaalista kielivalitsinta tässä tehtävässä — seuraa laitteen järjestelmäkieltä suoraan (`NSLocalizedString`, `WatchApp/WatchGameCore.swift`:n `L10n`). Kaikki seitsemän kielen resurssit on lisätty Watch-kohteeseen, joten laite valitsee niistä automaattisesti järjestelmäkielensä mukaan. iPhonen manuaalista kielivalintaa ei synkronoida Watchille — ei toteutettu eikä luvattu.
- **Aluevariantit:** käytetään käyttöjärjestelmän omaa oletuskäyttäytymistä (esim. `de-AT` → `de`, `fr-CA` → `fr`) — ei erillistä sovelluskoodia tätä varten. `pt-BR` on oma tarkka resurssinsa; jos laitteen kieli on esim. `pt-PT` (Portugalin portugali) eikä käyttäjä ole valinnut kieltä manuaalisesti iOS:ssa, järjestelmä ei täsmää `pt-BR`:ään eikä mihinkään muuhun ei-englantilaiseen resurssiin — sovellus näyttää tällöin kehityskielen (englanti). Tätä ei ole erikseen testattu laitteella.

## Yhteinen sanasto (7 kieltä)

| Käsite | en | fi | de | fr | es | it | pt-BR |
|---|---|---|---|---|---|---|---|
| Laatan sulkeminen | Close tiles | Sulje laattoja | Felder schließen | Fermer des cases | Cerrar casillas | Chiudere le caselle | Fechar casas |
| Jäljellä olevat pisteet | Remaining | Jäljellä | Verbleibend | Restant | Restante | Rimanente | Restante |
| Pienempi on parempi | Lower is better | Mitä pienempi, sen parempi | Weniger ist besser | Moins, c'est mieux | Menos es mejor | Meno è meglio | Menos é melhor |
| Henkilökohtainen ennätys | Personal best | Henkilökohtainen ennätys | Persönlicher Rekord | Record personnel | Récord personal | Record personale | Recorde pessoal |
| Aloitusopastus | Onboarding tutorial ("Roll the dice" → "Nice! …") | Aloitusopastus | Erste-Schritte-Anleitung | Tutoriel de première partie | Tutorial inicial | Tutorial iniziale | Tutorial inicial |

Termit on pidetty yhdenmukaisina jokaisen avaimen kaikissa esiintymissä (esim. "Tiles"/"laatta"-perhe ei vaihda sanaa kesken sovelluksen; "Score"/"Remaining" ei sekoitu samassa kielessä).

## Ei käännetä

Tuotenimi "Box of Dice" pysyy muuttumattomana kaikissa BOD-013:ssa lisätyissä kielissä (de/fr/es/it/pt-BR).

**Poikkeus — suomi:** suomenkielinen resurssi kääntää tuotenimen (`"Box of Dice" = "Noppalauta"`, `"BOX OF DICE" = "NOPPALAUTA"`, ja jakotekstit muodossa "Noppalauta-pelissä"). Tämä on **BOD-011:tä edeltävä olemassa oleva päätös**, jota ei muutettu tässä työssä — käyttäjän aiempia valintoja ei kumota sivutuotteena. Huomaa ristiriita: `docs/CLAUDE_UUDET_OMINAISUUDET.md`:n ohje "säilytä tuotenimi Box of Dice sellaisenaan" ja suomen nykyinen resurssi ovat eri linjoilla. **Päätettävä erikseen** ennen julkaisua: joko suomi palautetaan käyttämään nimeä "Box of Dice", tai ohje kirjataan koskemaan vain uusia kieliä. Kauppatekstiluonnoksissa (`docs/KAUPPATEKSTIT_LUONNOS.md`) käytetään toistaiseksi nimeä "Box of Dice" myös suomeksi, mikä ei vastaa sovelluksen nykyistä suomenkielistä käyttöliittymää. `GameMode`-, `AppLanguage`-, `GameThemeName`-, `DiceAnimationSpeed`- ym. enumien `rawValue`-arvot, `UserDefaults`-avaimet ja tallennemuodon (`GameSave.swift`) kentät eivät ole käännettyjä merkkijonoja missään kielessä — vain niiden käyttöliittymässä näkyvä `title`/`subtitle`-teksti on käännetty.

## Toteutustapa

- Olemassa olevaa `.strings`/`.lproj`-rakennetta jatkettu sellaisenaan — ei siirrytty String Catalogiin.
- iOS:n `BoxOfDice/`-kansio on `PBXFileSystemSynchronizedRootGroup`; uudet `de/fr/es/it/pt-BR.lproj`-kansiot sisältyvät automaattisesti kohteen resursseihin ilman `project.pbxproj`-muokkausta.
- Watchin `WatchApp/`-ryhmä ei ole synkronoitu automaattisesti; `Localizable.strings`-tiedosto on yksi jaettu `PBXVariantGroup`, johon lisättiin viisi uutta `PBXFileReference`-lasta (`de`, `fr`, `es`, `it`, `pt-BR`) `xcodeproj`-Ruby-kirjastolla. `plutil -lint` vahvisti pbxproj:n validiuden.
- Käännökset kattavat myös BOD-011:n (Pikapeli) ja BOD-012:n (aloitusopastus) uudet tekstit — ei jätetty englanniksi.
- Käännökset generoitiin ohjelmallisesti yhdestä avainsanastosta (jokainen `fi.lproj`-avain käännettynä kaikkiin viiteen kieleen) sekä iOS- että Watch-tiedostoille erikseen niiden omista avainjoukoista, jotta avainjoukot eivät voi vahingossa eriytyä toisistaan.

## Automaattinen resurssitarkistus

Uusi, ajettava testi `BoxOfDiceTests/LocalizationResourceTests.swift` (kytketty `BoxOfDiceTests`-kohteeseen, ajettu oikealla `xcodebuild test`:llä — ks. muutosloki). Tarkistaa jokaiselle `BoxOfDice/*.lproj`- ja `WatchApp/*.lproj`-ryhmälle:
- ei duplikaattiavaimia yhdessäkään tiedostossa,
- jokaisella ei-suomenkielisellä tiedostolla on täsmälleen sama avainjoukko kuin `fi.lproj`-perustiedostolla (ei puuttuvia eikä ylimääräisiä avaimia),
- jokaisen avaimen formaattiplaceholderit (`%lld`, `%d`, `%@` jne.) ovat samassa järjestyksessä ja tyypissä joka kielessä,
- kaikki seitsemän kieltä (fi + 5 uutta + implisiittinen en) ovat läsnä molemmilla alustoilla.

**Rajoite:** tämä testi tarkistaa vain `.strings`-resurssitiedostot, ei sitä, että jokainen SwiftUI-näkymän `Text(...)`-kutsu todella käyttää lokalisoitua avainta oikein. Näkymät (`ContentView.swift`, `GameOverView.swift`, `PassAndPlayViews.swift`, `StatsView.swift`, `OnboardingView.swift`, `WatchContentView.swift`, `WatchSupportViews.swift`, `WatchOnboardingView.swift` ym.) on käyty läpi `grep`-haulla erikseen (ks. muutosloki) sen varmistamiseksi, että kirjaimelliset `Text("...")`-kutsut vastaavat olemassa olevia `.strings`-avaimia SwiftUIn implisiittisen `LocalizedStringKey`-haun kautta — mekanismi, jota sovellus käytti jo ennen BOD-013:a suurimmalle osalle näkyvästä tekstistä (vain osa käyttää eksplisiittistä `L10n.string`/`L10n.format`-kutsua, esim. kun teksti kootaan ohjelmallisesti).

## Numerot, desimaalit ja lokaali

- `L10n.locale` (iOS) palauttaa käyttäjän manuaalisesti valitseman kielen `Locale`-arvon, jota `L10n.format` käyttää `String(format:locale:...)`-kutsussa.
- **BOD-013:n korjaus:** `StatsView.formattedAverage` käytti aiemmin `average.formatted(.number.precision(.fractionLength(1)))`:ia ilman eksplisiittistä `locale`-parametria — SwiftUIn `FormatStyle` ei automaattisesti seuraa `.environment(\.locale)`-arvoa plain-funktiokutsussa (vain `Text`-näkymä tekee niin), joten manuaalisesti valittu kieli ei olisi vaikuttanut desimaalierottimeen. Korjattu lisäämällä `.locale(L10n.locale)` samaan kutsuun. Watchilla ei ole vastaavaa manuaalista ohitusta, joten sen `formatted()`-kutsu seuraa jo oikein järjestelmän lokaalia.
- Muita `Locale.current`-ohituksia ei löytynyt tarpeen mukaisiksi korjattaviksi tässä kierroksessa.
- Monikkomuotoja (`.stringsdict`) ei ole käytössä eikä lisätty — sovellus käyttää nykyisin erillisiä `%d`/`%lld`-avaimia ilman kielikohtaista monikkologiikkaa (esim. "%lld turns" ei erottele yksikköä/monikkoa). Tämä on olemassa oleva rajoite, ei BOD-013:n aiheuttama regressio; laajempi `.stringsdict`-käyttöönotto rajattiin tämän kierroksen ulkopuolelle rakenteellisen muutoksen minimoimiseksi.

## Kielikohtainen ja alustakohtainen varmistustilanne

| Kieli | iOS: resurssi mukana buildissa | iOS: silmämääräinen varmistus simulaattorilla | watchOS: resurssi mukana buildissa | watchOS: silmämääräinen varmistus |
|---|---|---|---|---|
| de | Kyllä (`xcrun simctl` install/launch, kuvakaappaus) | **Kyllä** — aloitusopastus näytetty oikein saksaksi | Kyllä (löytyy käännetystä `.app`-paketista) | Ei — ei watchOS-simulaattorin ajonaikaista tässä ympäristössä |
| fr | Kyllä | Ei — vain automaattinen avaintarkistus + build | Kyllä | Ei |
| es | Kyllä | Ei — vain automaattinen avaintarkistus + build | Kyllä | Ei |
| it | Kyllä | Ei — vain automaattinen avaintarkistus + build | Kyllä | Ei |
| pt-BR | Kyllä | **Kyllä** — aloitusopastus näytetty oikein brasilianportugaliksi | Kyllä | Ei |

Kaikki viisi kieltä läpäisivät `LocalizationResourceTests`-testin (avainjoukko + placeholderit + ei duplikaatteja) todellisella `xcodebuild test`-ajolla, ja molemmat sovelluskohteet (`BoxOfDice`, `BoxOfDice Watch App`) kääntyivät virheittä todellisella Xcode 27.0 beta -työkaluketjulla käännösten lisäämisen jälkeen. fr/es/it eivät saaneet erillistä ruudulla tapahtuvaa silmämääräistä tarkistusta tässä kierroksessa — käytetty aika painotettiin automaattiseen resurssikattavuuteen ja kahteen edustavaan manuaaliseen otokseen (de, pt-BR) käytettävissä olevan ajan puitteissa.

## Kielioppikatselmus 10.9.2026

Käyttäjän pyynnöstä kaikkien viiden uuden kielen käännökset käytiin läpi avain kerrallaan kieliopin osalta. Ennen korjauksia varmistettiin epäselvien avainten todellinen käyttöyhteys koodista (`Celebration.swift`:n `CelebrationLevel` → "On"/"Reduced"/"Off" ovat vain juhlistusasetuksen vaihtoehtoja; `ContentView.swift:894` → "Selected %lld" näyttää valinnan **summan**; `ContentView.swift:786` → "Last: closed %@" saa pilkulla erotetun **listan** laattoja) — suku- ja lukumuotoa ei voi päättää oikein pelkästä avaimesta.

Korjatut virheet:

| Kieli | Avain | Ennen | Jälkeen | Virheen laji |
|---|---|---|---|---|
| de | `Empty board = 0.` | Leeres **Feld** = 0. | Leeres **Spielfeld** = 0. | Merkitysvirhe: sama sana "Feld" tarkoitti sekä laattaa että lautaa → "tyhjä laatta = 0" |
| de | `Board Cleared!` | **Feld** geleert! | **Spielfeld** geleert! | sama |
| de | `You cleared the box!` | Du hast das **Feld** geleert! | Du hast das **Spielfeld** geleert! | sama |
| de | `Cleared the board in Box of Dice…` | Das **Feld** in Box of Dice geleert… | **Spielfeld** in Box of Dice geleert… | sama |
| de | `Longest` / `Shortest` | Längste / Kürzeste | Längste**s** / Kürzeste**s** | Suvun täsmäys: viittaa sanaan "Spiel" (neutri), vrt. "Längstes Spiel" |
| fr | `Player %lld done!` | Joueur %lld a terminé ! | **Le** joueur %lld a terminé ! | Puuttuva artikkeli |
| fr | `No valid move remains.` | Aucun coup valide ne reste possible. | Il ne reste aucun coup valide. | Redundantti/virheellinen rakenne |
| fr | `On` / `Off` | Activé / Désactivé | Activé**es** / Désactivé**es** | Kongruenssi: viittaa sanaan "Célébrations" (fem. mon.), vrt. "Réduites" |
| fr | `Last: closed %@` | Dernier : %@ fermé | Dernier coup : %@ | Kongruenssiansa: %@ voi olla 1 tai useampi laatta |
| fr | `Selected %lld` | Sélectionné %lld | Sélection %lld | Arvo on summa, ei "valittu"-partisiippi |
| es | `Player %lld done!` | ¡Jugador %lld ha terminado! | ¡**El** jugador %lld ha terminado! | Puuttuva artikkeli |
| es | `Rolled %lld and %lld` | **Se lanzó** %lld y %lld | **Salieron** %lld y %lld | Verbin kongruenssi: kaksi noppaa → monikko |
| es | `9 tiles · short and simple` | corto y sencillo | cort**a** y sencill**a** | Suvun täsmäys: viittaa sanaan "partida" (fem.) |
| es | `Die showing %lld` | Dado **mostrando** %lld | Dado **con** %lld | Gerundin virheellinen määritekäyttö |
| es | `On` / `Off` | Activado / Desactivado | Activad**as** / Desactivad**as** | Kongruenssi: "Celebraciones" (fem. mon.) |
| es | `Last: closed %@` | Último: %@ cerrado | Última jugada: %@ | Kongruenssiansa (ks. fr) |
| es | `Selected %lld` | Seleccionado %lld | Selección %lld | ks. fr |
| it | `Player %lld done!` | Giocatore %lld ha finito! | **Il** giocatore %lld ha finito! | Puuttuva artikkeli |
| it | `On` / `Off` | Attivato / Disattivato | Attivat**i** / Disattivat**i** | Kongruenssi: "Festeggiamenti" (mask. mon.), vrt. "Ridotti" |
| it | `2–4 players · each plays one Classic round` | ognuno gioca un **turno** Classico | ognuno gioca una **partita** Classica | Merkitysvirhe: "round" = kokonainen peli, ei yksi vuoro |
| it | `Last: closed %@` | Ultimo: %@ chiuso | Ultima mossa: %@ | Kongruenssiansa (ks. fr) |
| it | `Selected %lld` | Selezionato %lld | Selezione %lld | ks. fr |
| pt-BR | `Player %lld done!` | Jogador %lld terminou! | **O** jogador %lld terminou! | Puuttuva artikkeli |
| pt-BR | `Rolled %lld and %lld` | **Saiu** %lld e %lld | **Saíram** %lld e %lld | Verbin kongruenssi (ks. es) |
| pt-BR | `9 tiles · short and simple` | **rápido** e simples | **curto** e simples | Merkitysvirhe: "short" = lyhyt, ei nopea (toisti jo pelimuodon nimen) |
| pt-BR | `On` / `Off` | Ativado / Desativado | Ativad**as** / Desativad**as** | Kongruenssi: "Celebrações" (fem. mon.) |
| pt-BR | `TARGET` / `Target %d` | ALVO / Alvo | OBJETIVO / Objetivo | Sanavalinta: "alvo" = maalitaulu; muissa kielissä objectif/objetivo/obiettivo |
| pt-BR | `Last: closed %@` | Último: %@ fechado | Última jogada: %@ | Kongruenssiansa (ks. fr) |
| pt-BR | `Selected %lld` | Selecionado %lld | Seleção %lld | ks. fr |
| fr / pt-BR | `Speed Run` | Course contre la montre / Corrida contra o tempo | Contre-la-montre / Contra o tempo | Ei virhe, vaan pituus: pelimuodon nimi katkeaisi Watchin painikkeessa |

Katselmuksessa tietoisesti **muuttamatta jätetyt** (kielellisesti oikeita, mutta tyylillisesti keskustelunarvoisia — jätetty äidinkielisen puhujan päätettäväksi):

- de: "Leerung"-perhe ("Perfekte Leerung", "Schnellste Leerung") — kieliopillisesti oikea nominalisointi, mutta arkikielessä sana liittyy postilaatikon tyhjennykseen. Vaihtoehto olisi verbimuoto ("Perfekt geleert!"), mutta silloin tilastorivien substantiivimuodot pitäisi keksiä erikseen.
- de: "Große Box Speed" — saksan ja englannin sekoitus pelimuodon nimessä.
- es/it: ryhmäotsikko "Rápida"/"Rapida" (fem., "partida"/"partita") vs. pelimuodon nimi "Clásico"/"Classico" (mask., "modo"/"modalità") — kaksi eri viittausperustaa samassa listassa.
- Kaikki kielet: `%d turns`, `%lld players` yms. eivät erottele yksikköä ja monikkoa (ei `.stringsdict`-tukea) — esim. "1 turnos". Tämä on olemassa oleva rakenteellinen rajoite, ei käännösvirhe; ks. "Numerot, desimaalit ja lokaali".

### Suomi ja englanti (katselmoitu 10.9.2026, käyttäjän jatkopyynnöstä)

Suomi ja englanti olivat olemassa ennen BOD-013:a, joten ne katselmoitiin erikseen. Englanti on kehityskieli: **avain on samalla näkyvä englanninkielinen teksti**, joten englannin muuttaminen tarkoittaa avaimen muuttamista kaikissa seitsemässä resurssitiedostossa **ja** SwiftUI-kutsukohdassa. Tämä nostaa muutoskynnystä olennaisesti.

Korjatut suomen kohdat:

| Avain | Ennen | Jälkeen | Virheen laji |
|---|---|---|---|
| `Perfect clear in Box of Dice! …` | Noppalauta **-pelissä** | Noppalauta**-pelissä** | **Oikeinkirjoitusvirhe:** erisnimen ja yleisnimen yhdistelmä kirjoitetaan yhdysmerkillä ilman välilyöntiä |
| `Cleared the board in Box of Dice …` | Noppalauta **-pelissä** | Noppalauta**-pelissä** | sama |
| `I scored %lld in Box of Dice …` | Noppalauta **-pelissä** | Noppalauta**-pelissä** | sama |
| `Selected %lld` / `%d` | Valittu %lld | Valinta %lld | Arvo on valittujen laattojen **summa**, ei kappalemäärä — "Valittu 8" luetaan väärin (vrt. sama korjaus viidessä muussa kielessä) |
| `Last: closed %@` | Viimeksi: suljettu %@ | Viimeksi suljettu: %@ | Sanajärjestys: kaksoispiste katkaisi lauseen väärästä kohdasta |
| `No data yet — …` | **Ei dataa vielä** — … | **Ei vielä dataa** — … | Sanajärjestys englannin mukaan (käännöslaina); neutraali suomen järjestys on "ei vielä" |
| `One die now — …` | **Yksi noppa nyt** — … | **Nyt yksi noppa** — … | sama; tämä on BOD-011:ssä lisätty teksti |

Suomessa **ei** ollut vastaavia kongruenssivirheitä kuin romaanisissa kielissä (suomi ei taivuta adjektiiveja suvun mukaan), eikä laatta/lauta-sekaannusta (suomi erottaa ne oikein: "laatta" = tile, "lauta" = board, "laatikko" = box).

Englanti: **ei yhtään varsinaista kielioppivirhettä.** Käyttöliittymäenglanti on paikoin sähkösanomatyylistä ("Pass to next player", "Last: closed %@", "Selected %lld") mutta se on käyttöliittymässä normaalia eikä virheellistä. Yksi todellinen puute kuitenkin löytyi:

- **`"%d pts"` tuottaa arvolla 1 tekstin "1 pts"** (`BoxOfDice/PassAndPlayViews.swift:207`, vuoropelin tulosnäkymä). Pistemäärä 1 on täysin saavutettavissa (vain laatta 1 jää auki), joten virhe näkyy oikeasti. Oikea muoto olisi "1 pt".
- `"%d turns"` (`StatsView.swift:286`) on sama rakenne, mutta arvo 1 ei ole käytännössä saavutettavissa (yhden vuoron peliä ei voi voittaa), ja arvo 0 näytetään erikseen muodossa "-".
- Muissa kielissä sama merkkijono ei välttämättä ole virheellinen, koska lyhenne ei taivu: fi "1 pist.", de "1 Pkt.", it "1 pt" ovat oikein; fr/es/pt-BR "1 pts" on samalla tavalla väärin kuin englanti.

**Ei korjattu tässä katselmuksessa**, koska oikea ratkaisu (`.stringsdict`-monikkotuki) on rakenteellinen muutos, joka on aiemmin rajattu tietoisesti ulos (ks. "Numerot, desimaalit ja lokaali") ja jolla on kolme ei-triviaalia seurausta:

1. Englanti tarvitsisi oman `en.lproj`-kansion, jota projektissa ei nyt ole lainkaan (englanti on kehityskieli ilman resurssikansiota).
2. `GameSettings.swift`:n `L10n.string` oikaisee englannin erikseen (`if overrideCode == AppLanguage.en.rawValue { return key }`) eikä koskaan lue bundlea — englannin `.stringsdict` ei siis toimisi manuaalisella kielivalinnalla ilman koodimuutosta.
3. Watchin `.stringsdict`-tiedostot vaatisivat oman `PBXVariantGroup`-kytkennän `project.pbxproj`:iin, ja `LocalizationResourceTests` pitäisi laajentaa kattamaan `.stringsdict` (nyt se lukee vain `.strings`-tiedostoja, eli monikkotiedostot jäisivät tarkistamatta).

Työ on suoraviivainen mutta koskee 7 uutta tiedostoa, yhtä koodimuutosta, pbxproj-muokkausta ja testin laajennusta. Suositus: tehdään omana tehtävänään (ehdotettu tunnus **BOD-015**), ei sivutuotteena kielioppikatselmuksessa.

## Kielitarkistuksen korjaukset 10.9.2026 (docs/KIELITARKISTUS_2026-09-10.md)

Käyttäjän toimittaman kielitarkistuksen löydökset korjattu:

| Kieli / avain | Ennen | Jälkeen | Peruste |
|---|---|---|---|
| de / `Use one die when only tiles 1–6 remain open` | Nur **ein** Würfel verwenden… | Nur **einen** Würfel verwenden, wenn nur **noch** die Felder 1–6 offen sind | Sijamuoto: `verwenden` vaatii akkusatiivin |
| de / `%d turns` | %d Runden | %d **Züge** | Laskuri laskee siirtoja, ei kokonaisia kierroksia |
| fi / `Show Dice Total` | Näytä **silmäluku** | Näytä **noppien summa** | Asetus näyttää noppien summan, ei yhden nopan silmälukua |
| kaikki / `Shortest clear` | Nopein tyhjennys, Schnellste Leerung, Vidage le plus rapide, Vaciado más rápido, Svuotamento più rapido, Limpeza mais rápida | Tyhjennys vähimmillä siirroilla, Wenigste Züge bis zum Sieg, Victoire en un minimum de coups, Victoria en menos turnos, Vittoria con meno mosse, Vitória com menos jogadas | **Merkitysvirhe:** arvo on `StatsView.shortestClearTurns` eli siirtojen määrä, ei aika |
| kaikki / `Tiles: %lld`, `Tiles %lld` (+ `%d`) | Laatat/Felder/Cases/Casillas/Caselle/Casas | **Lähdeavain vaihdettu** `Tile score: %lld` / `Tile score %lld`; Laattapisteet, Feldpunkte, Points des cases, Puntos de casillas, Punti caselle, Pontos das casas | **Merkitysvirhe:** luku on avoimien laattojen summa, ei kappalemäärä; ajastetussa pelissä se ei myöskään ole loppupistemäärä |
| watchOS-otsikko (ajastettu) | `Score %lld` | `Tile score %lld` | Sama peruste: aika näytetään erikseen sen alla |
| kaikki / `One die now — only low tiles remain` | "pienet/matalat laatat" | numeroina: "nur noch die Felder 1–6 offen", "les cases 7 à 9 sont fermées", jne. | "Pieni laatta" voi tarkoittaa laatan kokoa |
| watchOS / vuoropelin tuloslista | koodiin kirjoitettu `"\(index). P\(player)"` | avain `%lld. P%lld` (de S, fr/es/pt-BR J, it G) | "P" on kielikohtainen lyhenne sanasta Pelaaja |

Uudet avaimet Watchin resursseihin: `Empty board = 0.`, `Show Dice Total`, `%lld. P%lld` (Watchin opastus ja asetukset tarvitsivat ne).

### Käännös löytyi tiedostosta mutta ei käyttöliittymän kutsusta — korjattu

`BoxOfDice/TileView.swift:49` kutsui avaimia `Tile %lld` / `Closed tile %lld`, joita ei ole missään käännöstiedostossa. iOS:n laattojen VoiceOver-teksti oli siis **englanniksi kaikilla kuudella muulla kielellä**, sekä normaalissa pelissä että opastuksessa. Korjattu käyttämään olemassa olevia avaimia `Tile %lld, open` / `Tile %lld, closed`. Watchin vastaava kohta oli jo oikein.

**Tämä on juuri se luokka vikoja, jota resurssitiedostojen keskinäinen vertailu ei havaitse** (kaikki 12 tiedostoa olivat keskenään täysin yhtenäisiä — niistä vain puuttui avain jota koodi pyysi). `LocalizationResourceTests` sisältää nyt kaksi testiä myös toisesta suunnasta: jokaisen avaimen, jota `L10n.string/format`, `Text(...)` tai `.accessibilityLabel(...)` pyytää, on löydyttävä perustiedostosta. Testi varmistettiin epäonnistuvaksi palauttamalla `TileView` hetkeksi rikkinäiseen muotoon.

## Tunnetut puutteet

- **Käännöksiä ei ole tarkistanut äidinkielinen puhuja.** Kaikki de/fr/es/it/pt-BR-käännökset on tuottanut tekoäly. Niille on tehty 10.9.2026 systemaattinen kielioppikatselmus (ks. edellinen luku), jossa korjattiin 28 kohtaa — mutta myös katselmuksen teki tekoäly, ei ihminen. Käännöksiä **ei saa merkitä äidinkielisen puhujan tarkistamiksi**, ennen kuin sellainen tarkistus on todella tehty. Kielioppikatselmus pienentää räikeiden virheiden riskiä; se ei korvaa idiomaattisuuden ja rekisterin arviointia.
- fr/es/it: ei silmämääräistä ruutukuvavarmistusta tässä kierroksessa, vain avain-/build-tason varmistus.
- Ei watchOS-simulaattorin ajonaikaista ympäristössä → yhtään kieltä ei ole nähty käynnissä Watchilla, vain käännetty binääri sisältää kaikki resurssit.
- `.stringsdict`-pohjaista monikkotukea ei ole — mahdollinen erillinen jatkotehtävä, jos halutaan kieliopillisesti tarkempia monikkomuotoja (esim. saksan/venäjän kaltaiset kielet, joissa yksinkertainen %d ei riitä kaikkiin lukumääriin).
- Kauppatekstien (App Store / Google Play -kuvaukset) käännökset eivät kuulu tähän dokumenttiin — ne tehdään erikseen BOD-014:ssä `docs/KAUPPATEKSTIT_LUONNOS.md`:hen, ja ne on merkittävä luonnoksiksi.
- Android: ei tutkittu, ei käännetty. Tämän dokumentin sanasto (kappale "Yhteinen sanasto") on tarkoitettu käytettäväksi terminologisena lähtökohtana, jos/kun Android-lokalisointi joskus toteutetaan — ei todisteena Android-toteutuksen olemassaolosta.
