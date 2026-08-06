# Claude-tehtävät: lyhyt peli, ensipelin opastus ja uudet kielet

Laadittu 9.9.2026. Tämä tiedosto sisältää toteutuspromptit, ei valmiita muutoksia.

## Aloitusohje

Toteuta alla olevat tehtävät järjestyksessä **BOD-011 → BOD-012 → BOD-013 → BOD-014**. Yhdeksän laatan tila tehdään ensin, koska opastus käyttää sitä. Tee yksi kokonaisuus valmiiksi ja tarkista se ennen seuraavaa; jatka sitten seuraavaan ilman erillistä lupakysymystä.

Lue projektin nykyinen koodi, mahdolliset AGENTS.md-ohjeet ja seuraavat dokumentit:
- `docs/KORJAUSSEURANTA.md`
- `docs/CLAUDE_KIRJAUSOHJE.md`
- `docs/KORJAUSTEN_TARKISTUS_2026-09-09.md`

Säilytä olemassa olevat käyttäjän ja muiden työkalujen muutokset. Projektissa on tehty BOD-001–005-korjauksia ja BOD-006-tallennustyötä; älä oleta niiden olevan samassa tilassa kuin vanhassa raportissa. Selvitä ajantasainen tilanne. Älä palauta aiempia tiedostoversioita.

Kohteet ovat **iPhone, iPad ja Apple Watch**. Androidin lähdekoodia ei ole annettu: älä merkitse Androidia toteutetuksi. Kirjaa sille sama tavoitekäyttäytyminen myöhempää vertailua varten.

Älä lisää ulkoisia riippuvuuksia, maksullisuutta, mainoksia, analytiikkapalvelua tai päivittäistä haastetta. Älä tee laajaa ulkoasu-uudistusta, committeja tai julkaisua. Rajatut rakennemuutokset ovat sallittuja, jos ne tekevät opastuksesta, kielistä tai testeistä ylläpidettäviä.

Päivitä `docs/KORJAUSSEURANTA.md` jokaisen tehtävän jälkeen: tunnus, alusta, tila, ennen/jälkeen, tiedostot, testitulokset ja rajoitteet. Lisää tunnukset tarvittaessa uusina riveinä; älä muuta BOD-001–010-tunnusten merkityksiä. Kirjaa päätetyt rawValue-arvot, tallennusavaimet ja migraatiot Android-vertailua varten.

Testit on kytkettävä ajettaviin testikohteisiin; irrallista testitiedostoa ei lasketa ajetuksi testiksi. Jos raportin R1–R4 ovat vielä avoinna, korjaa näiden töiden vaatima testikytkentä ja rikkinäiset testikutsut rajatusti, ja kirjaa jäljelle jäävät aukot. Ympäristössä on ollut Xcode polussa `/Applications/Xcode-beta.app`; tarkista saatavuus ja käytä tarvittaessa prosessikohtaista DEVELOPER_DIR-asetusta. Pelkkä `swiftc -parse` ei varmista käännöstä tai toimintaa.

## Prompti 1 — BOD-011: yhdeksän laatan lyhyt pelimuoto

```text
Lisää Box of Diceen yhdeksän laatan ajastamaton yksinpelimuoto.

Tuotepäätökset:
- Englanninkielinen nimi: Quick Game. Suomenkielinen nimi: Pikapeli.
- Uusi vakaa GameMode-tunnus: quickGame. Älä nimeä vanhoja rawValue-arvoja uudelleen.
- Laatat 1–9, alussa kaksi noppaa, mikä tahansa avoimien laattojen yhdistelmä,
  jonka summa vastaa heittoa. Kun vain laattoja 1–6 on avoinna, käytä yhtä
  noppaa hyödyntäen olemassa olevaa oneDieWhenLowTilesRemain-sääntöä.
- Tulos on jäljelle jäävien laattojen summa. Ei aikapisteitä.
- Nykyinen Classic säilyy 12 laatan pelinä. Speed Run, Big Box,
  Big Box Speed ja Pass & Play säilyttävät nykyiset sääntönsä.
- Pikapeli näkyy iOS:n ja Watchin pelimuotovalinnassa ensimmäisenä.
  Älä näytä pelimuotovalintaa uusille pelaajille automaattisesti;
  ensikäynnistyksen reitti viimeistellään seuraavassa tehtävässä.
- Pikapeli on uuden käyttäjän ensimmäinen oikea peli. Päivittävän käyttäjän
  valittu pelimuoto ja keskeneräinen peli säilyvät.

Toteutus:
1. Tarkista GameMode molemmilla alustoilla, GameSettings.from,
   currentSettings-kutsut, pelimuotovalinnat, tulosnäkymät, jakaminen,
   juhlistuslogiikka ja kaikki pelimuotojen switch-haarat.
2. Varmista, että yhden nopan sääntö välitetään nimenomaan Pikapeliin;
   nykyiset currentSettings-kutsut ovat kovakoodanneet säännöt.
3. Näytä nopan määrän vaihtuessa selkeä lyhyt selite tarvittaessa.
   Heittohetken nopat eivät saa kadota ennen heiton ja valinnan loppua.
4. Lisää Pikapelille omat ennätys-, pistemäärä- ja pelimääräavaimet sekä
   tilastonäkymän rivit ja reset-käsittely. Älä sekoita sen pisteitä Classiciin.
5. Säilytä ja testaa nykyinen pelitallennus, versionointi ja vanhojen
   tallenteiden lukeminen. Pikapeli palautuu omalla pelimuodollaan ja
   säännöillään; se ei saa palautua Classicina.
6. Säilytä vanhojen käyttäjien tallennusdata ja valinnat. Älä muuta
   GameSettings.default-arvoa sokkona, jos se rikkoisi vanhoja oletuksia.
7. Käytä yhteistä GameEngineä molemmilla alustoilla. Watchin nykyinen
   pelimuotojen rajaaminen ei saa muuntaa quickGamea Classiciksi.
8. Lisää tämän tehtävän tekstit heti englanniksi ja suomeksi.

Hyväksymistestit:
- Pikapelissä on alussa täsmälleen laatat 1–9, kaksi noppaa ja pistemäärä 45.
- Siirtyminen yhteen noppaan tapahtuu, kun kaikki 7–9 on suljettu.
- Classicissa on edelleen 12 laattaa ja aiemmat säännöt.
- Pikapelin tulos ja ennätys eivät muuta Classicin omia tilastoja.
- Pikapelin keskeneräinen tallenne palautuu oikein; vanha Classic-tallenne
  palautuu edelleen 12 laatan pelinä.
- Tarkista iPhone, iPad ja Watch sekä molempien sovelluskohteiden buildit.

Kirjaa toteutus ja testinäyttö tunnukselle BOD-011.
```

## Prompti 2 — BOD-012: opastettu ensipeli ja ymmärrettävät pisteet

```text
Tee uudelle pelaajalle lyhyt vuorovaikutteinen ensipelin opastus Pikapelin
laudalla. Poista pelimuotovalikon automaattinen avaaminen ensikäynnistyksellä.
Säilytä pelimuotovalikko helposti löydettävänä normaalissa pelissä.

Haluttu kulku:
1. Uusi pelaaja näkee suoraan yhdeksän laatan laudan sekä lyhyen kehotteen
   "Heitä nopat". Ei erillistä esittelykarusellia tai tilin luomista.
2. Ensimmäinen opastusheitto on määrätty [3, 5], summa 8. Näytä
   "Heitit 8. Sulje esimerkiksi 8 tai 3 + 5."
3. Anna pelaajan valita itse. Hyväksy kaikki sääntöjen mukaiset summan 8
   yhdistelmät, älä ainoastaan esimerkin kahta vaihtoehtoa.
4. Näytä valittujen laattojen summa ja vahvistuspainike. Selitä virheellinen
   summa lyhyesti; älä rankaise tai lukitse pelaajaa opastuksen väärään tilaan.
5. Kelvollisen siirron jälkeen: "Hyvä! Tavoite on jättää mahdollisimman vähän
   pisteitä. Tyhjä lauta = 0." Tarjoa "Aloita peli", joka aloittaa uuden,
   normaalisti satunnaisen Pikapelin. Opastuksen automaattiheitto ei saa
   käynnistyä tämän vaiheen päälle.
6. Opastus on selvästi harjoittelua. Tarjoa aina Ohita-toiminto; se aloittaa
   normaalin satunnaisen Pikapelin ja merkitsee opastuksen käsitellyksi.

Rajaukset ja tallennus:
- Määrätty heitto kuuluu vain opastukseen. Älä muuta normaalipelien
  satunnaisuutta tai lisää siemenriippuvaista arvausta ensimmäiseen heittoon.
  Käytä rajattua testattavaa tapaa syöttää harjoitusheitto.
- Opastus ei muuta pelimääriä, ennätyksiä, voittoputkia tai muita tilastoja,
  eikä tuota normaalia jaettavaa pelitulosta.
- Älä tallenna harjoituslautaa normaalina keskeneräisenä pelinä.
- Jos uusi käyttäjä sulkee sovelluksen kesken opastuksen, sen saa aloittaa
  seuraavalla kerralla alusta. Valmistunut tai ohitettu opastus ei toistu.
- Olemassa oleva palautettava peli menee aina opastuksen edelle.
- Päivittävälle käyttäjälle ei pakoteta opastusta. Tunnista aiempi käyttö
  nykyisistä merkeistä (esim. hasSelectedInitialGameMode, tilastot, tallenne);
  pelkkä uuden onboarding-avaimen puuttuminen ei tarkoita uutta käyttäjää.
- Opastuksen voi avata uudestaan asetusten "Näin pelataan" -toiminnosta.
  Se ei saa tuhota tai ylikirjoittaa olemassa olevaa peliä: säilytä peli
  opastuksen ulkopuolella ja palauta se opastuksesta poistuttaessa. Tällöin
  lopputoiminto on "Takaisin peliin", ei uuden pelin pakkokäynnistys.
- Tee Watchille sama lyhyt kulku pieneen näyttöön sopivin tekstein ja
  painikkein. Opastuksen käsittelymerkintä voi olla laitekohtainen;
  älä rakenna tähän uutta synkronointia.

Noppien summa ja pisteet:
- Näytä noppien summa uusille käyttäjille oletuksena. Tarkista kaikki
  @AppStorage-oletukset, mukaan lukien ContentView ja SettingsView.
- Säilytä aiemman käyttäjän eksplisiittisesti tallennettu false-arvo.
  Älä suorita jokaisessa käynnistyksessä asetuksen pakotusta trueksi.
- Näytä ajastamattomassa pelissä "Jäljellä: 45" (laudan tilanteen mukaan)
  ja lyhyt "Pienempi on parempi" -selite. Käytä englanniksi esimerkiksi
  "Remaining: 45" ja "Lower is better".
- Ajastetussa pelissä erottele jäljellä olevien laattojen pisteet ja aika.
  Älä nimeä aikaa sisältävää loppupistemäärää pelkäksi "jäljellä"-luvuksi.
- Varmista VoiceOver-luettavuus, Reduce Motion ja suuremmat tekstikoot.
- Lisää tekstit englanniksi ja suomeksi; seuraava tehtävä lisää muut kielet.

Hyväksymistestit:
- Tuore asennus menee opastukseen ilman pelimuotovalikkoa.
- Päivittävä käyttäjä ja palautettava peli ohittavat automaattiopastuksen.
- Määrätty heitto on 3 + 5; 8 sekä 3 + 5 hyväksytään, virheellinen summa ei.
- Ohitus ja valmistuminen aloittavat uuden käyttäjän aidon satunnaispelin.
- Opastus ei kirjoita normaaleja tilastoja tai pelitallennetta.
- Asetuksista uudelleen avattu opastus palauttaa aiemman pelin ennalleen.
- Sovelluksen sulkeminen opastuksessa ei riko normaalia peliä/tallennetta.
- Puuttuva showDiceTotal-avain antaa true; tallennettu false säilyy falsena.
- iOS:n ja Watchin buildit ja ensikäynnistyksen toiminnallinen tarkistus.

Pidä opastuksen tilakone erillään normaalipelistä niin, ettei ContentView
kasva uudella suurella määrällä hajanaisia ehtoja. Kirjaa BOD-012.
```

## Prompti 3 — BOD-013: viisi uutta kieltä

```text
Lisää peliin seuraavat kielet tässä järjestyksessä:
1. Saksa — de — Deutsch
2. Ranska — fr — Français
3. Espanja — es — Español
4. Italia — it — Italiano
5. Brasilian portugali — pt-BR — Português (Brasil)

Säilytä englanti, suomi ja järjestelmän kielen seuraaminen. Toteuta kaikki
viisi tämän tehtävän aikana; järjestys on toteutus- ja tarkistusjärjestys.

Kartoita ensin nykyinen lokalisointi:
- iOS:n AppLanguage/L10n ja sovelluksen sisäinen kielivalinta.
- Watchin oma L10n, Bundle-resurssit ja asetukset.
- SwiftUI:n suoraan lokalisoimat tekstiliteraalit sekä L10n-kutsut.
- Tulos-, moninpeli-, tilasto-, opastus-, saavutustekstit ja VoiceOver-tekstit.
- Xcode-kohteiden resurssijäsenyys ja kehityskieli.

Toteutusvaatimukset:
- Lokalisoi koko näkyvä sovellus, myös BOD-011:n ja BOD-012:n uudet tekstit.
  Älä jätä uutta kieltä englanninkielisten avainten täyttämäksi näennäistueksi.
- Käytä projektin nykyistä .strings/.lproj-rakennetta, ellei suppea muutos
  ole välttämätön. Älä tee samalla tarpeetonta koko lokalisointijärjestelmän
  vaihtoa String Catalogeihin.
- Lisää kielivaihtoehdot iOS:n nykyiseen kielivalintaan omakielisillä nimillä.
- Watch seuraa tässä työssä omaa järjestelmäkieltään; kaikki viisi kieltä
  lisätään sen resursseihin. Älä lupaa iPhonen manuaalisen kielivalinnan
  synkronointia tai rakenna sitä tämän tehtävän sivutyönä.
- Tarkista järjestelmän aluevarianttien fallback, kuten de-AT → de ja
  fr-CA → fr. Brasilian portugali on pt-BR; älä kutsu sitä yleiseksi
  kaikkien portugalin aluevarianttien tueksi. Testaa pt-BR-laitelokaali.
- Espanjassa käytä mahdollisimman neutraalia sanastoa. Jos kauppateksteissä
  on myöhemmin aluekohtaisia versioita, tarkista ne erikseen.
- Käytä samoista käsitteistä johdonmukaisia sanoja: laatan sulkeminen,
  jäljellä olevat pisteet, pienempi tulos on parempi, oma ennätys ja opastus.
- Pidä Box of Dice -tuotenimi ennallaan. Pelimuotojen näkyvät nimet saa
  kääntää, mutta rawValue-arvoja, seed-tunnuksia, tallennusavaimia tai
  tallennettujen enumien arvoja ei käännetä.
- Älä kokoa lauseita liimaamalla käännettyjä sananpalasia. Säilytä
  formaattipaikkamerkkien tyypit, argumenttimäärät ja tarvittaessa järjestys.
- Tarkista numerot, desimaalit, päivämäärät ja monikot valitun kielen mukaan.
  Korjaa tarvittavat nykyiset Locale.current-ohitukset rajatusti.
- Kielenvaihto ei saa aloittaa peliä alusta, kadottaa opastuksen vaihetta,
  muuttaa sääntöjä tai kirjata tulosta uudestaan.
- Näkyvät opastuslauseet on mahduttava lukemaan myös Watchissa. Suosi
  luontevaa lyhyttä käännöstä liian pieneksi kutistetun tekstin sijaan.

Lisää docs/LOKALISOINTI.md:
- kielikoodit, resurssit ja alustakohtainen toiminta
- yhteinen termistö seitsemällä kielellä
- tarkistusstatus per kieli ja alusta
- tunnetut puutteet ja ihmisen kielentarkistuksen tarve.
Älä merkitse käännöksiä natiivipuhujan tarkistamiksi ilman oikeaa tarkistusta.

Lisää kevyt ajettava resurssitarkistus, joka löytää puuttuvat/duplikaattiavaimet
sekä ristiriitaiset formaattipaikkamerkit. Huomioi myös englanninkieliset
kehityskielen avaimet, vaikka en.lproj puuttuisi. Älä väitä pelkän avainvertailun
takaavan, että kaikki SwiftUI-tekstit on lokalisoitu: tarkista näkymätkin.

Hyväksymistestit:
- Koko ensipelin kulku ja normaalin pelin tulos näkyvät kullakin kielellä.
- iOS:n manuaalinen kielivalinta ja System toimivat; valinta säilyy käynnistyksessä.
- Watch sisältää ja käyttää jokaisen kielen resursseja.
- Ei rikkinäisiä formaattimerkkijonoja, englantiin jääneitä keskeisiä tekstejä
  tai kriittisiä leikkautuvia painikkeita.
- Kielenvaihto ja aluevariantit eivät riko peliä tai sen palautusta.
- Molemmat sovelluskohteet buildaavat.

Kirjaa BOD-013 kielikohtaisine tarkistustuloksineen.
```

## Prompti 4 — BOD-014: kokonaisuuden tarkistus ja kauppatekstiluonnokset

```text
Tarkista BOD-011–013 kokonaisuutena ja tee niiden julkaisuvalmistelut
paikallisina tiedostoina. Älä julkaise sovellusta tai muuta kauppojen tietoja.

Tarkistusmatriisi:
- uusi käyttäjä → opastus → aito Pikapeli → tulos → toinen peli
- aiempi käyttäjä → vanhan pelin palautus → pelimuodon vaihto Pikapeliin
- vanha Classic-tallenne ja nykyiset ennätykset säilyvät
- opastuksen ohitus, keskeytys ja avaaminen asetuksista uudelleen
- 7–9-laattojen sulkeminen ja yhden nopan sääntö Pikapelissä
- kaikki seitsemän kieltä iOS:ssa ja Watchissa; suuret tekstikoot ja
  pitkä saksankielinen teksti erityisesti pienimmällä tuetulla näytöllä
- iPadin ja iPhonen eri asennot; Watchin rajallinen näyttötila
- nykyiset BOD-001–005-regressiotestit sekä uudet ominaisuustestit.

Korjaa havaitsemasi tähän kokonaisuuteen liittyvät viat. Kirjaa tarkasti,
mitkä kohdat ajettiin laitteella/simulaattorilla, mitkä tarkistettiin vain
koodista ja mitkä jäivät varmistamatta. Älä kuittaa koko matriisia valmiiksi
pelkän onnistuneen buildin perusteella.

Tee docs/KAUPPATEKSTIT_LUONNOS.md, jossa on englanniksi, suomeksi, saksaksi,
ranskaksi, espanjaksi, italiaksi ja Brasilian portugaliksi:
- lyhyt kuvaus uudesta Pikapelistä ja opastuksesta
- kolme lyhyttä kuvakaappausotsikkoa
- päivityksen What's New -luonnos.
Käytä vain todella toteutettuja ominaisuuksia. Älä lisää päivittäistä haastetta,
pilvisynkronointia, premiumia tai väitettä taatusta onnistumisesta. Merkitse
kauppatekstit luonnoksiksi, joiden kenttärajat ja julkaistavan buildin vastaavuus
tarkistetaan ennen syöttämistä App Storeen tai Google Playhin. Älä esitä
Android-ominaisuuksia julkaistuina tai edes toteutettuina tämän Apple-työn perusteella.

Päivitä docs/KORJAUSSEURANTA.md ja docs/LOKALISOINTI.md. Lisää muutoslokiin
Android-vertailua varten yhteenveto uuden quickGame-tilan säännöistä,
onboarding-tiloista, oletusasetuksista, kielikoodeista ja hyväksymistesteistä.

Anna lopuksi tiivis raportti: toteutetut ominaisuudet, testit, tunnetut puutteet
ja muokatut tiedostot. Älä tee committia tai julkaisua. Kirjaa BOD-014.
```
