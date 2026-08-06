# BOD-001–005: riippumaton tarkistus 9.9.2026

## Johtopäätös

Viiden korjauksen tuotantokoodista ei löytynyt tässä tarkistuksessa uutta varmistettua toimintavirhettä. Sovelluksen iOS- ja Watch-simulaattoribuildit onnistuivat. Korjauksia ei kuitenkaan pidä merkitä kokonaan varmennetuiksi: testejä ei ole kytketty projektiin, kahdessa testitiedostossa on käännösvirheitä ja kaksi hyväksymistestiä ei todista tavoiteltua regressiosuojaa.

Tämä oli tarkistus, ei korjaustyö. Repositorion pelikoodia tai testejä ei muutettu. Vain tämä raportti ja seurantalokin tarkistusmerkintä lisättiin.

## Korjattavat havainnot

### R1 — Testit eivät kuulu yhteenkään Xcode-testikohteeseen

`BoxOfDiceTests/` ja `WatchAppTests/` sisältävät testitiedostot, mutta `BoxOfDice.xcodeproj/project.pbxproj` ei sisällä testitargeteja. Molempien skeemojen TestAction-osioista puuttuvat testattavat kohteet. Tavallinen sovellusbuild ei siksi käännä eikä suorita näitä testejä.

**Jatkotoimi:** kytke testit oikeisiin iOS/watchOS-testikohteisiin ja skeemoihin. Aja Xcoden testitoiminnolla molemmat kohteet ja kirjaa komennot sekä tulokset. Jos Watch-testien ajamiselle on aito ympäristörajoite, kirjaa se; älä rinnasta macOS-korvausympäristöä Watch-simulaattoriin.

### R2 — Ajastustestit eivät käänny nykyisiä tuotantorajapintoja vasten

- `BoxOfDiceTests/GameViewModelTimedAnimationTests.swift:22` (myös 41 ja 75): `NoOpGameFeedback()` kutsuu yksityistä alustajaa. Tuotantoluokka tarjoaa `NoOpGameFeedback.shared`-instanssin.
- `WatchAppTests/WatchGameCoreRegressionTests.swift:103`: `GameSettings(tileCount: 1, baseDiceCount: 1)` ei anna jaetun alustajan vaatimia `diceMode`- ja `moveRule`-argumentteja. Anna `.alwaysTwoDice` ja `.anyCombination`.

Molemmat virheet vahvistettiin `swiftc -typecheck` -ajolla rakennettujen iOS/watchOS-moduulien ja oikeiden simulaattori-SDK:iden kanssa. Pelkkä Swiftin parse-tarkistus ei löydä näitä virheitä. iOS:n muut tyyppipäättelyvirheet tässä testissä ovat epäonnistuneen alustajakutsun seurannaisvirheitä.

### R3 — Kaksoiskirjaustesti ei testaa estoa

`BoxOfDiceTests/GameStatisticsRecorderTests.swift:147` kutsuu kirjainta kahdesti ja odottaa pelimääräksi 2. Se ei kutsu näkymän `hasRecordedCurrentGameResult`-suojaa lainkaan. Suojan poistaminen tuotantokoodista ei siten rikkoisi tätä testiä, toisin kuin testin kommentti väittää.

**Jatkotoimi:** testaa todellista pelin päättymisen käsittelypolkua kahdella saman pelin tapahtumalla. Pelimäärän ja summan tulee kasvaa vain kerran. Uuden pelin jälkeen kirjaamisen tulee toimia taas. Tämä on testikattavuuspuute, ei näyttö siitä, että nykyinen näkymässä oleva suoja olisi rikki.

### R4 — Loppuajan testi sallii juuri sen virheen, jota sen pitäisi estää

Molempien alustojen `testElapsedSecondsFinalizedDirectlyFromStartTimeAtGameEnd` käyttää yhden laatan peliä ja hyväksyy yhden sekunnin eron. Havaittu testiajo päättyi kummallakin alustalla alle sekunnissa. Tällöin sekä vanha että uusi toteutus voivat palauttaa 0. Lisäksi yhden sekunnin toleranssi hyväksyy kokonaislukurajan yli ulottuvan vanhentuneen ajastinpäivityksen.

**Jatkotoimi:** käytä hallittavaa kelloa/ajanlaskennan testisaumaa. Aseta viimeinen jaksollinen päivitys juuri ennen sekuntirajaa ja lopetus heti sen jälkeen, ja vaadi täsmällinen lopputulos. Varmista, että testi epäonnistuu, jos `stopTimer()`-metodin suora loppuajan laskenta poistetaan.

## Näyttö korjauksittain

| Tunnus | Tarkistuksen tulos | Rajat |
|---|---|---|
| BOD-001 | Watchin peruutus- ja sukupolvitarkistus on oikeassa kohdassa awaitin jälkeen. Kolme peruutus-/uudelleenkäynnistystestiä läpäisi erillisajon. | macOS:ssa WatchKit-palautteet korvattu tyhjillä toteutuksilla; ei Watch-laitetestiä. |
| BOD-002 | Molemmat viewmodelit käyttävät ajastetussa tilassa normaalia nopeutta. iOS:n näkyvä noppa lukee efektiivisen nopeuden. Lopetusaika lasketaan suoraan. Ajastustestit läpäisivät väliaikaiset rajapintakorjaukset tehtyinä. | R2 ja R4 korjattava; animaatiota ei tarkistettu silmämääräisesti. Watchin ja iOS:n eri pelirytmejä ei luvata keskenään vertailukelpoisiksi. |
| BOD-003 | Watch käyttää jaettua GameEngineä ja välittää siemenen resetille. Jaettu tiedosto kuuluu kumpaankin buildiin. Moottorin 12 testiä läpäisi. | Testiajo macOS:ssa; ei laitteiden välistä kokonaisen pelin vertailuajoa. |
| BOD-004 | Hakualgoritmi ja varhainen poistuminen vaikuttavat oikeilta. Kaikki 5 hakutestiä, mukaan lukien laaja brute force -vertailu, läpäisivät. | Mittaukset macOS Debug-ajosta, eivät puhelimen tai kellon suorituskykylukuja. |
| BOD-005 | Uudet pistekeskiarvot ja ennätykset eritellään pelimuodoittain; vanhoja yhteissummia ei muuteta. Kuusi iOS-kirjaimen testiä läpäisi. | R3 korjattava. Watchin tilastokirjaus on edelleen erillinen toteutus; sen koodia luettiin mutta tilastonäkymää ei ajettu. |

## Ajetut tarkistukset

### Sovellusbuild

Xcode sijaitsee tässä koneessa polussa `/Applications/Xcode-beta.app`; järjestelmän oletus `xcode-select` osoitti vain Command Line Toolsiin. Täysi Xcode saatiin käyttöön prosessikohtaisella `DEVELOPER_DIR`-asetuksella.

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild \
  -project BoxOfDice.xcodeproj -scheme BoxOfDice -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/BoxOfDiceReviewIOS \
  CODE_SIGNING_ALLOWED=NO build
```

**Tulos: BUILD SUCCEEDED.** Riippuvuusgraafi rakensi sekä `BoxOfDice`- että `BoxOfDice Watch App` -kohteen, oikeille iOS/watchOS-simulaattori-SDK:ille. Ensimmäinen yritys estyi sandboxin simulaattoripalvelurajoituksiin; onnistunut ajo tehtiin hyväksytysti sandboxin ulkopuolella. Ensimmäisen yrityksen globaali `-sdk iphonesimulator` poistettiin, jotta se ei pakottaisi Watch-kohdetta väärälle SDK:lle.

### XCTest-erillisajot

Tilannekopion lähteistä tehtiin väliaikainen macOS Swift Package. Tämä ei lisännyt testikohteita varsinaiseen Xcode-projektiin.

1. **23 alkuperäistä testiä läpäisi, 0 virhettä:** GameEngineTests 12, GameEngineSearchTests 5 ja GameStatisticsRecorderTests 6. Tuotantolähteet ja testit kopioitiin muuttamattomina tilannekopiosta.
2. **8 viewmodel-testiä läpäisi, 0 virhettä:** Watch 5 ja iOS 3. Vain väliaikaisiin testikopioihin tehtiin R2:n rajapintakorjaukset. Viewmodelien toimintalogiikka säilytettiin. WatchKit-tuonti korvattiin macOS-ajossa tyhjällä tuntopalauteluokalla; iOS:n oletuspalautepalvelu korvattiin NoOp-toteutuksella. Ajo ei varmista ääniä, tuntopalautetta tai natiivien näkymien toimintaa.

Molemmissa vaiheissa käytetty komento:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test \
  --package-path /private/tmp/BoxOfDiceCoreReview \
  --scratch-path /private/tmp/BoxOfDiceCoreReview-build \
  --cache-path /private/tmp/BoxOfDiceCoreReview-cache --disable-sandbox
```

Pakettia rajattiin toisessa vaiheessa uusiin viewmodel-testeihin, jotta aiempaa 23 testin joukkoa ei ajettu tarpeettomasti uudelleen.

Hakumittaus tässä macOS Debug-ajossa (18 avointa laattaa): summalla 9 noin 0,448 s → 0,000013 s; summalla 18 noin 0,437 s → 0,000051 s. Vertailutestin referenssi laskee kaikki osajoukot kokonaan, joten luku ei ole täsmällinen vertailu aiemman tuotantoversion jokaisen optimoinnin kanssa. Näyttö vahvistaa uuden haun olevan tässä vertailussa selvästi kevyempi, ei tiettyä laitekohtaista nopeutuskerrointa.

## Samanaikaiset muutokset ja säilytetty aineisto

`GameEngine.swift` muuttui tarkistuksen aikana (Codable-tallennusmallin muutoksia). Tarkistusta varten otettiin tilannekopio noin klo 19.53 Suomen aikaa. Viimeisessä vertailussa alkuperäisistä kopioiduista tiedostoista vain GameEngine poikkesi kopion tiivisteestä. Tämä raportti ei hyväksy myöhempiä muutoksia eikä BOD-006-tallennusominaisuutta.

Tämän työympäristön väliaikainen aineisto:
- `/private/tmp/BoxOfDiceReviewSnapshot/` ja `review-hashes.json`: lähteiden tilannekopio ja SHA-256-tiivisteet.
- `/private/tmp/BoxOfDiceReviewIOS.log`: onnistuneen buildin loki.
- `/private/tmp/BoxOfDiceCoreReview-core-results.log`: 23 alkuperäisen testin tulokset.
- `/private/tmp/BoxOfDiceCoreReview-tests.log`: 8 viewmodel-testin tulokset.
- `/private/tmp/BODReviewIOSTestCompile.log` ja `/private/tmp/BODReviewWatchTestCompile.log`: alkuperäisten testien tyyppitarkistusvirheet.

Väliaikaiset tiedostot eivät ole pysyvää repoarkistoa. Raportin johtopäätökset ja rajaukset on siksi kirjattu tähän dokumenttiin. Androidia ei tutkittu. Committeja tai julkaisua ei tehty.
