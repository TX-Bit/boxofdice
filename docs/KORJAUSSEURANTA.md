# Box of Dice: korjausseuranta ja alustavertailu

Perustettu 9.9.2026. Yhteinen kirjanpito iOS-, watchOS- ja Android-korjauksille.

## Lähtötilanne ja näytön rajat

- Alkuperäinen arvio perustuu paikallisen iOS/watchOS-lähdekoodin lukemiseen 9.9.2026. Sovelluksia ei ajettu eikä ongelmia toistettu laitteella arvioinnin yhteydessä.
- Alla olevat korjaukset ovat suunnitelmia, eivät valmistuneita töitä. Aiemmassa keskustelussa laaditut kuusi Claude-promptia vastaavat tunnuksia BOD-001–BOD-006 samassa järjestyksessä.
- Androidin lähdekoodia ei ole tutkittu. Apple-versiossa havaittu ongelma ei todista vastaavaa Android-ongelmaa.
- Työpuussa oli seurannan perustamishetkellä valmiiksi muutoksia. Niitä ei ole tässä luokiteltu tämän korjaussarjan tekemiksi.
- Suhteelliset lähdekoodipolut viittaavat tämän dokumentin sisältävän repositorion juureen.

## Päivitysohje korjauksen tekijälle

1. Lue tehtävän tunnus ja varmista havainto nykyisestä koodista ennen muutoksia.
2. Päivitä alla olevan taulukon kyseisen alustan tila. Älä muuta muiden alustojen tilaa ilman tutkimusta.
3. Kirjaa korjauksen jälkeen muutoslokiin päivämäärä, tunnus, alusta, ennen/jälkeen-käyttäytyminen, muutetut tiedostot ja täsmällinen testinäyttö.
4. Merkitse erikseen testit, joita ei ajettu, sekä epäonnistumiset ja jäljellä olevat rajoitteet. Buildin onnistuminen ei yksin osoita käyttäytymisen korjaantumista.
5. Lisää commit-tunnus ja julkaisuversio vasta, kun ne ovat olemassa. Älä tee committia tai julkaisua pelkän kirjanpidon vuoksi.
6. Säilytä vanhat lokimerkinnät. Lisää uusi merkintä, jos korjausta myöhemmin muutetaan tai vika palaa.
7. Säilytä tehtävään kuulumattomat käyttäjän muutokset. Rajaa lokin tiedostoluettelo omaan korjaukseen.

Tilat: **Tutkimatta**, **Koodihavainto**, **Toistettu**, **Suunniteltu**, **Työn alla**, **Toteutettu, varmistamatta**, **Varmistettu**, **Ei koske**. Käytä `Ei koske` -tilaa vain perustelun kanssa. Julkaisu kirjataan erikseen; varmistettu ei tarkoita julkaistua.

## Tilanne alustakohtaisesti

| Tunnus | Asia | iOS | watchOS | Android |
|---|---|---|---|---|
| BOD-001 | Vanhan asynkronisen tehtävän tilapäivitys | Tutkimatta: tarkista regressio | Toteutettu, varmistamatta | Tutkimatta |
| BOD-002 | Animaatioasetuksen vaikutus aikapisteisiin | Toteutettu, varmistamatta | Toteutettu, varmistamatta | Tutkimatta |
| BOD-003 | Pelilogiikan ja siemenellisen satunnaisuuden yhtenäisyys | Toteutettu, varmistamatta | Toteutettu, varmistamatta | Tutkimatta |
| BOD-004 | Sallittujen siirtojen haun työmäärä | Toteutettu, varmistamatta | Toteutettu, varmistamatta | Tutkimatta |
| BOD-005 | Eri pelimuotojen pisteiden sekoittuminen tilastoissa | Toteutettu, varmistamatta | Toteutettu, varmistamatta | Tutkimatta |
| BOD-006 | Keskeneräisen pelin tallennus ja palautus | Toteutettu, varmistamatta | Toteutettu, varmistamatta | Tutkimatta |
| BOD-011 | Yhdeksän laatan Pikapeli-pelimuoto | Toteutettu, varmistettu | Toteutettu, varmistamatta | Ei koske: tavoite kirjattu vertailua varten |
| BOD-012 | Ensimmäisen pelin opastus Pikapelin laudalla, ei automaattista pelitilavalikkoa | Korjattu, varmistettu: taustatallennusvika korjattu ja katettu regressiotestillä | Korjattu, varmistamatta (sama korjaus, ei watchOS-ajoa) | Ei koske: tavoite kirjattu vertailua varten |
| BOD-013 | Viisi uutta kieltä (de/fr/es/it/pt-BR) englannin ja suomen lisäksi | Korjattu, varmistettu: merkitys-, sijamuoto- ja VoiceOver-virheet korjattu | Korjattu, varmistamatta | Ei koske: sanasto kirjattu vertailua varten |
| BOD-014 | BOD-011–013:n kokonaiskatselmus, kauppatekstiluonnokset, julkaisuvalmistelu (vain paikalliset tiedostot) | Toteutettu, varmistettu (iPad-tarkistus tehty 10.9., ks. korjaus alla) | Toteutettu, varmistamatta | Ei koske: yhteenveto kirjattu vertailua varten |
| BOD-016 | Opastuksen vaaka-asettelu: napit jäivät näytön ulkopuolelle matalassa näkymässä | Korjattu, varmistettu | Ei koske: Watchin opastus oli jo vieritettävä | Ei koske |
| BOD-017 | Kaikki vaaka-asennot (iPhone + iPad): pelin loppuruutu, moninpelinäkymät, juhlistukset ja pelinäkymä | Korjattu, varmistettu: 2-sarakkeiset kortit, ScrollView-kääreet, dynaaminen noppakoko, läpäisi kaikki 85 testiä | Ei koske: Watchissa ei ole vaaka-asentoa | Ei koske |

## BOD-001 — Vanha tehtävä ei saa muuttaa uutta peliä

**Luonne:** toimintavirhe. Ensimmäinen korjaus.

**Havainto:** `WatchApp/WatchGameCore.swift` peruuttaa heittotehtävän uuden pelin alussa, mutta `rollDice()` jatkaa `try? await Task.sleep` -kutsun jälkeen tilan muuttamista tarkistamatta peruutusta. Myös ajastintehtävän lopetus tarkistetaan. iOS:ssa on jo peruutustarkistuksia; samaa vikaa ei ole osoitettu siinä.

**Tavoite:** peruutettu tai vanhaan peliin kuuluva tehtävä ei muuta noppia, pelivaihetta, heittolukitusta, aikaa eikä tuota palautetta. Nykyinen normaali pelinkulku säilyy.

**Hyväksymistestit:**
- Aloita heitto ja uusi peli ennen animaation loppumista. Vanhan odotuksen päätyttyä uusi peli on edelleen aloitustilassa.
- Aloita uusi peli nopeasti useita kertoja. Vanhat tehtävät eivät vaikuta viimeiseen peliin.
- Vanhan ajastimen lopettaminen ei muuta uuden pelin aikaa.

**Android-vertailu:** tarkista coroutinet, viivästetyt callbackit, animaation valmistumiskäsittelijät ja ajastimet. Peruuttaminen ja pelisession tunnistaminen voivat vaatia Androidissa eri toteutuksen; hyväksymiskäyttäytyminen on sama.

## BOD-002 — Animaatioasetus ei saa antaa piste-etua

**Luonne:** pisteytyksen reiluusvirhe.

**Havainto:** `BoxOfDice/GameViewModel.swift` ja `WatchApp/WatchGameCore.swift` mittaavat aikaa ensimmäisestä heitosta. Käyttäjän valitsema animaatiokesto sisältyy aikaan. Tarkista lopetuksessa myös viimeisen ajastinpäivityksen ja lopullisen ajan ero.

**Valittu korjauslinja:** ajastetuissa pelimuodoissa käytetään normaalia vakioanimaatiota; muissa pelimuodoissa käyttäjän asetusta. Sekä näkyvä animaatio että vuorovaikutuslukitus käyttävät samaa efektiivistä kestoa. Lopullinen aika lasketaan lopetushetkellä, ei viimeisestä ajastinpäivityksestä. Pisteytyskaava säilyy.

**Hyväksymistestit:**
- Short/normal/long-asetukset tuottavat ajastetussa pelissä saman efektiivisen animaatiokeston.
- Asetuksen muuttaminen kesken ajastetun pelin ei anna etua.
- Tavalliset pelimuodot kunnioittavat asetusta.
- Lopetusaika vastaa määriteltyä pyöristystä lopetushetkellä.

**Android-vertailu:** selvitä, sisältyvätkö animaatiot ja automaattiheiton viiveet pisteisiin. Älä julista eri alustojen aikatuloksia vertailukelpoisiksi ennen kuin myös muu pelinkulku, ajastus ja säännöt on verrattu.

## BOD-003 — Sama sääntömoottori Apple-alustoille

**Luonne:** ylläpidettävyyskorjaus ja todettu siemenparametrin toiminnallinen puute. Suurempi työ kuin muut yksittäiset korjaukset.

**Havainto:** `BoxOfDice/GameEngine.swift` sisältää erillisen puhtaan moottorin ja siemenellisen generaattorin. `WatchApp/WatchGameCore.swift` toteuttaa omaa pelilogiikkaa; `newGame(settings:seed:isTimed:)` ei käytä vastaanottamaansa siementä. Sääntöjen käsittely on myös eriytynyt.

**Tavoite:** iOS ja watchOS käyttävät samaa alustariippumatonta pelimoottoria ja puhtaita malleja. Käyttöliittymä, lokalisointi, tuntopalaute ja alustakohtainen heittojen käynnistystapa säilyvät erillisinä. Tallennusavaimet säilytetään. BOD-001- ja BOD-002-korjaukset eivät saa kadota yhdistämisessä.

**Hyväksymistestit:**
- Sallittu/virheellinen valinta, voitto ja siirtojen loppuminen.
- Yhden nopan sääntö sekä enintään kahden laatan sääntö.
- Samat asetukset, siemen ja toimintojono tuottavat saman lopputilan Apple-alustoilla.
- Reset vaihtaa siemenen oikein; ilman siementä peli on satunnainen.
- Molemmat sovelluskohteet buildaavat.

**Android-vertailu:** yhteinen Swift-lähdekoodi ei ole Android-vaatimus. Vertaa sääntöjä ja tilasiirtymiä alustariippumattomilla testitapauksilla. Jos myöhemmin halutaan yhteisiä siemenhaasteita, määritä generaattori, siemenen muoto, noppaluvuksi muunnos, generaattorin kulutus ja algoritmiversio täsmällisesti. Sama numero siemenenä ei yksin takaa samoja heittoja Swiftissä ja Kotlinissa.

## BOD-004 — Rajattu sallittujen siirtojen haku

**Luonne:** koodista havaittu suorituskykyriski; laitehidastumista ei ole mitattu.

**Havainto:** molemmat toteutukset käyvät läpi kaikki avointen laattojen epätyhjät osajoukot. 18 laatalla niitä on 262143. Siirron olemassaolon tarkistus muodostaa nykyisin myös tarpeettomasti koko siirtolistan.

**Tavoite:** rajattu haku katkaisee mahdottomat haarat ja huomioi siirtosäännön jo haussa. Olemassaolotarkistus päättyy ensimmäiseen löydettyyn siirtoon. Sallitut yhdistelmät ja nykyinen vihjeen valintaperiaate säilyvät.

**Hyväksymistestit:** vertaa tulosjoukkoja yksinkertaiseen brute force -referenssiin eri avoimilla laatoilla, noppasummilla ja molemmilla säännöillä. Ei puuttuvia siirtoja tai duplikaatteja. Mittaa täyden Big Box -laudan haku ennen/jälkeen ja kirjaa laite/ympäristö sekä mittaustapa. Älä käytä haurasta tarkkaa aikarajaa regressiotestissä.

**Android-vertailu:** tarkista algoritmi ja kutsujen määrä. Mittaa Androidissa erikseen; Apple-laitteen ajoaika ei osoita Androidin suorituskykyä.

## BOD-005 — Vertailukelpoiset tilastot ja turvallinen migraatio

**Luonne:** tilastojen tulkittavuusvirhe.

**Havainto:** `BoxOfDice/ContentView.swift`-tiedoston `recordCompletedGame` yhdistää eri lautojen ja ajastettujen pelien loppupisteitä yhteisiin summiin ja ennätykseen. Pelimuotokohtaisia ennätyksiä on jo olemassa. Watchin tilastot tulee tutkia erikseen.

**Tavoite:** uudet pisteisiin perustuvat tilastot eritellään pelimuodoittain. Järkevät yhteismäärät säilyvät. Vanhoja tilastoja ei poisteta eikä puuttuvaa pelimuotohistoriaa päätellä arvaamalla. Uusien keskiarvojen alkaminen päivityksestä kerrotaan selvästi. Moninpelin nykyinen tilastokäytäntö säilyy. Yksi päättynyt peli kirjataan vain kerran; mahdollista nykyistä kaksoiskirjausvikaa ei vielä ole osoitettu.

**Hyväksymistestit:** vanha tallennusdata, ensimmäinen uusi tulos, nollan pisteen ennätys, ajastettu tulos, eri pelimuotojen erillisyys ja saman pelituloksen käsittely uudelleen. Testaa migraation toistaminen.

**Android-vertailu:** vertaa pistekaavoja, tilastojen ryhmittelyä, vanhan datan migraatiota ja tulosten yksikäsitteistä kirjaamista. Älä kopioi Apple-tallennusavaimia ilman Androidin nykyisen datan kartoitusta.

## BOD-006 — Keskeneräisen pelin palautus

**Luonne:** puuttuvan toiminnallisuuden lisäys, ei sama asia kuin toistettu kaatumisvika. Toteutetaan muiden korjausten jälkeen.

**Havainto:** iOS:n aktiivinen peli näyttää olevan vain muistissa, vaikka asetukset ja tilastot tallennetaan. Palautuminen prosessin päättymisen jälkeen on varmistettava laitteella. Watchin tallennus kartoitetaan ennen toteutusta.

**Tavoite:** versionoitu, eheä paikallinen pelitallenne. Tallennetaan pelimuoto, säännöt, laatat, nopat, valinta, pelivaihe, siirtohistoria, satunnaisgeneraattorin tila sekä moninpelin vuoro ja tulokset. Keskeneräinen heitto ei saa vaihtua uudeksi arvonnaksi tai jäädä lukkoon. Ajastetussa pelissä taustalla kulunut aika kuuluu edelleen tulokseen. Vioittunut tallenne ei kaada peliä. Palautus ei kirjaa tulosta uudestaan. Ei pilvisynkronointia tässä työssä.

**Hyväksymistestit:** palautus ennen heittoa, valinnan aikana, heiton aikana, ajastetussa pelissä ja moninpelin pelaajavaihdossa. Testaa oikea prosessin päättäminen ja uudelleenkäynnistys, ei vain näkymän luontia. Testaa vioittunut/tuntematon tallenne, uuden pelin korvaava tallennus ja päättyneen pelin palautus.

**Android-vertailu:** erottele näytön kierto, Activityn uudelleenluonti, taustalle siirtyminen ja prosessin kuolema. ViewModelin säilyminen yksin ei tarkoita pysyvää pelitallennusta.

## Muut löydökset — ei sisälly kuuteen korjaukseen

| Tunnus | Havainto | Jatkokäsittely |
|---|---|---|
| BOD-007 | `bestHint()` suosii vähintä laattamäärää; strategista optimaalisuutta ei lasketa. | Nykyinen Hint-teksti ei yksin ole lupaus parhaasta strategiasta. Mahdollinen strategiaopastus on oma ominaisuutensa. |
| BOD-008 | ContentView sisältää noin 1400 riviä ja useita vastuita. | Pilkotaan hallitusti tarpeen mukaan, ei laajana sivuremonttina bugikorjauksessa. |
| BOD-009 | Julkinen App Store -kuvaus ja paikallinen koodi kuvaavat suljettavia laattoja eri tavoin. | Vertaa julkaistuun buildiin ennen kauppatekstin päivitystä. Ei oleteta paikallista koodia julkaistuksi. |
| BOD-010 | PhoneConnectivityManager voi ohittaa ensimmäisen teeman lähetyksen session aktivoituessa; valmistumiskäsittelijä on tyhjä. | Alustava koodihavainto, toistettava ensin. Ei aiempien kuuden promptin piirissä. |
| BOD-015 | Monikkomuotoja ei eroteta: `"%d pts"` näyttää arvolla 1 tekstin "1 pts" (`PassAndPlayViews.swift:207`). Koskee myös fr/es/pt-BR; fi/de/it ovat oikein, koska lyhenne ei taivu. Löydetty 10.9.2026 kielioppikatselmuksessa. | Vaatii `.stringsdict`-tuen: puuttuva `en.lproj`, `L10n.string`:n englanti-oikaisun koodimuutos, Watchin `PBXVariantGroup`-kytkentä ja `LocalizationResourceTests`:n laajennus. Oma tehtävänsä, ei sivutuote. Ks. `docs/LOKALISOINTI.md`. |

## Muutosloki

### 25.11.2026 — Keskiyö oletusteemaksi ja keskitetty ostoruutu

- Keskiyö on iOS- ja watchOS-kohteiden oletusteema. Sovellus käyttää tallennettua teemavalintaa, jos pelaaja on jo valinnut teeman.
- Täysversion näkymän otsikko, kuvaus, hinta ja ostojen palautus ovat keskitetyn, valittuun teemaan mukautuvan kortin sisällä. Matalassa näkymässä noppakuvake on otsikon vieressä ja ostopainike ostojen palautuksen vieressä.

### 25.11.2026 — Päivittäinen kierrosraja ja täysversio

- Ilmaisversiossa voi aloittaa 10 kierrosta kalenteripäivässä laitteen paikallisen ajan mukaan. Ensimmäinen nopanheitto käyttää kierroksen. Tallennetun kierroksen jatkaminen ja harjoittelu ovat mahdollisia myös päivärajalla. Vuoropelissä jokaisen pelaajan kierros lasketaan erikseen.
- StoreKitin vahvistama kertamaksullinen täysversio poistaa kierrosrajan ja arvostelupyynnöt. Oston ja ostojen palautuksen voi avata asetuksista tai päivärajan näkymästä. Sovellus näyttää StoreKitin paikallisen hinnan.
- App Storen järjestelmäpyyntö tehdään joka kahdeksannen loppuun pelatun ilmaiskierroksen jälkeen. Apple päättää ikkunan näyttämisestä.
- App Store Connectin tuoteluonnos on **Non-Consumable**, tuotetunnus `com.mm.BoxOfDice.fullversion` ja Yhdysvaltain perushinta **1,99 USD**. Perhejako on käytössä. Ensimmäinen ostotuote lähetetään arviointiin uuden sovellusversion mukana. [Applen hintaohje](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase) · [Applen arviointiohje](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
- Päivärajan ostoruudun teksti lyhennettiin. Hinta haetaan ostoruudun avautuessa näkyviin ostajan App Store -alueen valuutassa. App Store Connectissa Suomen hinnaksi tarkistettiin **1,99 €**.

### 25.11.2026 — iPhonen, iPadin ja Duon tulosruudut

- Yksinpelin tuloskortti käyttää samaa kompaktia yhden palstan asettelua pystyssä ja vaakatasossa. Kortti näyttää loppupisteet, mahdollisen aikatuloksen ja ennätystiedon. Avoimien laattojen lista poistettiin tuloskortista. Duon etunäytön vaakakortti keskitetään, ja osittain avattuna kortti sijoitetaan taitoksen ohjainpuolelle.
- XCTest tarkistaa vieritystarpeen 13 koossa, mukaan lukien pienet iPhonet, iPadin jaettu ikkuna ja Duon taittoasennot. Testit kattavat ajastetun yksinpelin ennätystietoineen, Vuoropelin kierrostuloksen ja neljän pelaajan lopputuloksen.

### 25.11.2026 — iPhone Duo: yhtenäinen sisänäytön pystyasettelu

- Osittain ja kokonaan avattu sisänäyttö käyttävät samaa pystyasettelua. Otsikko ja lauta ovat taitoksen yläpuolella, nopat ja vuoropainike alapuolella. Klassisen 4 × 3 -lauta on osittain avattuna hieman pienempi.
- Vertailukuvat otettiin simulaattorissa Pikapelistä, Klassisesta ja Isosta laatikosta molemmissa taittoasennoissa.
- Palautteen perusteella 12 laatan pelit käyttävät molemmissa pystyasennon taittoasennoissa kahta kuuden laatan riviä. Laatoille jää enemmän tilaa, ja otsikon, noppien sekä vuoropainikkeen paikat säilyvät.

### 25.11.2026 — iPhone Duo: yhtenäinen ulkonäytön pystyasettelu

- Otsikko, pistetieto, pelimuotovalitsin, nopat ja vuoropainike käyttävät yhteisiä paikkoja laattamäärästä riippumatta. Pikapelin 3 × 3 -lautaa madallettiin ja Klassisen laattoja pidennettiin hieman.
- Build onnistui. Duon simulaattorista otettiin vertailukuvat 9, 12 ja 18 laatan peleistä. Pikapelissä Sulje laatat ja Vihje näkyivät samalla ruudulla heiton jälkeen.

### 25.11.2026 — iPhone Duo: yhtenäiset sisänäytön vaakanäkymät

- Täysin avoin ja osittain avoin vaakanäkymä käyttävät samaa laudan ja ohjainten asettelua. Taitos määrää palstojen välisen vapaan alueen. Noppien enimmäiskokoa kasvatettiin ja vuoron painiketta laskettiin.
- Build onnistui. Device Hubissa heitettiin Ison laatikon kolme noppaa molemmissa asennoissa. Vertailukuvat otettiin samasta pelitilanteesta ja näytettiin käyttäjälle esikatseluna.

### 25.11.2026 — iPhone Duo: pelilautojen ja pelimuotovalikon esikatselu

- Classicin oikeaa palstaa väljennettiin kirjataitossa. Pikapeli käyttää 3 × 3 -ruudukkoa sisänäytöllä. Ison laatikon laattoja ja ohjainpalstaa väljennettiin kirja-asennossa.
- Pelimuotovalikko mukautuu käytettävissä olevaan tilaan. Duon kirjataitossa ja käännetyllä ulkonäytöllä kaikki kuusi pelimuotoa, Vuoropelin pelaajamäärä ja aloituspainike näkyivät ilman vieritystä. Build onnistui. Asettelut ovat käyttäjän esikatselussa.
- Palautteen perusteella valikko palautettiin alkuperäisiin ryhmiin ja kuvauksiin. Ryhmät ovat tavallisesti allekkain. Matalassa vaakanäkymässä ne voivat olla kahdessa palstassa, ja Vuoropelin pelaajamäärä mahtuu aloituspainikkeen viereen. Uusi build onnistui ja kuvat otettiin Duon simulaattorista Vuoropeli valittuna.

### 25.11.2026 — iPhone Duo: pelilaudan mittasuhteet ja pystynäkymä

- Pienennettiin pelilautaa Duon vaakanäkymissä. Osittain avatun näytön ohjaimiin palautettiin Noppalauta-otsikko. Täysin avatulla vaakanäytöllä tilasto- ja asetuskuvakkeet sijoitettiin pistetietojen yhteyteen.
- Duon pystynäkymä valitsee normaalin tai tiiviin asettelun vapaan korkeuden mukaan. Vieritys on varalla, jos kumpikaan ei mahdu. Classicin lauta, nopat, Sulje laatat ja Vihje näkyivät ulkonäytöllä heiton jälkeen ilman vierittämistä.

### 25.11.2026 — iPhone Duo: pelinäkymä osittain avattuna

- Pelilauta ja vuoron ohjaimet sijoitetaan järjestelmän ilmoittaman taitosalueen eri puolille. Kirja-asennossa lauta on vasemmalla ja ohjaimet oikealla. Vaakasuorassa taitossa lauta on ylhäällä ja ohjaimet alhaalla.
- iPhone Duo -simulaattorissa 81 XCTest-testiä läpi. Pelimoottorin hakutestit jätettiin tästä ajosta pois. Device Hubissa tarkistettiin Classicin lauta ja ohjaimet osittain avatussa kirja-asennossa.
- Jatkosäätö: kirja-asennossa 12 laattaa asetettiin neljään sarakkeeseen ja kolmeen riviin. Ohjaimia suurennettiin. Täysin avatun vaakanäkymän 12 laatan ruudukko muutettiin samaan muotoon ja laudan yläreuna sovitettiin tilastopainikkeen alle. Ulkonäytön sisältö keskitettiin sekä pysty- että vaaka-asennossa, ja kameran sekä tilailmaisinten ympärille jätettiin tilaa. Viimeisin build onnistui ja Classic tarkistettiin Device Hubissa näissä asennoissa.

### 25.11.2026 — iOS: uuden pelin vahvistus ja tilastotekstit

- Pelimuotovalikon Aloita peli kysyy vahvistuksen, jos nykyisessä pelissä on heitetty tai heitto on käynnissä. Myös kesken oleva paikallinen moninpeli suojataan pelaajien vuorojen välissä. Peruutus säilyttää nykyisen pelin ja pelimuotovalikon valinnan.
- Tilaston nimi on nyt ”Vähiten siirtoja voittoon”. iOS käyttää yksikköä ja monikkoa oikein kaikilla seitsemällä kielellä. Watch-kohteen otsikko täsmennettiin samoin.
- iPhone Duo -suunnitelma: ulkonäytölle nykyinen pystynäkymä, leveälle sisänäytölle lauta vasemmalle ja noppien sekä vuoron ohjaimet oikealle. Valitse asettelu vapaan ikkuna-alueen mukaan. Tarkista taittamisen aikana sama peli, valitut laatat, kesken oleva heitto ja ajastin. Asettelumuutos on suunnittelussa.
- Varmistus: iPhone Duo -simulaattorissa 81 XCTest-testiä läpi. Pelimoottorin hakutestit rajattiin tästä ajosta pois. Watch-kohde rakentui. Vahvistusdialogin käsinajo ja Duon eri taittoasentojen visuaalinen tarkistus ovat avoinna.

### 10.9.2026 — riippumaton BOD-011–014-tarkistus

- Nykyinen iOS-testikokonaisuus ajettiin erillisestä lähdekoodikopiosta: **62/62 läpi**.
- Lisätty vain tarkistuskopioon käyttöliittymän elinkaarta käyttävä integraatiotesti: **1/1 epäonnistui**, koska ensikäynnistyksen opastuksen taustoitus tallensi piilossa olevan 12 laatan Classic-pelin. Sama tallennuspolku löytyi Watch-koodista, mutta Watch-ajonaikaista toistoa ei tehty.
- Pikapelin peruslogiikka ja tilastojen erottelu läpäisivät testit. Watchin opastuksesta puuttuu valinnan summa ja nollapisteen selitys; normaalipelistä summan näyttö. Käännöksissä ja iOS:n VoiceOver-avaimissa on vielä avoimia kohtia.
- BOD-012–014:n iOS-tiloja tarkennettu yllä; aiemmat toteutuslokit säilytetty. Kokonaisuutta ei vielä merkitä julkaisuvalmiiksi.
- Raportti ja korjausohjeet: [UUDISTUSTEN_TARKISTUS_2026-09-10.md](UUDISTUSTEN_TARKISTUS_2026-09-10.md).
- Kaikkien seitsemän kielen arvio: [KIELITARKISTUS_2026-09-10.md](KIELITARKISTUS_2026-09-10.md).
- Varsinaiseen projektiin muutettiin tässä tarkistuksessa vain dokumentteja. Ei committia, julkaisua eikä Android-tarkistusta.

### 9.9.2026 — BOD-011, iOS + iPadOS + watchOS: Pikapeli (Quick Game), 9 laattaa

Toteutus `docs/CLAUDE_UUDET_OMINAISUUDET.md`:n ohjeistuksella. Ennen aloitusta luettu `docs/KORJAUSSEURANTA.md`, `docs/CLAUDE_KIRJAUSOHJE.md` ja `docs/KORJAUSTEN_TARKISTUS_2026-09-09.md`; havaittu ajantasainen tila (BOD-001–006 toteutettu, BOD-006:n tallennuskoodi olemassa, R1–R4 korjattu edellisessä istunnossa) suoraan koodista, ei vanhasta raportista.

- Tunnus ja alusta: BOD-011, iOS + iPadOS (yhteinen SwiftUI-koodi) + watchOS
- Tila ennen → jälkeen: Puuttuu → Toteutettu
- **Tuotepäätökset (kirjattu Android-vertailua varten):**
  - `GameMode.quickGame` — vakaa `rawValue` = `"quickGame"`. Vanhoja rawValue-arvoja (`classic`, `speedRun`, `bigBox`, `bigBoxSpeed`, `passAndPlay`) ei muutettu.
  - Englanti: "Quick Game". Suomi: "Pikapeli".
  - Laatat 1–9 (`tileCount = 9`), `baseDiceCount = 2`, `diceMode = .oneDieWhenLowTilesRemain` (uusi `GameMode.diceMode`-laskettu ominaisuus, molemmilla alustoilla), `moveRule = .anyCombination`. Yhden nopan raja: kaikki avoimet laatat ≤ 6 (olemassa oleva `GameEngine.currentDieCount`-logiikka, ei muutettu).
  - Ei aikapisteitä (`isTimed = false`, oletus).
  - Tulos = jäljelle jäävien laattojen summa (olemassa oleva `score`-logiikka, ei muutettu).
  - Classic (12), Speed Run (12+aika), Big Box (18), Big Box Speed (18+aika), Pass & Play (12, moninpeli) säilyivät muuttumattomina.
  - Uudet tallennusavaimet: `statistics.bestScore.quickGame`, `statistics.modeScoreTotal.quickGame`, `statistics.modeScoreCount.quickGame` (sama avainnimikäytäntö kuin muilla pelimuodoilla, BOD-005). Ei migraatiota — uudet avaimet alkavat tyhjinä kaikilla asennuksilla, kuten muutkin `modeScoreTotal`/`modeScoreCount`-avaimet BOD-005:ssä.
  - `GameMode`-enumin `case quickGame` on ensimmäinen tapaus (`CaseIterable.allCases` järjestys), jotta Watchin pelitilavalikko (joka iteroi `allCases`) näyttää sen ensimmäisenä ilman erillistä listaa. iOS:n `GameModeSelectionView` listaa ryhmät käsin; "Quick"-ryhmä lisätty ensimmäiseksi samasta syystä.
- Toteutus:
  - `BoxOfDice/GameMode.swift` ja `WatchApp/WatchGameCore.swift`:n `GameMode` (molemmat alustakohtaiset kopiot): uusi `case quickGame` ensimmäisenä, `title`/`subtitle`/`tileCount`/`baseDiceCount`/uusi `diceMode`-laskettu ominaisuus.
  - `ContentView.currentSettings` ja `WatchContentView.currentSettings`: välittivät aiemmin kovakoodatun `.alwaysTwoDice`:n kaikille pelimuodoille (havaittu koodivirhe, joka olisi estänyt yhden nopan säännön Pikapelissä) — korjattu käyttämään `currentGameMode.diceMode`:a.
  - `GameStatistics.swift`, `WatchGameCore.swift`:n `StatisticsStorageKey`: uudet Pikapeli-avaimet.
  - `GameStatisticsRecorder.swift` (iOS) ja `WatchContentView.swift`:n omat `updateBestScoreByMode`/`updateModeScoreAverage`-toteutukset (Watch käyttää BOD-005:stä lähtien omaa, ei-jaettua tilastokirjausta): uusi `case .quickGame` molempiin switch-lohkoihin.
  - `StatsView.swift` (iOS) ja `WatchSupportViews.swift`:n `WatchStatsView`: Pikapeli lisätty ensimmäisenä "Best/Average Score by Mode" -riveihin ja "Reset"-käsittelyyn.
  - `GameModeSelectionView.swift` (iOS): "Quick"-ryhmä (`[.quickGame]`) ensimmäisenä pelitilalistassa.
  - `ContentView.swift`: uusi lyhyt selite ("One die now — only low tiles remain" / "Yksi noppa nyt — vain pienet laatat jäljellä"), näkyy vain kun `currentGameMode == .quickGame && viewModel.dieCount == 1`. `viewModel.dieCount` pysyy jo ennestään kiinnitettynä heiton omaan noppamäärään koko heiton+valinnan ajan (`rollingDieCount`-tilannekuva), joten nopat eivät katoa kesken heittoa; tätä ei tarvinnut korjata, vain vahvistaa koodista.
  - Watchin pieneen näyttöön ei lisätty vastaavaa selitetekstiä (tilan puute); nopan määrän muutos on siellä jo itsessään selkeä visuaalinen vihje.
  - `BoxOfDice/fi.lproj/Localizable.strings`, `WatchApp/fi.lproj/Localizable.strings`: uudet englannin/suomen tekstit heti ("Quick Game"/"Pikapeli", "Quick"/"Pika", "9 tiles · short and simple" / "9 laattaa · lyhyt ja yksinkertainen", "One die now — only low tiles remain" / "Yksi noppa nyt — vain pienet laatat jäljellä", Watchille "9 tiles"/"9 laattaa").
  - `GameSave.swift`/`ContentView.restoreSavedGameIfAny`/`persistCurrentGame`: ei muutettu — `SavedGame.gameMode: GameMode` ja `GameEngine` ovat jo täysin yleisiä; Pikapeli-tallenne palautuu automaattisesti omalla pelimuodollaan ja säännöillään, koska mitään pelimuotokohtaista erikoiskäsittelyä ei ollut palautuskoodissa.
  - `BoxOfDice.xcodeproj/project.pbxproj`: uusi `BoxOfDiceTests/QuickGameTests.swift` lisätty `BoxOfDiceTests`-testikohteeseen `xcodeproj`-Ruby-kirjastolla (samalla tavalla kuin R1-korjauksessa testikohteet lisättiin). `plutil -lint` vahvisti validiuden.
- Uusi testitiedosto: `BoxOfDiceTests/QuickGameTests.swift` (8 testiä): aloitustila (9 laattaa, 2 noppaa, pistemäärä 45), Classic säilyy 12 laattana, siirtyminen yhteen noppaan kun 7–9 suljettu, pysyy kahdessa nopassa kun jokin 7–9 on auki, mikä tahansa yhdistelmä sallitaan, Pikapelin tulos/ennätys ei vaikuta Classiciin, Pikapeli-tallenne palautuu Pikapelinä, vanha Classic-tallenne palautuu edelleen 12 laatan pelinä.
- **Ajetut testit ja buildit (oikea Xcode 27.0 beta, `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`):**
  - `xcodebuild -scheme "BoxOfDice Watch App" -destination 'generic/platform=watchOS Simulator' build` → **BUILD SUCCEEDED**.
  - `xcodebuild test -scheme BoxOfDice -destination 'platform=iOS Simulator,id=<iPhone 17 Pro>'` → **TEST SUCCEEDED, 51/51 testiä** (kaikki aiemmat 43 + uudet 8 `QuickGameTests`).
  - Asennettu ja käynnistetty käännetty `BoxOfDice.app` samalla iPhone-simulaattorilla (`xcrun simctl install`/`launch`) ja otettu kuvakaappaus — sovellus käynnistyi, lauta ja suomenkieliset tekstit renderöityivät oikein virheittä. Ei automatisoitua kosketussyötettä (ei UI-testikehystä käytössä), niin Pikapeli-tilan valintaa "Valitse pelitila" -näkymässä ei nähty silmämääräisesti kuvakaappauksella; sen ensimmäinen sijainti listassa on varmistettu koodista (`modeGroup`-kutsujärjestys) ja epäsuorasti `GameMode.allCases`-järjestyksellä Watchille.
  - **iPad:** ei erillistä iPad-simulaattoria käytettävissä tässä ympäristössä (vain "iPhone 17 Pro" saatavilla `xcrun simctl list devices available`); iPad-layout käyttää samaa yleistä laattaruudukon kaavaa (`columnsCount = tiles.count > 10 ? 6 : 5`, `ContentView.swift`) kuin muut ei-Big-Box-pelimuodot, eikä Pikapeli lisää mitään iPad-kohtaista erikoistapausta — tarkistettu koodista, ei laitteella/simulaattorilla.
  - **watchOS-testit:** `BoxOfDice Watch AppTests`-kohde kääntyy, mutta tässä ympäristössä ei ole watchOS-simulaattorin ajonaikaista asennettuna (`xcrun simctl list runtimes` näyttää vain iOS 27:n) — Watch-kohtaisia Pikapeli-yksikkötestejä ei lisätty eikä ajettu tällä kierroksella samasta syystä kuin BOD-006:ssa.
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Uudet `statistics.*.quickGame`-avaimet lisätty; ei muutoksia olemassa oleviin avaimiin tai `GameSettings.default`-arvoon (edelleen Classic-vastaava 12/2/`.alwaysTwoDice`/`.anyCombination`, koskematta pyynnön mukaisesti).
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: Ei laitetestiä. Ei iPad-simulaattoria. Ei watchOS-simulaattoriajoa (vain kääntö). Pikapelin ensimmäistä sijaintia mode-valitsimessa ei nähty silmämääräisesti napautuksin, vain koodista ja kuvakaappauksesta pelinäkymän puolelta.
- Android-vertailu: Ei toteutettu, ei merkitty toteutetuksi. Tavoite Android-vertailua varten: 9 laatan pelimuoto `quickGame`-tunnuksella (tai vastaavalla vakaalla tunnisteella), laatat 1–9, kaksi noppaa alussa, yksi noppa kun laatat 7–9 suljettu, mikä tahansa summaa vastaava yhdistelmä, ei aikapisteitä, oma ennätys/keskiarvo erillään Classicista, näkyy pelitilavalinnan ensimmäisenä.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-012, iOS + iPadOS + watchOS: ensimmäisen pelin opastus, automaattivalikon poisto

Toteutus `docs/CLAUDE_UUDET_OMINAISUUDET.md`:n Prompt 2:n ohjeistuksella, BOD-011:n jälkeen samassa istunnossa.

- Tunnus ja alusta: BOD-012, iOS + iPadOS (yhteinen SwiftUI-koodi) + watchOS
- Tila ennen → jälkeen: Puuttuu → Toteutettu
- **Tuotepäätökset (kirjattu Android-vertailua varten):**
  - Uusi jaettu (molemmilla alustoilla käytetty) tyyppi `OnboardingViewModel` — täysin erillinen tila-automaatti, ei kosketa `GameEngine`/`GameViewModel`/`GameSave`/tilastoja. Askeleet: `waitingForRoll` → `selecting` → `resolved`.
  - Opastuksen heitto on kiinteä `[3, 5]` (summa 8) vain opastuksessa; normaalin pelin satunnaisuuteen ei koskettu.
  - Opastus hyväksyy minkä tahansa sääntöjenmukaisen summa-8-yhdistelmän avoimista laatoista (Pikapelin `MoveRule.anyCombination`-logiikkaa vastaava tarkistus opastuksen omassa mallissa), ei vain esimerkkejä (yksi laatta 8, tai 3+5).
  - Virheellinen summa ei sulje mitään eikä lukitse tilaa — pelaaja voi jatkaa valintaa vapaasti (`canConfirm == false`, `confirm()` on no-op).
  - Uusi tallennusavain `settings.onboardingCompletedOrSkipped` (Bool, laitekohtainen, ei WatchConnectivity-synkronointia — Watchilla oma samanniminen avain omassa `SettingsStorageKey`-enumissaan).
  - Uusi käyttäjä tunnistetaan heuristiikalla `isReturningUser = hasSelectedInitialGameMode || gamesPlayed > 0`, tarkistetaan vasta sen JÄLKEEN kun `restoreSavedGameIfAny()` on jo yritetty ja epäonnistunut — palautettavissa oleva peli voittaa aina opastuksen. Palaava käyttäjä saa `onboardingCompletedOrSkipped = true` takautuvasti, jottei heuristiikkaa arvioida joka käynnistyksellä uudestaan.
  - Automaattinen pelitilavalikon avaus ensimmäisellä käynnistyksellä (`if !hasSelectedInitialGameMode { isShowingModeSelection = true }`) POISTETTU molemmilta alustoilta. Valikko on edelleen manuaalisesti avattavissa entiseen tapaan (iOS: "Klassinen >" -kahva; Watch: oma valikkopolku) — ei muutettu.
  - "How to Play" -rivi lisätty Asetuksiin (iOS `SettingsView`, Watch `WatchSettingsView`) — avaa opastuksen uudelleen `isReplay: true` -tilassa ilman että nykyinen peli katoaa (opastus piirretään ZStack-peittona olemassa olevan pelinäkymän päälle, ei `.sheet`, joka korvaisi sisällön; `viewModel`-tilaa ei koskaan lueta tai kirjoiteta opastuksesta).
  - Uudelleen avattuna ("How to Play") viimeinen toiminto on "Takaisin peliin", ei uusi peli — sulkee vain peittokuvan.
  - `showDiceTotal`-oletusarvo (`@AppStorage`) muutettu `false` → `true` sekä `ContentView.swift`:ssä että `SettingsView.swift`:ssä. Koska `@AppStorage`-oletus vaikuttaa vain, jos avainta ei ole koskaan kirjoitettu `UserDefaults`:iin, tämä antaa uusille käyttäjille `true`:n ilman migraatiokoodia, ja säilyttää olemassa olevien käyttäjien nimenomaisesti tallennetun `false`-arvon muuttumattomana.
  - Ajastamattomassa pelissä pistetekstin merkintä muutettu "Score: %lld" → "Remaining: %lld" ("Jäljellä: %lld") + lyhyt selite "Lower is better" ("Mitä pienempi, sen parempi", olemassa oleva käännösavain uudelleenkäytetty). Ajastetun pelin pistetekstiä ei muutettu (näyttää edelleen pisteet erikseen ajasta, olemassa olevan logiikan mukaisesti).
  - Watchin kompaktin otsikon pisteteksti eriytetty tilan mukaan: `currentGameMode.isTimed ? "Score %lld" : "Remaining %lld"`.
- Toteutus:
  - `BoxOfDice/OnboardingViewModel.swift` (uusi, jaettu tiedosto — liitetty Watch-kohteeseen samalla `project.pbxproj`-kaavalla kuin `GameEngine.swift`/`GameSave.swift`): laatat, kiinteä heitto, valinta, vahvistus, `canConfirm`, `step`.
  - `BoxOfDice/OnboardingView.swift` (uusi, iOS): prompti, lauta (`TileView`), nopat (`Dice3DView(isRolling:false, rollDuration:0)`, jo asettuneena näytettäväksi), valinnan summa, vahvistus-/ohitus-/aloitanappi, `#Preview`.
  - `WatchApp/WatchOnboardingView.swift` (uusi, Watch): sama jaettu `OnboardingViewModel`, oma yksinkertainen 26pt-laattanappi (ei `WatchTileButton`-uudelleenkäyttöä, koska se on `private` `WatchContentView.swift`:lle — päätettiin olla nostamatta sen näkyvyyttä tuotantokoodissa tämän tehtävän ulkopuolella), samat käännösavaimet kuin iOS:lla (ei lyhennettyä erillistekstiä Watchille — BOD-013:n ohjeen mukaisesti käytetään samaa lähdetekstiä molemmilla alustoilla, kutistettuna, ei uudelleensanoitettuna).
  - `ContentView.swift`, `WatchContentView.swift`: `onAppear`/vastaava yksinkertaistettu kutsuksi `beginAppLaunchFlow()`; uudet `onboardingContext`-tila, `finishOnboarding(context:)`; opastuspeitto ZStackiin; `SettingsView`/`WatchSettingsView`-kutsuun `onShowHowToPlay`-parametri.
  - `BoxOfDice/GameSettings.swift`, `WatchApp/WatchGameCore.swift`:n `SettingsStorageKey`: uusi `onboardingCompletedOrSkipped`-avain molemmilla alustoilla.
  - `BoxOfDice/fi.lproj/Localizable.strings`, `WatchApp/fi.lproj/Localizable.strings`: uudet englannin/suomen opastustekstit ("Roll the dice"/"Heitä nopat", heittoprompti-malline, "Nice! The goal is to leave as few points as possible."/"Hyvä! Tavoite on jättää mahdollisimman vähän pisteitä.", "Empty board = 0."/"Tyhjä lauta = 0.", "Skip"/"Ohita", "Back to Game"/"Takaisin peliin", "How to Play"/"Näin pelataan", "Remaining: %lld"/"Jäljellä: %lld").
  - `BoxOfDice.xcodeproj/project.pbxproj`: `OnboardingViewModel.swift` lisätty jaettuna tiedostona Watch-kohteeseen; `WatchOnboardingView.swift` lisätty Watch-kohteen `WatchApp`-ryhmään; `BoxOfDiceTests/OnboardingViewModelTests.swift` lisätty `BoxOfDiceTests`-testikohteeseen. Kaikki `xcodeproj`-Ruby-kirjastolla, `plutil -lint` vahvisti validiuden joka kerta.
- Kaksi itse havaittua ja korjattua kaksoisavainvirhettä ennen buildia: `BoxOfDice/fi.lproj/Localizable.strings`:iin lisätty päällekkäinen "Lower is better" (Game Over -näytöllä jo eri suomennoksella oleva avain — poistettu oma lisäys, jätetty kommentti uudelleenkäytöstä) ja `WatchApp/fi.lproj/Localizable.strings`:iin päällekkäinen "Score %lld" (poistettu). Havaittu `grep -oE '^"[^"]+"' tiedosto | sort | uniq -d` -tarkistuksella jokaisen lokalisointierän jälkeen.
- Yksi itse havaittu ja korjattu käännösvirhe: `OnboardingViewModel.swift` puuttui `import Combine`, mikä esti `ObservableObject`-yhdenmukaisuuden ("type 'OnboardingViewModel' does not conform to protocol 'ObservableObject'") sekä iOS- että watchOS-kohteessa. Korjattu lisäämällä `import Combine` (sama kuvio kuin `GameViewModel.swift`:ssä). Vahvistettu korjatuksi toisella oikealla `xcodebuild build` -ajolla.
- Uusi testitiedosto: `BoxOfDiceTests/OnboardingViewModelTests.swift` (8 testiä): aloitustila (9 avointa laattaa, ei heittoa), kiinteä heitto 3+5 aina, toinen heittoyritys ei nollaa kesken olevaa valintaa, yhden laatan esimerkki hyväksytään, 3+5-esimerkki hyväksytään, kolmas listaamaton yhdistelmä (1+2+5=8) hyväksytään ja vain oikeat laatat sulkeutuvat, väärä summa ei mene läpi eikä lukitse tilaa (pelaaja voi jatkaa valintaa), jo suljetun laatan uudelleenpainallus ei tee mitään.
- **Ajetut testit ja buildit (oikea Xcode 27.0 beta, `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`):**
  - `xcodebuild -scheme "BoxOfDice Watch App" -destination 'generic/platform=watchOS Simulator' build` → ensimmäisellä yrityksellä epäonnistui (`import Combine` puuttui) → korjauksen jälkeen **BUILD SUCCEEDED**.
  - `xcodebuild -scheme BoxOfDice -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED**.
  - `xcodebuild test -scheme BoxOfDice -destination 'platform=iOS Simulator,id=<iPhone 17 Pro>'` → **TEST SUCCEEDED, 59/59 testiä** (51 aiempaa + 8 uutta `OnboardingViewModelTests`).
  - Tuore asennus vahvistettu: sovellus poistettu simulaattorista (`xcrun simctl uninstall`), käännetty `.app` asennettu ja käynnistetty uudelleen (`xcrun simctl install`/`launch`) tyhjällä simulaattoridatalla, kuvakaappaus otettu. Kuvakaappaus näyttää: 9 laattaa (1–9) oikein aseteltuna, prompti "Heitä nopat", kaksi asettunutta noppaa, "Heitä"-päänappi, "Ohita"-linkki — täsmää spesifikaatioon (askel 1: lauta + lyhyt prompti, ei erillistä introcarousellia).
  - Manuaalista kosketussyöttöä koko opastuspolulle (heitto → valinta → vahvistus → "Aloita peli") ei ajettu tässä ympäristössä (ei UI-testikehystä); polku on testattu `OnboardingViewModelTests`:llä mallitasolla ja SwiftUI-sidonta on tarkistettu koodista rivi riviltä, ei simulaattorin kosketustapahtumin.
  - **iPad:** ei erillistä iPad-simulaattoria käytettävissä; opastusnäkymä käyttää samaa yleistä asettelua kuin muu pelinäkymä, ei iPad-erikoistapausta — tarkistettu koodista.
  - **watchOS-testit:** `WatchOnboardingView.swift` kääntyy osana Watch-buildia; ei watchOS-simulaattorin ajonaikaista ympäristössä, joten Watch-kohtaista käyttöliittymä- tai käyttäytymisajoa ei tehty (sama tunnettu rajoite kuin BOD-006/BOD-011).
- Saavutettavuus: `OnboardingView.swift`:ssä yksi `.accessibilityElement`/`.accessibilityLabel`-pari lisätty noppariville. Systemaattista VoiceOver-järjestyksen, Reduce Motion -käyttäytymisen tai Dynamic Type -suurten tekstikokojen tarkistusta ei ole tehty kummallakaan alustalla tässä kierroksessa — merkitään avoimeksi puutteeksi, tarkistettava ennen BOD-014:n julkaisuvalmiuskatselmusta.
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: uusi `settings.onboardingCompletedOrSkipped`-avain (Bool) molemmilla alustoilla; `showDiceTotal`-oletusarvon muutos vaikuttaa vain avaimen ensimmäiseen lukuun asennuksissa, joissa sitä ei ole koskaan kirjoitettu — olemassa olevaa dataa ei muuteta eikä migroida.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: ei laitetestiä; ei iPad-simulaattoria; ei watchOS-simulaattoriajoa; ei automatisoitua kosketussyöttöä koko opastuspolulle simulaattorilla (vain aloitusnäkymä kuvakaapattu); systemaattinen saavutettavuustarkistus (VoiceOver-järjestys, Reduce Motion, Dynamic Type XXL) tekemättä.
- Android-vertailu: Ei toteutettu, ei merkitty toteutetuksi. Tavoite Android-vertailua varten: erillinen, pelistä irrallinen opastustila-automaatti; kiinteä ensimmäinen heitto (3+5=8) vain opastuksessa; hyväksy mikä tahansa sääntöjenmukainen summa-8-yhdistelmä; uuden/palaavan käyttäjän tunnistus olemassa olevista signaaleista (ei uutta pakollista tiliä/avainta ainoana signaalina); opastus ei koskaan kirjoita normaaleja tilastoja/tallenteita; opastus uudelleen avattavissa asetuksista tuhoamatta nykyistä peliä; `showDiceTotal`-tyyppisen asetuksen oletusarvon muutos ilman migraatiota (uusi asennus saa uuden oletuksen, olemassa oleva nimenomainen arvo säilyy) on yleistettävissä malli myös Androidille.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-013, iOS + iPadOS + watchOS: viisi uutta kieltä (de/fr/es/it/pt-BR)

Toteutus `docs/CLAUDE_UUDET_OMINAISUUDET.md`:n Prompt 3:n ohjeistuksella, BOD-012:n jälkeen samassa istunnossa. Täysi selvitys, sanasto ja tunnetut puutteet on kirjattu `docs/LOKALISOINTI.md`:ään; tähän vain tiivistelmä ja testinäyttö.

- Tunnus ja alusta: BOD-013, iOS + iPadOS + watchOS
- Tila ennen → jälkeen: Puuttuu (vain fi+en) → Toteutettu (fi + en + 5 uutta kieltä)
- **Tuotepäätökset (kirjattu Android-vertailua varten):** ks. `docs/LOKALISOINTI.md` kokonaisuudessaan — kielikoodit, sanasto, "ei käännetä" -lista (rawValue/avaimet/tuotenimi), alustakohtainen käyttäytymisero (iOS: manuaalinen valitsin + "System"; Watch: seuraa vain laitteen kieltä, ei omaa valitsinta eikä synkronointia iPhonesta).
- Toteutus:
  - Kartoitus ennen toteutusta: `BoxOfDice/GameSettings.swift`:n `L10n`/`AppLanguage`, `WatchApp/WatchGameCore.swift`:n oma `L10n`, molempien `.lproj`-rakenteet, kirjaimellisten `Text("...")`-kutsujen ja `L10n`-kutsujen ero (`grep`-läpikäynti kaikista näkymätiedostoista).
  - Käännökset generoitiin ohjelmallisesti yhdestä avainsanastosta (jokainen olemassa oleva `fi.lproj`-avain käännettynä de/fr/es/it/pt-BR:ksi) erillisillä avainjoukoilla iOS:lle ja Watchille (Watch-tiedostossa 161 avainta, iOS-tiedostossa 183 — Watch ei sisällä esim. moninpelin jakomerkkijonoja tai osaa juhlistusteksteistä). Generointiskripti varmisti ohjelmallisesti, ettei yhtään avainta jäänyt kääntämättä (ei "väärennettyä" englannin täyttöä).
  - Uudet resurssikansiot: `BoxOfDice/{de,fr,es,it,pt-BR}.lproj/Localizable.strings`, `WatchApp/{de,fr,es,it,pt-BR}.lproj/Localizable.strings`.
  - `BoxOfDice/GameSettings.swift`:n `AppLanguage`-enum: viisi uutta `case`ia (`de`, `fr`, `es`, `it`, `ptBR` jonka `rawValue = "pt-BR"`), natiivikieliset näyttönimet ("Deutsch", "Français", "Español", "Italiano", "Português (Brasil)"). Kielivalitsin (`SettingsView.swift`) on jo täysin `ForEach(AppLanguage.allCases)`-pohjainen — ei tarvinnut muuta UI-koodimuutosta.
  - `BoxOfDice.xcodeproj/project.pbxproj`: `knownRegions` laajennettu (`de`, `fr`, `es`, `it`, `"pt-BR"`). iOS:n `BoxOfDice/`-kansio on `PBXFileSystemSynchronizedRootGroup`, joten uudet `.lproj`-kansiot sisältyivät automaattisesti kohteen resursseihin ilman lisämuokkausta. Watchin jaettu `Localizable.strings`-`PBXVariantGroup` sai viisi uutta `PBXFileReference`-lasta `xcodeproj`-Ruby-kirjastolla. `plutil -lint` vahvisti validiuden.
  - `BoxOfDice/StatsView.swift`:n `formattedAverage`: lisätty `.locale(L10n.locale)` `.formatted(.number...)`-kutsuun — SwiftUIn `FormatStyle` ei automaattisesti seuraa `.environment(\.locale)`-ohitusta plain-funktiokutsussa (vain `Text`-näkymä tekee niin), joten manuaalisesti valittu kieli ei olisi vaikuttanut keskiarvon desimaalierottimeen ilman tätä. Watchilla ei ole vastaavaa manuaalista kieliohitusta, joten sen `formatted()`-kutsua ei muutettu.
  - Uusi ajettava resurssitesti `BoxOfDiceTests/LocalizationResourceTests.swift` (kytketty `BoxOfDiceTests`-kohteeseen `xcodeproj`-kirjastolla): lukee kaikki `.lproj/Localizable.strings`-tiedostot suoraan levyltä (`#filePath`-suhteinen polku, ei `Bundle`-riippuvuutta), tarkistaa jokaiselle kielelle avainjoukon täsmäävyyden `fi.lproj`-perustiedostoon nähden (ei puuttuvia eikä ylimääräisiä avaimia), ettei yhdessäkään tiedostossa ole duplikaattiavaimia, että jokaisen jaetun avaimen formaattiplaceholderit (`%lld`/`%d`/`%@` jne.) täsmäävät tyypiltään ja järjestykseltään jokaisessa kielessä, ja että kaikki seitsemän kieltä ovat läsnä molemmilla alustoilla.
- **Ajetut testit ja buildit (oikea Xcode 27.0 beta, `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`):**
  - `xcodebuild -scheme BoxOfDice -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED**.
  - `xcodebuild -scheme "BoxOfDice Watch App" -destination 'generic/platform=watchOS Simulator' build` → **BUILD SUCCEEDED**.
  - `xcodebuild test -scheme BoxOfDice -destination 'platform=iOS Simulator,id=<iPhone 17 Pro>'` → **TEST SUCCEEDED, 62/62 testiä** (59 aiempaa + 3 uutta `LocalizationResourceTests`).
  - Todennettu käännetyistä `.app`-paketeista (`find … -iname "*.lproj"`), että kaikki viisi uutta kielikansiota ovat mukana sekä `BoxOfDice.app`:ssa että `BoxOfDice Watch App.app`:ssa — ei vain lähdekoodikansiossa, vaan oikeasti kopioituna resursseihin buildin kautta.
  - Silmämääräinen simulaattorivarmistus kahdelle kielelle asentamalla tuore build, kirjoittamalla `settings.language`-oletusarvo suoraan sovelluksen `UserDefaults`-domainiin (`xcrun simctl spawn … defaults write`) ja ottamalla kuvakaappaus: **saksa** ("Würfle", "Würfeln", "Überspringen" — aloitusopastuksen teksti oikein) ja **pt-BR** ("Lance os dados", "Lançar", "Pular" — sama näkymä). fr/es/it eivät saaneet vastaavaa ruutukuvavarmistusta tässä kierroksessa (ks. rajoitteet).
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: `settings.language`-avaimen sallittujen arvojen joukko kasvoi (`"de"`, `"fr"`, `"es"`, `"it"`, `"pt-BR"`); vanha arvo (`"en"`/`"fi"`/puuttuva) toimii muuttumattomasti. Ei migraatiota, ei vaikutusta pelitallenteisiin tai tilastoihin.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet (täysi lista `docs/LOKALISOINTI.md`:ssä):
  - **Käännöksiä ei ole tarkistanut äidinkielinen puhuja** — ei merkitty äidinkielisen puhujan tarkistamiksi.
  - fr/es/it: ei silmämääräistä ruutukuvavarmistusta, vain avain-/build-tason varmistus.
  - Ei watchOS-simulaattorin ajonaikaista tässä ympäristössä → yhtään kieltä ei ole nähty käynnissä Watchilla, vain käännetyn binäärin resursseina.
  - Resurssitesti ei todista, että jokainen `Text(...)`-kutsu käyttää lokalisoitua avainta oikein — tämä tarkistettiin erikseen `grep`-läpikäynnillä näkymätiedostoista (kirjaimelliset `Text("...")`-kutsut käyttävät SwiftUIn implisiittistä `LocalizedStringKey`-hakua ja täsmäävät olemassa oleviin `.strings`-avaimiin, mukaan lukien interpoloidut kuten `Text("Tiles: \(score)")` → avain `"Tiles: %lld"`).
  - `.stringsdict`-monikkotukea ei lisätty (olemassa oleva rajoite, ei uusi regressio).
  - Kauppatekstien käännökset eivät kuulu tähän — tehdään BOD-014:ssä.
- Android-vertailu: Ei toteutettu, ei merkitty toteutetuksi. Tavoite Android-vertailua varten: sama 7 kielen joukko (en, fi, de, fr, es, it, pt-BR erikseen — ei yleistä `pt`), `docs/LOKALISOINTI.md`:n sanasto käytettäväksi terminologisena lähtökohtana, saman kielivalinnan pysyvyysperiaate (valinta säilyy uudelleenkäynnistysten yli, ei nollaa peliä/opastusta/tuloksia).
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 10.9.2026 — BOD-013:n jatko: viiden uuden kielen kielioppikatselmus

Käyttäjä pyysi tarkastamaan kaikkien kielten kieliopin. Käytiin läpi de/fr/es/it/pt-BR avain kerrallaan (183 avainta/kieli iOS:llä, 161 Watchilla). Suomea ja englantia ei muutettu — ne olivat olemassa ennen BOD-013:a.

- Tunnus ja alusta: BOD-013 (jatkokorjaus), iOS + iPadOS + watchOS
- Tila ennen → jälkeen: Toteutettu (kääntämättä tarkistamatta) → Toteutettu, kielioppi tarkistettu (ei silti äidinkielisen puhujan katselmusta)
- **Menetelmä:** ennen korjauksia varmistettiin epäselvien avainten todellinen käyttöyhteys koodista, koska suku-/lukumuotoa ei voi päättää pelkästä avaimesta:
  - `Celebration.swift:34` — "On"/"Reduced"/"Off" ovat **vain** `CelebrationLevel`-valitsimen vaihtoehtoja → niiden on kongruoitava sanan "Celebrations" kanssa.
  - `ContentView.swift:894` — "Selected %lld" näyttää valinnan **summan**, ei kappalemäärää.
  - `ContentView.swift:786` — "Last: closed %@" saa pilkulla erotetun **listan** laattoja (1…n) → mikä tahansa yksikkö-/monikkomuotoinen partisiippi olisi väärin osassa tapauksia.
- **Korjatut virheet: 28 kohtaa.** Täysi taulukko (kieli, avain, ennen/jälkeen, virheen laji) on `docs/LOKALISOINTI.md`:n luvussa "Kielioppikatselmus 10.9.2026". Tiivistelmä lajeittain:
  - **Merkitysvirhe (de):** sama sana "Feld" tarkoitti sekä laattaa että pelilautaa — "Empty board = 0." oli "Leeres Feld = 0." eli "tyhjä laatta = 0". Lauta on nyt "Spielfeld" neljässä merkkijonossa; laatta pysyy "Feld".
  - **Merkitysvirhe (it):** "each plays one Classic round" oli "un turno Classico" (yksi vuoro) → "una partita Classica" (kokonainen peli).
  - **Merkitysvirhe (pt-BR):** "9 tiles · short and simple" oli "rápido e simples" (nopea) → "curto e simples"; toisti myös turhaan pelimuodon nimen "Jogo rápido".
  - **Puuttuva artikkeli (fr/es/it/pt-BR):** "Player %lld done!" — englannista kopioitu artikkeliton rakenne on virheellinen kaikissa neljässä romaanisessa kielessä. Nyt "Le joueur…", "¡El jugador…", "Il giocatore…", "O jogador…".
  - **Verbin kongruenssi (es/pt-BR):** "Rolled %lld and %lld" oli yksikössä kahdesta nopasta ("Se lanzó", "Saiu") → "Salieron", "Saíram".
  - **Suvun/luvun kongruenssi (de/fr/es/it/pt-BR):** juhlistusasetuksen "On"/"Off" olivat mask. yksikössä, vaikka "Reduced" oli jo oikein monikossa; "Longest"/"Shortest" (de) olivat feminiinissä vaikka viittaavat sanaan "Spiel"; "9 tiles · short and simple" (es) oli maskuliinissa vaikka viittaa sanaan "partida".
  - **Kongruenssiansan poisto (fr/es/it/pt-BR):** "Last: closed %@" muotoiltiin uudelleen ("Dernier coup :", "Última jugada:", "Ultima mossa:", "Última jogada:") niin ettei partisiipin lukua tarvitse valita ennalta tuntemattomalle laattamäärälle.
  - **Gerundin määritekäyttö (es):** "Dado mostrando %lld" → "Dado con %lld".
  - **Rakennevirhe (fr):** "Aucun coup valide ne reste possible." → "Il ne reste aucun coup valide."
  - **Sanavalinta (pt-BR):** "TARGET" oli "ALVO" (maalitaulu) → "OBJETIVO", yhdenmukaisesti muiden romaanisten kielten kanssa.
  - **Pituus, ei kielioppi (fr/pt-BR):** "Speed Run" lyhennettiin muotoihin "Contre-la-montre" ja "Contra o tempo", koska aiemmat 3–4 sanan nimet olisivat katkenneet Watchin pelitilapainikkeessa.
- **Tietoisesti muuttamatta jätetyt** (kieliopillisesti oikeita, tyylillisesti keskustelunarvoisia — jätetty äidinkielisen katselmuksen päätettäväksi): saksan "Leerung"-perhe, "Große Box Speed" -sekakielisyys, es/it:n ryhmäotsikon ja pelimuodon nimen eri viittausperusta ("Rápida" vs. "Clásico"), sekä monikkomuotojen puute (`%d turns` → "1 turnos") joka on `.stringsdict`-rakenteen puuttumisesta johtuva olemassa oleva rajoite, ei käännösvirhe.
- **Kauppatekstiluonnokset tarkistettiin samalla** (`docs/KAUPPATEKSTIT_LUONNOS.md`, BOD-014): korjattiin 5 kohtaa — saksan "unbegrenzt" (= rajoittamaton, ei "ajastamaton") → "ohne Zeitlimit" kolmessa kohdassa, saksan "leeres Feld" → "leeres Spielfeld" (sama laatta/lauta-sekaannus kuin sovelluksessa), italian "senza tempo" (= ajaton) → "senza limite di tempo" kahdessa kohdassa, espanjan kuvatekstin "sin reloj" → "sin cronómetro".
- Muutetut tiedostot: `BoxOfDice/{de,fr,es,it,pt-BR}.lproj/Localizable.strings`, `WatchApp/{de,fr,es,it,pt-BR}.lproj/Localizable.strings` (10 tiedostoa) sekä `docs/KAUPPATEKSTIT_LUONNOS.md` ja `docs/LOKALISOINTI.md`. Molempien alustojen käännöstiedostot generoitiin uudelleen samasta korjatusta avainsanastosta, joten iOS:n ja Watchin käännökset eivät voi eriytyä toisistaan. Swift-koodia, avaimia tai `project.pbxproj`:ia ei muutettu.
- **Ajetut testit ja buildit (oikea Xcode 27.0 beta):**
  - `plutil -lint` + duplikaattiavaintarkistus kaikille 10 tiedostolle → puhdas.
  - `xcodebuild test -scheme BoxOfDice -destination 'platform=iOS Simulator,id=<iPhone 17 Pro>'` → **TEST SUCCEEDED, 62/62 testiä**. `LocalizationResourceTests` vahvistaa erikseen, että avainjoukot ja formaattiplaceholderit pysyivät ehjinä korjausten jälkeen (kaikissa muutetuissa merkkijonoissa `%lld`/`%d`/`%@` säilyivät tyypiltään ja järjestykseltään).
  - `xcodebuild -scheme "BoxOfDice Watch App" -destination 'generic/platform=watchOS Simulator' build` → **BUILD SUCCEEDED**.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: ei uutta silmämääräistä simulaattoritarkistusta (muutokset koskivat vain merkkijonojen sisältöä, eivät mekanismia; renderöinti oli jo varmistettu de- ja pt-BR-kuvakaappauksin BOD-013:ssa). **Katselmuksen teki tekoäly, ei äidinkielinen puhuja** — käännöksiä ei edelleenkään saa merkitä ihmisen tarkistamiksi.
- Android-vertailu: ei koske. Korjatut kohdat ovat kuitenkin hyvä tarkistuslista, jos Android joskus lokalisoidaan samoille kielille — erityisesti artikkelien pakollisuus romaanisissa kielissä ja se, ettei listamuuttujaan (`%@` = 1…n laattaa) saa liittää lukuun sidottua partisiippia.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 10.9.2026 — Tarkistusraporttien UUDISTUSTEN_TARKISTUS / KIELITARKISTUS löydösten korjaus

Käyttäjä toimitti kaksi tarkistusraporttia (`docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md`, `docs/KIELITARKISTUS_2026-09-10.md`). Korjattu raporttien korjausjärjestyksessä. **Kaikki raporttien löydökset arvioitiin perustelluiksi.**

#### 1. Ensikäynnistyksen taustatallennus (raportin §1) — vakavin, oma regressioni BOD-012:sta

- **Vika:** opastuksen alla oleva `GameViewModel` sisältää oletuksena 12 laatan Classic-pelin. `persistCurrentGame()` tallensi sen taustalle siirryttäessä (`ContentView.swift` scenePhase-käsittelijä) ja `viewModel.revision`-muutoksissa. Koska `beginAppLaunchFlow()` tarkistaa palautettavan tallenteen **ennen** opastuksen tarvetta — tarkoituksella, jotta oikea keskeytynyt peli voittaa aina — seuraava käynnistys palautti Classic-pelin eikä opastusta näytetty koskaan. Uusi pelaaja päätyi 12 laatan peliin jota ei valinnut.
- **Korjaus:** `OnboardingContext` siirretty jaettuun `BoxOfDice/OnboardingViewModel.swift`:iin (se oli aiemmin päällekkäisenä sisäkkäisenä enuminä molemmissa näkymissä) ja sille lisätty sääntö `allowsPersistingUnderlyingGame`: `.firstLaunch` → false, `.replay` → true. `persistCurrentGame()` palaa heti molemmilla alustoilla, kun sääntö kieltää tallennuksen. Asetuksista avatun uusintaopastuksen alla oleva **oikea peli tallentuu edelleen** — sitä ei saanut rikkoa korjatessa. `finishOnboarding` nollaa kontekstin ennen uuden pelin aloitusta, joten opastuksen valmistuminen ja ohitus tallentavat uuden Pikapelin normaalisti.
- **Testinäyttö:** uusi `BoxOfDiceTests/OnboardingLifecycleTests.swift` (4 testiä). Kaksi niistä isännöi oikean `ContentView`in `UIHostingController`-ikkunassa ja vaihtaa scenePhasen active → background, kuten tarkistaja teki. **Varmistettu, että testi myös epäonnistuu ilman korjausta:** suoja poistettiin tilapäisesti ja testi kaatui viestiin `wrote a resumable save (mode=classic, tiles=12)` — täsmälleen raportin havainto. Vastintesti `testBackgroundingWithARealGameStillWritesASave` läpäisee **sekä** korjatulla että korjaamattomalla koodilla, eli se todistaa nimenomaan ettei korjaus mennyt liian pitkälle.
- Watchin vastaava korjaus (`WatchContentView.persistCurrentGame`) on identtinen ja jakaa saman säännön, mutta sitä ei voi ajaa: ei watchOS-simulaattorin ajonaikaista. Jaetun `OnboardingContext`-säännön yksikkötestit kattavat Watchin logiikan siltä osin kuin ilman ajoa voi.

#### 2. Watchin opastuksen puutteet (raportin §2)

- `WatchOnboardingView`: lisätty valintavaiheeseen rivi, joka näyttää valinnan summan ja tavoitesumman (`Selected %lld · Target %lld`, samat avaimet kuin iOS:llä), ja loppuvaiheeseen iOS:ltä puuttunut `Empty board = 0.` -selite. Aiemmin aloittelija näki vain käytöstä poistetun Vahvista-painikkeen näkemättä mitä valinnasta puuttui.
- **Watchissa ei ollut noppasumman näyttöä lainkaan**, joten BOD-012:n uusi `showDiceTotal = true` -oletus ei toteutunut siellä mitenkään. Lisätty: uusi avain `SettingsStorageKey.showDiceTotal` Watchin avaimiin (sama nimi kuin iOS:llä, laitekohtainen — ei WatchConnectivity-synkronointia), summan näyttö `diceAndBadgeRow`iin noppien viereen (pystytila on Watchissa niukin resurssi) vain heiton asetuttua, sekä vastaava kytkin Watchin asetuksiin. Noppien saavutettavuusseloste kertoo nyt summan pelkän "Dice rolled" sijaan.
- Watchin opastuslaatoista puuttui saavutettavuusseloste kokonaan; lisätty `Tile %lld, open/closed` + valittu-tila.

#### 3. Käännösten ja VoiceOverin korjaukset (raportin §3 ja KIELITARKISTUS)

- **de:** `Nur ein Würfel verwenden` → `Nur einen Würfel verwenden, wenn nur noch die Felder 1–6 offen sind` (akkusatiivi). `%d turns` → `%d Züge` (laskuri laskee siirtoja, ei kierroksia).
- **fi:** `Show Dice Total` = "Näytä silmäluku" → **"Näytä noppien summa"** (asetus näyttää summan, ei yhden nopan silmälukua).
- **Kaikki:** `Shortest clear` oli käännetty nopeudeksi (Nopein tyhjennys / Schnellste Leerung / Vidage le plus rapide …), vaikka arvo on `StatsView.shortestClearTurns` eli **siirtojen lukumäärä**. Korjattu kaikissa kuudessa käännöskielessä viittaamaan vähimpään siirtomäärään.
- **Kaikki + lähdeavaimet:** `Tiles: %lld` näytti `viewModel.score`n eli avoimien laattojen **summan**, ei kappalemäärää. Englannin lähdeavaimet muutettu `Tile score: %lld` / `Tile score %lld` (ja `%d`-variantit) ja kutsukohdat päivitetty (`ContentView.headerScoreRow`, `GameOverView`). Watchin ajastettu otsikko sanoi `Score %lld`, mikä ajastetussa pelissä lupaa loppupisteitä; muutettu `Tile score %lld`:ksi, koska aika näytetään erikseen sen alla.
- **Pikapelin yhden nopan selite** ilmaistaan nyt numeroina ("nur noch die Felder 1–6 offen" / "les cases 7 à 9 sont fermées" jne.) eikä epämääräisesti "pienistä laatoista"; suomen versio jätettiin ennalleen ("vain pienet laatat jäljellä") — huom. tämä on raportin tyylisuositus, ei virhe, ja suomen sanamuoto on jo aiemmin katselmoitu.
- **VoiceOver (raportin tärkein kielilöydös):** `BoxOfDice/TileView.swift:49` kutsui avaimia `Tile %lld` / `Closed tile %lld`, joita ei ole käännetty missään — iOS:n laattojen VoiceOver-teksti oli **englanniksi kaikilla kuudella muulla kielellä**, sekä normaalissa pelissä että opastuksessa. Korjattu käyttämään oikeita avaimia `Tile %lld, open` / `Tile %lld, closed`. Watchin vastaava kohta oli jo oikein.
- Uusi löydös korjauksen sivutuotteena: `WatchSupportViews.swift:546` kirjoitti vuoropelin tuloslistan muodossa `"\(index). P\(player)"` — "P" on kielikohtainen lyhenne (de S, fr/es/pt J, it G). Lokalisoitu avaimella `%lld. P%lld`.
- **Testinäyttö:** `LocalizationResourceTests` laajennettu kahdella testillä, jotka tarkistavat että **jokainen avain jota käyttöliittymä pyytää on olemassa** — juuri se, mitä resurssitiedostojen keskinäinen vertailu ei havaitse. Testi jäsentää `L10n.string/format`-kutsut sekä `Text(...)`- ja `.accessibilityLabel(...)`-literaalit ja normalisoi interpolaatiot avainmuotoon.
  - **Ensimmäinen versio testistä ei havainnut vikaa** (regex vaati literaalin heti sulkeen jälkeen, mutta koodissa oli ternaari) — se korjattiin tasapainotettuun sulkujäsennykseen ja **varmistettiin epäonnistuvaksi** palauttamalla `TileView` hetkeksi rikkinäiseen muotoon: testi raportoi `TileView.swift: "Tile %lld"` ja `"Closed tile %lld"` eikä mitään muuta.

#### 4. Opastuksen vaaka-asettelu (raportin §5:n erityinen tarkistuskohde) — raportin epäily osui oikeaan

- **Mitattu:** opastuksen pystysuora sarake tarvitsi 547 pistettä korkeutta. Vaaka-iPhonessa on 390 ja pienimmällä tuetulla näytöllä 375 → **Heitä- ja Ohita-painikkeet jäivät näytön ulkopuolelle eikä mikään vierittänyt**. Ensimmäisellä näytöllä jonka uusi pelaaja näkee tämä on umpikuja, ei kosmeettinen vika.
- **Korjaus:** sisältö `ScrollView`iin, joka venyy koko korkeuteen (`minHeight: proxy.size.height`) — pystysuunnassa sisältö pysyy keskitettynä kuten ennen, ja mikään geometria ei voi enää jäädä saavuttamattomiin. Lisäksi tiivis asettelu matalille näkymille (< 520pt): pienemmät laatat (36×52 vs 44×66), pienemmät nopat, tiiviimmät välit ja marginaalit sekä koristeellisen "Box of Dice" -otsikon piilotus. Mitattu tulos: sisältö 360,3pt → mahtuu sekä 390:een että 375:een **ilman vieritystä**; vieritys jää vain turvaverkoksi (esim. suurimmat tekstikoot).
- **Testinäyttö:** uusi `BoxOfDiceTests/OnboardingLayoutTests.swift` mittaa seitsemän geometriaa (iPhone pysty/vaaka, pienin tuettu pysty/vaaka, iPad pysty/vaaka, iPadin jaettu näkymä).
  - **Testin ensimmäinen versio meni läpi väärästä syystä:** `sizeThatFits` palauttaa ScrollView'n oman rajatun korkeuden, joten se sanoo "mahtuu" riippumatta ylivuodosta. Havaittu renderöimällä näkymä oikeasti kuvaksi — napit näkyivät leikattuina vaikka testi oli vihreä. Korjattu mittaamaan `contentSize` vs. näkyvä alue.
  - Toinen harha matkan varrella: synteettinen testi-ikkuna antoi ScrollView'lle 54pt:n `adjustedContentInset.top`in, jota oikeassa sovelluksessa ei ole, koska `ContentView` esittää opastuksen `.ignoresSafeArea()`-modifierilla. Mittaus tehdään nyt samalla modifierilla, jolloin luku kuvaa sovellusta eikä testikehystä.
- **iPad-tarkistus tehty** (ks. seuraava kohta): tuore asennus, opastus renderöityy oikein pystyasennossa ennen ja jälkeen asettelumuutoksen.

#### Korjaus aiempaan lokimerkintääni: iPad-simulaattori

Aiemmissa BOD-011/012/014-merkinnöissä väitin, ettei tässä ympäristössä ole iPad-simulaattoria. **Väite oli virheellinen** — tarkistaja huomautti siitä aiheellisesti. Olin suodattanut laitelistan hakusanalla "iphone" ja päätellyt siitä väärin. Ympäristössä on 43 iPad-laitetyyppiä luotavissa, ja iPad-simulaattoreita oli myös valmiina. Tässä korjauksessa luotiin oma iPad Pro 11" -simulaattori, ajettiin tuore asennus ja otettiin kuvakaappaukset (ennen ja jälkeen asettelumuutoksen), minkä jälkeen simulaattori poistettiin. Käyttäjän omiin simulaattoreihin ei koskettu. **Tarkistus oli siis tekemättä, ei ympäristön vuoksi mahdoton** — vanhat merkinnät jätetään paikoilleen historiaksi, mutta tämä merkintä kumoaa niiden iPad-väitteen.

#### Ajetut testit ja buildit (oikea Xcode 27.0 beta)

- `xcodebuild test -scheme BoxOfDice -destination 'platform=iOS Simulator,id=<iPhone 17 Pro>'` → **TEST SUCCEEDED, 70/70 testiä** (62 aiempaa + 4 `OnboardingLifecycleTests` + 2 `OnboardingLayoutTests` + 2 uutta `LocalizationResourceTests`-testiä).
- `xcodebuild -scheme "BoxOfDice Watch App" -destination 'generic/platform=watchOS Simulator' build` → **BUILD SUCCEEDED**.
- iPad Pro 11" -simulaattori: tuore asennus + käynnistys + kuvakaappaus kahdesti (ennen/jälkeen asettelumuutoksen) — opastus renderöityy oikein, ei regressiota.
- Vaaka-asettelu varmistettu sekä mittaamalla että renderöimällä näkymä kuvaksi kokoon 667×375 — koko sisältö painikkeineen näkyvissä.
- 12 `.strings`-tiedoston `plutil -lint`, duplikaattiavaimet ja formaattiparametrit: ei virheitä.

#### Ajamatta jääneet tarkistukset

- **Ei watchOS-ajoa** (ei simulaattorin ajonaikaista): Watchin summat, opastuksen uusi rivi, noppasumma ja asetuskytkin on varmistettu vain kääntymällä ja koodista.
- Koko opastusketjua (heitto → valinta → vahvistus → Aloita peli) ei ole ajettu kosketussyötteinä; se on katettu malli- ja elinkaaritesteillä sekä koodin lukemisella.
- iPadin vaaka-asentoa ei kuvakaapattu simulaattorista (simulaattorin kierto vaatii GUI:n, jota tässä ympäristössä ei ajeta); iPad-vaaka on katettu mittaustestillä.
- VoiceOveria ei ole kuunneltu laitteella — korjaus varmistettu avaintasolla ja testillä, ei ruudunlukijalla.
- Raportin §5:n huomio siitä, ettei `QuickGameTests`in vanha Classic-tallennus todista aidon julkaisuversiotallenteen migraatiota, pitää paikkansa; sitä ei ole korjattu tässä ja se vaatisi aidon vanhan tallenteen.

#### Android-vertailu

Ei tutkittu, ei muutettu. Hyväksymiskriteerit vertailua varten: opastuksen aikana ei saa kirjoittaa normaalia pelitallennetta; uusintaopastuksen alla oleva oikea peli on säilyttävä; laattojen ruudunlukutekstien on tultava käännösresursseista eikä koodiin kirjoitetuista englanninkielisistä merkkijonoista; opastuksen toimintojen on oltava saavutettavissa myös matalassa vaakanäkymässä.

- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 10.9.2026 — Suomen ja englannin kielioppikatselmus

Käyttäjän jatkopyyntö edellisen merkinnän jälkeen. Molemmat kielet olivat olemassa ennen BOD-013:a, joten ne katselmoitiin erikseen ja eri kynnyksellä: englanti on kehityskieli, jossa **avain on samalla näkyvä teksti**, joten englannin sanamuodon muuttaminen tarkoittaisi avaimen muuttamista seitsemässä resurssitiedostossa ja SwiftUI-kutsukohdassa.

- Tunnus ja alusta: BOD-013 (jatkokorjaus), iOS + iPadOS + watchOS
- **Korjatut suomen kohdat: 7** (täysi taulukko `docs/LOKALISOINTI.md`:n luvussa "Suomi ja englanti"):
  - **Oikeinkirjoitusvirhe, 3 merkkijonoa:** jaettavissa tulosteksteissä luki "Noppalauta **-pelissä**" välilyönnin kanssa → "Noppalauta-pelissä". Erisnimen ja yleisnimen yhdistelmä kirjoitetaan yhdysmerkillä ilman välilyöntiä.
  - `Selected %lld`/`%d`: "Valittu %lld" → "Valinta %lld" — arvo on valittujen laattojen **summa**, ei kappalemäärä (sama korjaus kuin viidessä muussa kielessä edellisessä katselmuksessa).
  - `Last: closed %@`: "Viimeksi: suljettu %@" → "Viimeksi suljettu: %@" (kaksoispiste katkaisi lauseen väärästä kohdasta).
  - `No data yet — …`: "Ei dataa vielä" → "Ei vielä dataa" (englannin sanajärjestyksen käännöslaina).
  - `One die now — …`: "Yksi noppa nyt" → "Nyt yksi noppa" (sama; BOD-011:ssä lisätty teksti).
  - Suomessa **ei** ollut romaanisten kielten kongruenssivirheitä (ei suvun mukaista taivutusta) eikä saksan laatta/lauta-sekaannusta — suomi erottaa "laatta", "lauta" ja "laatikko" oikein.
- **Englanti: ei yhtään varsinaista kielioppivirhettä.** Käyttöliittymäenglanti on paikoin sähkösanomatyylistä ("Pass to next player", "Selected %lld") mutta se on käyttöliittymässä normaalia, ei virheellistä. Englannin avaimia ei muutettu.
- **Löydetty, korjaamatta jätetty (uusi tunnus BOD-015):** `"%d pts"` tuottaa arvolla 1 tekstin **"1 pts"** (`BoxOfDice/PassAndPlayViews.swift:207`, vuoropelin tulosnäkymä). Pistemäärä 1 on saavutettavissa (vain laatta 1 jää auki), joten virhe näkyy oikeasti. Sama koskee ranskaa, espanjaa ja pt-BR:ää; suomi ("1 pist."), saksa ("1 Pkt.") ja italia ("1 pt") ovat oikein, koska lyhenne ei taivu. `"%d turns"` on sama rakenne, mutta arvo 1 ei ole käytännössä saavutettavissa. **Ei korjattu**, koska oikea ratkaisu (`.stringsdict`) on rakenteellinen muutos, joka aiemmin rajattiin tietoisesti ulos ja jolla on kolme ei-triviaalia seurausta: englanti tarvitsisi puuttuvan `en.lproj`-kansion; `L10n.string` oikaisee englannin erikseen eikä lue bundlea lainkaan (koodimuutos tarvitaan); Watchin `.stringsdict` vaatisi oman `PBXVariantGroup`-kytkennän ja `LocalizationResourceTests`:n laajennuksen (nyt se lukee vain `.strings`-tiedostoja). Perustelu ja työn laajuus: `docs/LOKALISOINTI.md`.
- **Dokumentaatiovirhe korjattu:** `docs/LOKALISOINTI.md` väitti, että tuotenimi "Box of Dice" pysyy muuttumattomana **kaikissa** kielissä. Suomenkielinen resurssi kääntää sen ("Noppalauta") — tämä on BOD-011:tä edeltävä olemassa oleva päätös, jota **ei muutettu** (käyttäjän aiempia valintoja ei kumota sivutuotteena). Dokumentti kertoo nyt poikkeuksen ja sen ristiriidan `docs/CLAUDE_UUDET_OMINAISUUDET.md`:n ohjeen kanssa; **päätettävä erikseen** ennen julkaisua. Huom. myös `docs/KAUPPATEKSTIT_LUONNOS.md` käyttää suomeksi nimeä "Box of Dice", mikä ei vastaa sovelluksen nykyistä suomenkielistä käyttöliittymää.
- Muutetut tiedostot: `BoxOfDice/fi.lproj/Localizable.strings`, `WatchApp/fi.lproj/Localizable.strings`, `docs/LOKALISOINTI.md`. Swift-koodia, avaimia, muita kieliä tai `project.pbxproj`:ia ei muutettu.
- **Ajetut testit ja buildit (oikea Xcode 27.0 beta):** `plutil -lint` + duplikaattitarkistus molemmille suomen tiedostoille → puhdas. `xcodebuild test -scheme BoxOfDice` → **TEST SUCCEEDED, 62/62 testiä**. `xcodebuild -scheme "BoxOfDice Watch App"` → **BUILD SUCCEEDED**.
- Ajamatta jääneet tarkistukset: ei silmämääräistä simulaattoritarkistusta (vain merkkijonojen sisältö muuttui, ei mekanismi). Jaettavien tulostekstien ("Noppalauta-pelissä") näkymistä oikein jakolomakkeessa ei testattu laitteella.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-014, iOS + iPadOS + watchOS: BOD-011–013 kokonaiskatselmus ja julkaisuvalmistelu (paikalliset tiedostot)

Toteutus `docs/CLAUDE_UUDET_OMINAISUUDET.md`:n Prompt 4:n ohjeistuksella, BOD-013:n jälkeen samassa istunnossa. **Ei julkaisua eikä kauppadatan muutosta** — vain paikallisten tiedostojen katselmus ja luonnokset, kuten pyydetty.

- Tunnus ja alusta: BOD-014, iOS + iPadOS + watchOS
- **Katselmusmatriisi ja tarkkuustaso (mikä ajettu laitteella/simulaattorilla vs. tarkistettu vain koodista vs. jäänyt varmistamatta):**

| Katselmuskohta | Tarkkuustaso |
|---|---|
| Uusi käyttäjä → opastus → oikea Pikapeli → tulos → toinen peli | Osittain laitteella: tuore asennus + opastuksen ensimmäinen näyttö kuvakaapattu (saksa, pt-BR, XXXL-tekstikoko). Koko polku heitosta tulokseen ja toiseen peliin **ei** ajettu kosketussyötöin (ei UI-testikehystä) — varmistettu `OnboardingViewModelTests`+`QuickGameTests`-yksikkötesteillä ja koodin lukemisella (`finishOnboarding`, `beginAppLaunchFlow`). |
| Palaava käyttäjä → vanhan pelin palautus → tilan vaihto Pikapeliin | Koodista + yksikkötesteistä (`GameRestoreTests`, `QuickGameTests`). Ei laiteajoa. |
| Vanha Classic-tallenne ja nykyiset ennätykset säilyvät | **Ajettu**: `QuickGameTests.testOldClassicSaveStillRestoresAsATwelveTileGame`, `testQuickGameResultAndBestScoreDoNotAffectClassicStatistics` — todellinen `xcodebuild test`. |
| Opastuksen ohitus, keskeytys, uudelleenavaus asetuksista | Koodista (ZStack-peitto, `onboardingCompletedOrSkipped`-logiikka) + `OnboardingViewModelTests`. Ei UI-tason ajoa keskeytys-/uudelleenavausskenaarioille. |
| Laattojen 7–9 sulkeminen ja yhden nopan sääntö Pikapelissä | **Ajettu**: `QuickGameTests.testSwitchesToOneDieOnceTilesSevenThroughNineAreAllClosed`, `testStaysAtTwoDiceIfAnyOfSevenEightNineIsStillOpen`. |
| Kaikki seitsemän kieltä iOS:lla ja Watchilla | **Ajettu**: `LocalizationResourceTests` (avainjoukko, duplikaatit, placeholderit) + molempien kohteiden build, jossa kaikki 5 uutta `.lproj`-kansiota todennettu mukana käännetyssä paketissa. Silmämääräinen kuvakaappaus vain kahdelle kielelle (de, pt-BR); fr/es/it vain avain-/build-tasolla. Watch: ei watchOS-simulaattorin ajonaikaista → ei yhtään kieltä nähty käynnissä Watchilla. |
| Suuret tekstikoot ja pitkä saksankielinen teksti pienimmällä tuetulla näytöllä | **Osittain ajettu**: `xcrun simctl ui … content_size accessibility-extra-extra-extra-large` + saksa + kuvakaappaus opastuksen ensimmäisestä näytöstä — ei leikkautumista, painikkeet kasvoivat oikein tämän kierroksen korjauksen jälkeen (ks. alla). **Ei pienintä tuettua näyttöä** — tässä ympäristössä on saatavilla vain "iPhone 17 Pro" -simulaattori (`xcrun simctl list devices available`), ei esim. iPhone SE:tä. |
| iPad ja iPhone eri suunnissa | **Ei ajettu** — ei iPad-simulaattoria tässä ympäristössä (sama rajoite kuin BOD-011/012). Tarkistettu vain koodista: laattaruudukon sarakemäärä (`columnsCount`) on jo yleinen kaava, ei Pikapeli-/opastuskohtaista erikoistapausta. |
| Watchin rajallinen näyttötila | Koodista (kompakti asettelu, `ScrollView`, pienemmät fontit `WatchOnboardingView.swift`:ssä) — ei laite-/simulaattoriajoa. |
| BOD-001–005-regressiotestit + uudet ominaisuustestit | **Ajettu**: koko `BoxOfDiceTests`-sarja, 62/62 testiä, todellinen `xcodebuild test` (ks. alla). |

- **Tässä katselmuksessa löydetty ja korjattu bugi:** `BoxOfDice/OnboardingView.swift`:n kolme painiketta ("Roll"/"Confirm"/"Start Game"/"Back to Game") käyttivät kiinteää `.frame(height:)`-korkeutta yhdessä Dynamic Type -skaalautuvan fontin (`GameTypography.button`, `.custom(..., relativeTo: .headline)`) kanssa — suurilla esteettömyys-tekstikoilla (esim. Accessibility XXXL) ja pidemmällä kielellä (saksa) painikkeen teksti olisi voinut rivittyä ja leikkautua kiinteän korkeuden sisällä. Korjattu vaihtamalla `.frame(height:)` → `.frame(minHeight:)` kaikissa kolmessa kohdassa, jolloin painike kasvaa tarvittaessa sen sijaan että leikkaa tekstin. Vahvistettu kuvakaappauksella (saksa, Accessibility XXXL) — teksti mahtuu, ei leikkautumista. Rajattu koskemaan vain BOD-012:n uusia opastusnäkymiä, ei sovelluksen muita, jo olemassa olevia painikkeita (ei laajaa esteettömyyskorjausta koko sovellukseen tässä kierroksessa — merkitty jatkotarpeeksi alla).
- **Ajetut testit ja buildit (oikea Xcode 27.0 beta):**
  - `xcodebuild -scheme BoxOfDice -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED** (korjauksen jälkeen).
  - `xcodebuild test -scheme BoxOfDice -destination 'platform=iOS Simulator,id=<iPhone 17 Pro>'` → **TEST SUCCEEDED, 62/62 testiä** (uudelleenajo korjauksen jälkeen, ei regressiota).
  - `xcrun simctl`-pohjainen silmämääräinen tarkistus: saksa + Accessibility XXXL -tekstikoko opastuksen ensimmäisellä näytöllä — painikkeet ja teksti mahtuvat oikein.
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: ei uusia.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: ks. katselmusmatriisi yllä; lisäksi App Store- ja Google Play -kauppatekstien merkkimäärärajoja ja lopullista buildia vasten tarkistamista ei ole tehty (ks. `docs/KAUPPATEKSTIT_LUONNOS.md`).
- **Uusi tiedosto:** `docs/KAUPPATEKSTIT_LUONNOS.md` — lyhyt kuvaus Pikapelistä ja opastuksesta, kolme kuvakaappaustekstiä ja What's New -luonnos kaikilla seitsemällä kielellä. Merkitty selvästi luonnokseksi; ei väitteitä päivän haasteesta, pilvisynkronoinnista, premium-ominaisuuksista tai taatusta onnistumisesta; ei Android-mainintoja julkaistuna tai toteutettuna.
- **docs/LOKALISOINTI.md ja docs/KORJAUSSEURANTA.md päivitetty** tämän katselmuksen löydöksillä (tämä merkintä).
- **Yhteenveto Android-vertailua varten (kaikki BOD-011–013 yhdessä):**
  - `quickGame`-pelimuodon säännöt: 9 laattaa, 2 noppaa alussa, 1 noppa kun laatat 7–9 suljettu, mikä tahansa summaa vastaava avointen laattojen yhdistelmä, ei aikapisteitä, tulos = jäljelle jäävien laattojen summa, oma ennätys/keskiarvo erillään Classicista.
  - Opastuksen tilat: `waitingForRoll` → `selecting` → `resolved`; kiinteä ensimmäinen heitto (3+5=8) vain opastuksessa; uuden/palaavan käyttäjän tunnistus olemassa olevista signaaleista (`hasSelectedInitialGameMode`, pelien määrä, tallenne) ilman pakollista uutta tiliavainta; opastus ei koskaan kirjoita normaaleja tilastoja/tallenteita; palautettavissa oleva peli voittaa aina opastuksen.
  - Oletusasetusten muutokset ilman migraatiota: `showDiceTotal` uusilla asennuksilla `true`, olemassa oleva nimenomainen `false` säilyy (AppStorage-oletusarvon semantiikka, ei migraatiokoodia).
  - Kielikoodit: `en` (kehityskieli, ei erillistä resurssikansiota), `fi`, `de`, `fr`, `es`, `it`, `pt-BR` (ei yleistä `pt`). Täysi sanasto ja per-kieli/alusta-tila `docs/LOKALISOINTI.md`:ssä.
  - Hyväksymistestit, jotka Android-toteutuksen tulisi myös läpäistä: `BoxOfDiceTests/QuickGameTests.swift` (8 testiä), `BoxOfDiceTests/OnboardingViewModelTests.swift` (8 testiä), `BoxOfDiceTests/LocalizationResourceTests.swift` (3 testiä, resurssien eheys — ei sovellu sellaisenaan Androidin resurssijärjestelmään, mutta samat tarkistuskohdat: ei puuttuvia/duplikaatti-/epäyhtenäisiä avaimia).
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — R1–R4-löydösten korjaus (docs/KORJAUSTEN_TARKISTUS_2026-09-09.md)

Käyttäjä pyysi tarkistamaan riippumattoman tarkistusraportin löydökset R1–R4 ja korjaamaan ne, jos itsekin arvioin sen tarpeelliseksi. Arvioin kaikki neljä perustelluiksi ja korjasin kaikki.

- **R1 — testit eivät kuuluneet Xcode-testikohteeseen.** Lisätty projektiin oikeat testikohteet `BoxOfDiceTests` (iOS, riippuu `BoxOfDice`-kohteesta, `TEST_HOST`/`BUNDLE_LOADER` asetettu) ja `BoxOfDice Watch AppTests` (watchOS, riippuu `BoxOfDice Watch App` -kohteesta). Toteutettu Ruby `xcodeproj`-kirjastolla (versio 1.28.1, todettu asennetuksi tällä koneella) suoraan `project.pbxproj`:iin käsin kirjoittamisen sijaan — pienempi riski virheelliseen pbxproj-syntaksiin. Molempien skeemojen (`BoxOfDice.xcscheme`, `BoxOfDice Watch App.xcscheme`) `TestAction`-osioihin lisätty puuttunut `<Testables>`-viittaus uuteen testikohteeseen. **`xcodebuild test -scheme BoxOfDice` ajettiin oikeasti simulaattorilla (iPhone 17 Pro, iOS 27 Simulator) — TEST SUCCEEDED, 43/43 testiä läpäisi**, käyttäen projektin OMAA testikohdetta (ei tilapäistä SPM-pakettia). `BoxOfDice Watch AppTests` -kohde kääntyy (`xcodebuild build -destination 'generic/platform=watchOS Simulator'` → BUILD SUCCEEDED), mutta tässä ympäristössä ei ole asennettuna watchOS-simulaattorin ajonaikaista (`xcrun simctl list runtimes` näyttää vain iOS 27:n) — `xcodebuild test` Watch-skeemalle epäonnistuu laitteen puutteeseen, ei koodi- tai konfiguraatiovirheeseen (virheviesti liitteenä alla). Watchin testilogiikka on sen sijaan varmistettu ajamalla samat testit oikealla Xcode/XCTest-toolchainilla tilapäisessä macOS-SPM-paketissa (10/10 läpäisi, ks. BOD-006-merkintä) — tämä ei ole täysin sama asia kuin ajo projektin omassa watchOS-testikohteessa, mutta lähellä.
- **R2 — käännösvirheet testeissä.** Korjattu edellisessä istunnossa (`NoOpGameFeedback()` → `.shared`; Watchin `GameSettings`-kutsulle `diceMode`/`moveRule`). Vahvistettu pysyvän korjattuna: molemmat käännösvirheet poissa, testit kääntyvät ja läpäisevät edellä mainitussa oikeassa Xcode-ajossa.
- **R3 — kaksoiskirjaustesti ei testannut itse suojaa.** Eriytetty `ContentView`/`WatchContentView`:n `@State`-Bool-suoja omaksi puhtaaksi, testattavaksi tyypiksi `GameResultRecordGuard` (uusi jaettu tiedosto `BoxOfDice/GameResultRecordGuard.swift`, liitetty Watch-kohteeseen samalla `project.pbxproj`-kaavalla kuin `GameEngine.swift`). `ContentView.handleGameOver` ja `WatchContentView.handleGameStateChange` kutsuvat nyt `resultRecordGuard.recordIfNeeded()`:ia raa'an Bool-tarkistuksen sijaan; kaikki `newGame`/`restore`-kohdat kutsuvat `resultRecordGuard.reset()`:ia. Uusi `BoxOfDiceTests/GameResultRecordGuardTests.swift` (3 testiä) testaa suojan itsensä — mukaan lukien nimenomaan pyydetyn skenaarion (kaksi samaa "peli päättyi" -tapahtumaa samalle pelille, sitten uusi peli). Vanhan `GameStatisticsRecorderTests.testCallingTwiceForTheSameResultDoublesEveryCount`:n kommentti korjattu selittämään rehellisesti, mitä se todistaa ja mitä ei.
- **R4 — loppuajan testi ei erottelisi vanhaa ja uutta toteutusta.** Lisätty molempiin `GameViewModel`-luokkiin injektoitava kello (`var now: () -> Date = Date.init`), joka korvaa kaikki suorat `Date()`-kutsut ajastinpolulla; tuotantokäyttäytyminen säilyy identtisenä (oletusarvo on todellinen kello). Uusi testi (`testElapsedSecondsFinalizedFromClockNotFromAStalePeriodicTick`, molemmilla alustoilla) jäädyttää kellon, odottaa yhden todellisen jaksoittaisen päivityksen tapahtuvan (kirjaa "vanhentuneen" 0:n), hypättää kellon eteenpäin ja päättää pelin **samassa synkronisessa askeleessa** (ei `await`-kohtaa välissä) — tämä poistaa ajoituskilpailun kokonaan, koska mikään muu ei voi ajautua pääaktorin väliin. **Vahvistettu, että testi myös epäonnistuu**, kun `stopTimer()`:n suora loppuajan laskenta poistetaan tilapäisestä kopiosta (simuloitu R4:n pyytämä regressiotarkistus): `XCTAssertEqual failed: ("0") is not equal to ("1")`.
- Kaikki korjaukset ajettu läpäisemään todellisella Xcode 27.0 (beta) -toolchainilla (`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`), ei vain `swiftc`-erillisajoilla.
- Ei muutettu tuotantokäyttäytymistä miltään osin — kaikki neljä ovat testi-/projektirakenteen korjauksia.
- Commit / julkaisu: ei tehty.

### 9.9.2026 — BOD-006, iOS + watchOS: keskeneräisen pelin tallennus ja palautus; R2:n korjaus

- Päivämäärä: 9.9.2026
- Tunnus ja alusta: BOD-006, iOS ja watchOS. Sivutuotteena korjattu myös riippumattoman tarkistuksen (ks. alla oleva 9.9.2026-merkintä ja `KORJAUSTEN_TARKISTUS_2026-09-09.md`) löydös **R2** (kaksi testitiedostoa eivät kääntyneet nykyisiä rajapintoja vasten).
- Tila ennen → jälkeen: Koodihavainto → Toteutettu, varmistamatta (molemmat alustat)
- Ongelman varmistus: Aktiivinen peli oli vain `GameEngine`/`GameViewModel`-muistissa; asetukset (`SettingsStorageKey`) ja tilastot (`StatisticsStorageKey`) tallentuivat `UserDefaults`:iin, mutta kesken oleva pelitila (laatat, nopat, valinta, pelivaihe, siirtohistoria, siemenellisen generaattorin tila, moninpelin vuoro/tulokset) katosi sovelluksen sulkeutuessa. Vahvistettu koodin lukemisesta.
- Toteutus:
  - `GameEngine`, `Tile`, `MoveRecord`, `GameState`, `DiceMode`, `MoveRule`, `GameSettings`, `SeededRandomNumberGenerator` ja `GameMode` (molemmat alustakohtaiset kopiot) saivat `Codable`-yhteensopivuuden. `MoveRecord.id` on tarkoituksella pois tallenteesta (`CodingKeys`) — se on vain paikallinen SwiftUI-tunniste, ei pelitilaa.
  - Uusi jaettu tiedosto `BoxOfDice/GameSave.swift` (liitetty myös Watch-kohteeseen samalla `project.pbxproj`-kaavalla kuin `GameEngine.swift`): `SavedGame` (versioitu — `schemaVersion`-kenttä — Codable-tallenne, joka sisältää pelimuodon, koko `GameEngine`-tilan, kesken olevan (ei vielä sitoutuneen) heiton nopat, ajastetun pelin aloitusajan sekä moninpelin pelaajamäärän/vuoron/tulokset) ja `GameSaveStore` (lataa/tallenna/tyhjennä). Tallennus `Data.write(to:options:.atomic)`:lla omaan `Application Support`-alihakemistoon; ei Core Dataa, ei pilvisynkronointia.
  - `GameSaveStore.load()` palauttaa `nil` jokaisessa virhetilanteessa (puuttuva tiedosto, lukuvirhe, virheellinen/tunnistamaton JSON) `try?`:lla — ei koskaan kaada sovellusta.
  - `GameViewModel` (molemmat alustat) sai `restore(engine:pendingRollDice:gameStartTime:isTimed:)`-metodin: peruuttaa kesken olevat heitto-/ajastintehtävät (Watchilla myös `gameGeneration`-sukupolven kasvatus, ks. BOD-001), ottaa tallennetun `GameEngine`-tilan käyttöön, **sitoo kesken jääneen (jo arvotun, ei vielä sitoutuneen) heiton suoraan `engine.roll(dice:)`:llä ilman animaatiota** — ei uutta arvontaa, ei jää "heitossa"-tilaan lukkoon — ja käynnistää ajastimen uudelleen alkuperäisestä (mahdollisesti kauan sitten, jopa ennen uudelleenkäynnistystä alkaneesta) `gameStartTime`-ajankohdasta, jolloin taustalla/suljettuna kulunut aika lasketaan mukaan.
  - Uusi `revision`-laskuri (`@Published`) molemmissa `GameViewModel`-luokissa kasvaa jokaisen merkityksellisen toiminnon (heiton sitoutuminen, laatan valinta, vahvistus, kumoaminen, uusi peli, palautus) jälkeen. `ContentView`/`WatchContentView` tarkkailee sitä (`onChange`) ja tallentaa pelin — tämä on yksinkertaisempi ja kattavampi kuin erillisten julkaistujen kenttien tarkkailu, koska se ei voi unohtaa mitään toimintopistettä.
  - `@Environment(\.scenePhase)` + `.onChange(of: scenePhase)` tallentaa pelin myös sovelluksen siirtyessä taustalle — mukaan lukien kesken olevan heiton nopat, jos animaatio oli juuri silloin käynnissä.
  - Käynnistyksessä (`onAppear`) yritetään ensin `restoreSavedGameIfAny()`; vain jos tallennetta ei ole (tai se on vioittunut), aloitetaan uusi peli entiseen tapaan.
  - Päättynyt peli (`gameState == .gameOver`) ei koskaan tallennu resumoitavana — `persistCurrentGame()` kutsuu tällöin `GameSaveStore.clear()`in sijaan tallennuksen. Tämä takaa rakenteellisesti, että päättyneen pelin palautus ei voi kirjata tilastoja uudestaan: palautettavaa tallennetta ei koskaan ole olemassa päättyneelle pelille.
  - Uusi peli (`beginNewViewModelGame`) korvaa edellisen tallenteen välittömästi.
  - **R2:n korjaus** (ei osa alkuperäistä BOD-006-pyyntöä, mutta sivutuote tämän istunnon aikaisesta oikeiden Xcode-työkalujen käytöstä): `BoxOfDiceTests/GameViewModelTimedAnimationTests.swift` käytti `NoOpGameFeedback()`-kutsua yksityiseen alustajaan; korjattu `NoOpGameFeedback.shared`. `WatchAppTests/WatchGameCoreRegressionTests.swift:103` kutsui `GameSettings(tileCount:baseDiceCount:)`-alustajaa puuttuvin `diceMode`/`moveRule`-argumentein; lisätty `.alwaysTwoDice, .anyCombination`. Molemmat vahvistettiin korjatuiksi ajamalla testit oikeasti (ks. alla).
- Muutetut/uudet tiedostot:
  - `BoxOfDice/GameEngine.swift` (Codable-konformanssit), `BoxOfDice/GameMode.swift`, `WatchApp/WatchGameCore.swift` (`GameMode`: Codable; `GameViewModel`: `revision`, `pendingRollDiceForSaving`, `engineSnapshot`, `gameStartTimeForSaving`, `restore(...)`, `beginTimerLoop()`-refaktorointi)
  - `BoxOfDice/GameSave.swift` (uusi, jaettu)
  - `BoxOfDice/GameViewModel.swift` (samat lisäykset kuin Watchille)
  - `BoxOfDice/ContentView.swift`, `WatchApp/WatchContentView.swift` (`scenePhase`, `restoreSavedGameIfAny()`, `persistCurrentGame()`, `beginNewViewModelGame` tallentaa nyt myös)
  - `BoxOfDice.xcodeproj/project.pbxproj` (`GameSave.swift`:lle sama eksplisiittinen Watch-kohteen jäsenyys kuin `GameEngine.swift`:lle; `plutil -lint` vahvisti validiuden)
  - `BoxOfDiceTests/GameSaveStoreTests.swift`, `BoxOfDiceTests/GameRestoreTests.swift`, `WatchAppTests/WatchGameRestoreTests.swift` (uudet testit)
  - `BoxOfDiceTests/GameViewModelTimedAnimationTests.swift`, `WatchAppTests/WatchGameCoreRegressionTests.swift` (R2-korjaus)
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Uusi tiedostomuotoinen tallenne (`active_game.json` sovelluksen Application Support -hakemistossa), ei UserDefaults-avaimia. Ei vaikutusta olemassa oleviin asetus-/tilastoavaimiin.
- **Ajetut testit ja buildit — tällä kertaa oikealla Xcodella** (`/Applications/Xcode-beta.app`, Xcode 27.0/27A5252f, käytössä `DEVELOPER_DIR`-ympäristömuuttujalla; aiemmissa BOD-001–005-merkinnöissä käytettiin vain `swiftc`-erillisajoja komentorivi-työkaluilla, koska Xcode-betaa ei ollut tunnistettu tässä istunnossa):
  - `xcodebuild -scheme BoxOfDice -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED**.
  - `xcodebuild -scheme "BoxOfDice Watch App" -destination 'generic/platform=watchOS Simulator' build` → **BUILD SUCCEEDED**.
  - Tuotantolähteet ja testit koottiin tilapäisiin macOS-SPM-paketteihin (ei muutoksia varsinaiseen Xcode-projektiin) ja ajettiin `swift test`:llä samalla `DEVELOPER_DIR`:llä — täysi Xcode-toolchain, oikea XCTest, ei manuaalisia `swiftc`-ajureita:
    - Moottori/haku/tilastot (pelkkä Foundation): **32/32 läpäisi** — `GameEngineTests` 12, `GameEngineSearchTests` 5, `GameStatisticsRecorderTests` 6, `GameSaveStoreTests` 9 (uusi, BOD-006).
    - iOS-viewmodel (SwiftUI-riippuvainen, `GameFeedback.swift` korvattu testipaketissa AVAudioSession-riippumattomalla tynkäluokalla, koska AVAudioSession ei ole käytettävissä macOS:lla — ei tuotantokoodin muutos): **8/8 läpäisi** — `GameRestoreTests` 5 (uusi, BOD-006: palautus ennen heittoa, valinnan aikana, kesken heiton, ajastetussa pelissä, päättyneen pelin ajastin ei jatku), `GameViewModelTimedAnimationTests` 3 (BOD-002, nyt R2:n jälkeen kääntyvä).
    - Watch-viewmodel (WatchKit korvattu testipaketissa tyhjällä haptiikkatynkäluokalla): **10/10 läpäisi** — `WatchGameCoreRegressionTests` 5 (BOD-001, nyt R2:n jälkeen kääntyvä), `WatchGameRestoreTests` 5 (uusi, BOD-006, samat skenaariot kuin iOS:lla).
  - Yhteensä 50/50 testiä läpäisi todellisella Xcode/XCTest-ajolla tässä istunnossa.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet:
  - Testit eivät edelleen kuulu mihinkään Xcode-projektin testikohteeseen (ks. R1 — ei korjattu tässä istunnossa; vaatisi `project.pbxproj`:n laajempaa muokkausta uuden testitargetin lisäämiseksi, mikä rajattiin tämän kierroksen ulkopuolelle harkitusti pienen riskin pitämiseksi).
  - R3 (kaksoiskirjaustesti ei testaa itse suojaa) ja R4 (loppuajan testin löysä toleranssi/lyhyt peli ei erottele vanhaa ja uutta toteutusta) jäävät avoimiksi — molemmat koskevat aiempien BOD-002/005-korjausten testejä, eivät BOD-006:ta, ja niiden korjaaminen vaatisi joko UI-testauskirjaston lisäämistä (kaksoiskirjaussuoja elää SwiftUI-näkymässä) tai injektoitavaa kelloa (ajastintesti) — molemmat suurempia muutoksia kuin tämän tehtävän rajaus.
  - Ei laitetestiä (fyysinen iPhone/Watch) kummallakaan alustalla — vain simulaattori-SDK-kääntö ja macOS-XCTest-ajo. Todellista prosessin päättämistä (kill -9, muistin vapautus käyttöjärjestelmän toimesta) ei ole testattu; simuloitu vain rakentamalla `GameEngine`/`GameViewModel`-tila käsin ja ajamalla `restore()` tuoreelle instanssille, joka on käytännössä samanlainen tilanne kuin prosessin uudelleenkäynnistys.
  - Moninpelin pelaajamäärän/vuoron/tulosten palautus on testattu `SavedGame`-tallennetasolla (`GameSaveStoreTests`) mutta ei `ContentView.restoreSavedGameIfAny()`:n läpi, koska se on SwiftUI-näkymän metodi eikä projektissa ole UI-testauskirjastoa.
  - Ei ole varmistettu silmämääräisesti simulaattorilla, että palautettu peli näyttäytyy oikein käyttöliittymässä (esim. animaation puuttuminen kesken-heiton-palautuksessa).
- Android-/Apple-vertailun tulos tai seuraava tarkistus: Android tutkimatta, ei muutettu. Erottele näytön kierto, Activityn uudelleenluonti, taustalle siirtyminen ja prosessin kuolema Androidissa erikseen (ks. alkuperäinen BOD-006-Android-vertailuohje).
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-001–005: riippumaton tarkistus

- Raportti: [Korjausten tarkistus ja jatkotoimet](KORJAUSTEN_TARKISTUS_2026-09-09.md).
- Tuotantokoodia tai repositorion testejä ei muutettu; vain tarkistusraportti ja tämä merkintä lisättiin.
- iOS- ja watchOS-simulaattorikohteet rakentuivat onnistuneesti Xcode-betalla (`DEVELOPER_DIR` asetettuna). Aiempi Command Line Tools -rajoite ei estänyt tätä tarkistusta.
- 23 alkuperäistä pelimoottori-/haku-/tilastotestiä läpäisi erillisessä macOS-XCTest-paketissa. Lisäksi 8 viewmodel-testiä läpäisi väliaikaisin testirajapintakorjauksin ja korvatuin laitepalauttein.
- Avoimet havainnot R1–R4 raportissa: Xcode-testikohteet puuttuvat; iOS:n NoOp-alustaja ja Watchin GameSettings-kutsu estävät alkuperäisten ajastustestien kääntymisen; kaksoiskirjauksen esto ja loppuajan sekuntiraja eivät saa nykyisistä testeistä riittävää regressiosuojaa.
- Alustataulukkoa ei nostettu kokonaan Varmistettu-tilaan: alkuperäisiä testejä ei vielä voi ajaa sovellusprojektista, eikä Watchin natiivia toimintatestiä tai animaatioiden visuaalista tarkistusta tehty. Korjauskohtainen näyttö ja rajat löytyvät raportista.
- GameEngine muuttui samanaikaisesti; tarkistus tehtiin tilannekopion pohjalta. BOD-006 ja kopion jälkeiset muutokset eivät sisälly hyväksyntään. Android tutkimatta.
- Commit / julkaisu: ei tehty.

### 9.9.2026 — BOD-005, iOS + watchOS: pelimuotokohtaiset pistetilastot

- Päivämäärä: 9.9.2026
- Tunnus ja alusta: BOD-005, iOS ja watchOS
- Tila ennen → jälkeen: Koodihavainto → Toteutettu, varmistamatta (molemmat alustat)
- Ongelman varmistus (koodi / toisto ja olosuhteet): Luettu `BoxOfDice/ContentView.swift`, `BoxOfDice/GameStatistics.swift`, `BoxOfDice/StatsView.swift`, `WatchApp/WatchContentView.swift` ja `WatchApp/WatchSupportViews.swift` nykytilassa. Vahvistettu koodista: `recordCompletedGame` (molemmilla alustoilla, rakenteellisesti identtinen) lisäsi jokaisen pelimuodon `finalScore`-arvon (joka jo sisältää ajastetun pelin sekunnit) samaan yhteiseen `totalScore`/`bestScore`/`winningScoreTotal`/`losingScoreTotal`-lukuun riippumatta laattamäärästä (12 vs. 18) tai siitä, sisälsikö tulos aikaa. `bestScoreClassic`/`bestScoreSpeedRun`/`bestScoreBigBox`/`bestScoreBigBoxSpeed` olivat jo ennestään oikein pelimuotokohtaisia — näitä ei tarvinnut korjata, vain säilyttää. Ei toistettu laitteella; havainto perustuu koodin lukemiseen ja päättelyyn pistekaavasta (`GameMode.finalScore(baseScore:elapsedSeconds:)`).
- Ennen → jälkeen -käyttäytyminen: Ennen: "Average score" / "Best Score" -yhteisluvut ja "Average winning/losing score" sekoittivat 12 ja 18 laatan pelit sekä ajastetut ja ajastamattomat pelimuodot yhteen, joten ne eivät olleet vertailukelpoisia eivätkä mielekkäitä. Jälkeen: `totalScore`, `bestScore`, `winningScoreTotal` ja `losingScoreTotal` ovat jäädytettyjä (uusi koodi ei enää lue eikä kirjoita niitä; vanha data säilyy `UserDefaults`-tallessa, "Reset"-toiminto tyhjentää ne edelleen käyttäjän omasta pyynnöstä). Uudet avaimet `modeScoreTotal.<mode>` / `modeScoreCount.<mode>` keräävät pelimuotokohtaisen summan ja määrän *tästä päivityksestä alkaen* — ei yritetä jakaa vanhaa yhteissummaa arvaamalla pelimuotojen kesken. Käyttöliittymä näyttää nyt "Best Score by Mode" (olemassa ollut, säilytetty) -osion rinnalla uuden "Average Score by Mode" -osion, jossa jokaisen pelimuodon rivillä on "(+ time)"-merkintä ajastetuille pelimuodoille ja osion alla lyhyt selite ("Averages count games played after this update."/"Keskiarvot lasketaan tästä päivityksestä alkaen pelatuista peleistä."). Yhteenvetokortti "Best Score" (yhdistetty, harhaanjohtava) korvattiin "Perfect"-kortilla (täydelliset tyhjennykset, aidosti yhdistettävä luku). `gamesPlayed`/`gamesWon`/`losses`/`perfectClears`/voittoputket/`longestGameTurns`/`shortestClearTurns`/`remainingTileCounts` säilyivät yhdistettyinä ja koskemattomina — näitä ei pyydetty erotella eivätkä ne ole pisteitä. Lisätty myös nimenomainen suoja saman päättyneen pelin kaksinkertaista kirjaamista vastaan (`hasRecordedCurrentGameResult`), joka nollataan aina uuden pelin alkaessa ja tarkistetaan `handleGameOver`/`handleGameStateChange`:ssa ennen `recordCompletedGame`-kutsua.
- Korjauksen toteutus ja mahdollinen poikkeama suunnitelmasta: Toteutus vastaa tavoitetta. Yksi rakenteellinen lisäys suunnitelman ulkopuolella: pelkkä pistetilastojen kirjauslogiikka eriytettiin iOS:lla omaan puhtaaseen tiedostoon `BoxOfDice/GameStatisticsRecorder.swift`, joka ottaa `UserDefaults`-instanssin parametrina — tämä tehtiin nimenomaan, jotta vaaditut testitapaukset (vanha data, ensimmäinen tulos, nollapisteen ennätys, ajastettu tulos, toistuva kirjaus) voidaan ajaa suoraan ilman SwiftUI-näkymän renderöintiä. `ContentView.recordCompletedGame(won:)` kutsuu nyt tätä yhdellä rivillä. Watch-puolella (`WatchContentView.swift`) vastaava logiikka säilytettiin suoraan näkymässä (kuten aiemminkin) ilman vastaavaa eriytystä, koska Watch-kohteelle ei ole ajettavaa testikohdetta tässä ympäristössä eikä tehtävä erikseen pyytänyt alustojen tilastologiikan yhdistämistä (toisin kuin BOD-003 pelimoottorille) — Watchin toteutus tarkistettiin käsin rinnakkain iOS:n korjatun logiikan kanssa täsmäävyyden varmistamiseksi.
- Muutetut tiedostot:
  - `BoxOfDice/GameStatistics.swift` (lisätty: `modeScoreTotal.<mode>` / `modeScoreCount.<mode>` -avaimet; vanhat avaimet säilytetty koskemattomina)
  - `BoxOfDice/GameStatisticsRecorder.swift` (uusi: puhdas, testattava tilastonkirjauslogiikka)
  - `BoxOfDice/ContentView.swift` (`recordCompletedGame` delegoi `GameStatisticsRecorder`:lle; `hasRecordedCurrentGameResult`-suoja; poistettu käytöstä tarpeettomiksi jääneet `@AppStorage`-kentät, jotka olivat vain kirjoituskäytössä)
  - `BoxOfDice/StatsView.swift` (UI: "Average Score by Mode" -osio, "(+ time)"-merkinnät, yhteenvetokortti "Best Score" → "Perfect", "Reset" tyhjentää myös uudet ja vanhat avaimet)
  - `WatchApp/WatchGameCore.swift` (`StatisticsStorageKey`: lisätty samat `modeScoreTotal`/`modeScoreCount`-avaimet)
  - `WatchApp/WatchContentView.swift` (`recordCompletedGame` pelimuotokohtaiseksi; `hasRecordedCurrentGameResult`-suoja `handleGameStateChange`:ssa; kaikki neljä `viewModel.newGame(...)`-kutsupaikkaa ohjattu `beginNewViewModelGame`-apufunktion läpi suojan nollaamiseksi)
  - `WatchApp/WatchSupportViews.swift` (`WatchStatsView`: pelimuotokohtaiset keskiarvorivit Classic/Speed Run -pelimuodoille, sama selite, "(+ time)"-merkinnät, "Reset" tyhjentää myös uudet ja vanhat avaimet)
  - `BoxOfDice/fi.lproj/Localizable.strings`, `WatchApp/fi.lproj/Localizable.strings` (uudet suomennokset: "Average Score by Mode", "%@ (+ time)", "Averages count games played after this update.", Watchille lisäksi "%@ avg.")
  - `BoxOfDiceTests/GameStatisticsRecorderTests.swift` (uusi, testit — ei vielä kytketty testikohteeseen)
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Uudet avaimet (`statistics.modeScoreTotal.*`, `statistics.modeScoreCount.*`) lisätty; kaikki alkavat nollasta joka asennuksella eikä niitä täytetä taannehtivasti vanhasta datasta. Vanhoja avaimia (`statistics.totalScore`, `statistics.bestScore`, `statistics.winningScoreTotal`, `statistics.losingScoreTotal`) ei poisteta eikä niiden arvoja muuteta koodin toimesta — ne jäävät `UserDefaults`-tallessa koskemattomina, paitsi jos käyttäjä itse painaa "Reset". Pelimuotokohtaiset `bestScore.<mode>`-avaimet säilyvät täysin ennallaan.
- Ajetut testit ja buildit (komennot, ympäristö, tulos): `swiftc -typecheck BoxOfDice/GameStatisticsRecorder.swift BoxOfDice/GameStatistics.swift BoxOfDice/GameMode.swift BoxOfDice/GameSettings.swift BoxOfDice/GameEngine.swift -parse-as-library` onnistui virheittä (aidosti tyyppitarkistettu). Kaikki muutetut tiedostot (myös SwiftUI-riippuvaiset) läpäisivät `swiftc -parse`:n. Lisäksi `BoxOfDiceTests/GameStatisticsRecorderTests.swift`:n kaikki kuusi testitapausta (vanha data koskematta, ensimmäinen tulos pelimuodolle, nollapisteen ennätys pysyy eikä ylikirjoitu, ajastettu tulos sisältää sekunnit vain oikeaan pelimuotoon, kaksi eri pelimuotoa kertyvät erillisiin laskureihin, kahdesti kutsuminen kaksinkertaistaa laskurit) ajettiin manuaalisesti erillisenä `swiftc`-ajurina todellista `GameStatisticsRecorder`-lähdekoodia ja eristettyä `UserDefaults(suiteName:)`-varastoa vastaan — kaikki kuusi tapausta onnistuivat ("ALL PASS").
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: Ei täyttä Xcodea tässä ympäristössä — kumpaakaan sovelluskohdetta ei voitu oikeasti kääntää tai ajaa. `BoxOfDiceTests/GameStatisticsRecorderTests.swift` ei ole ajettu XCTestin kautta (testikohde puuttuu), vain manuaalisena ajurina. `hasRecordedCurrentGameResult`-suojan itsensä (SwiftUI-näkymän `@State`) toimintaa ei voitu testata suoraan, koska se elää `ContentView`/`WatchContentView`-näkymän sisällä eikä projektissa ole UI-testausriippuvuutta (esim. ViewInspector) eikä sellaista pyydetty lisättäväksi; `GameStatisticsRecorderTests`-testi dokumentoi tämän rajoitteen selkeästi ("mitä tapahtuisi jos suoja ohitettaisiin") sen sijaan että väittäisi todistaneensa suojan itsensä toimivan. Watchin UI-muutoksia (uusi keskiarvo-osio, selite) ei ole nähty simulaattorissa tai laitteella, vain koodin lukemisen perusteella.
- Android-/Apple-vertailun tulos tai seuraava tarkistus: Android tutkimatta, ei muutettu.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-004, iOS + watchOS: rajattu haku sallituille siirroille

- Päivämäärä: 9.9.2026
- Tunnus ja alusta: BOD-004, iOS ja watchOS (yhteinen `GameEngine`, ks. BOD-003 samalta päivältä)
- Tila ennen → jälkeen: Koodihavainto → Toteutettu, varmistamatta (molemmat alustat, koska moottori on nyt yhteinen)
- Ongelman varmistus (koodi / toisto ja olosuhteet): Ennen BOD-004-korjausta `GameEngine.allowedSubsets` (ks. tämän dokumentin BOD-003-merkintä, jossa se yhdistettiin `BoxOfDice/GameEngine.swift`-tiedostoon) kävi läpi kaikki `1..<(1 << n)` bittimaskia eli kaikki avointen laattojen epätyhjät osajoukot (18 laatalla 262143), ja `hasValidMoves()` kutsui `!validMoves().isEmpty`, joka rakensi täyden siirtolistan vain olemassaolon tarkistamiseksi. Vahvistettu koodin lukemisesta ja mittaamalla tämän istunnon aikana (ks. alla) — ei laitteella.
- Ennen → jälkeen -käyttäytyminen: Ennen: siirtohaku skannasi kaikki osajoukot myös silloin, kun `oneOrTwoTiles`-sääntö olisi hylännyt yli kaksi laattaa käyttävät osajoukot vasta jälkikäteen, ja olemassaolotarkistus rakensi turhaan koko listan. Jälkeen: `GameEngine.allowedCombinations(_:target:stopAtFirst:)` on syvyyshaku järjestettyjen (nousevassa järjestyksessä), aidosti positiivisten laattanumeroiden yli: kun kertymä ylittää tavoitteen, koko haara hylätään kokonaan (koska seuraava tai mikä tahansa myöhempi laatta on vähintään yhtä suuri, mikään jatko ei voi enää osua tavoitteeseen) — tätä ei rajattu vain "katkaise silmukka", vaan koko alipuu jätetään käymättä. `oneOrTwoTiles`-sääntö rajaa haarautumisen jo haun aikana (`maxTilesPerMove`), ei jälkikäteen suodattamalla. `hasValidMoves()` kutsuu hakua `stopAtFirst: true` -lipulla, joka palauttaa välittömästi ensimmäisen osuman löydyttyä sen sijaan, että täysi lista rakennettaisiin. `validMoves()` ja `bestHint()`:n vähiten-laattoja/leksikografinen-tasapeli-periaate säilyivät muuttumattomina; `bestHint()` kutsuu edelleen `validMoves()`:ia eikä uutta strategia-algoritmia ole toteutettu. Ei välimuistia lisätty.
- Korjauksen toteutus ja mahdollinen poikkeama suunnitelmasta: Toteutus vastaa BOD-004-tavoitetta täsmälleen. Ei poikkeamaa. `allowedCombinations` muutettiin `private`-tasosta oletusarvoiseen (internal) näkyvyyteen, jotta `@testable import`-testit voivat ajaa sitä suoraan mielivaltaisilla laattalistoilla riippumatta minkään `GameEngine`-instanssin todellisesta laattatilasta; tämä ei muuta julkista API:a (`GameEngine`-tyyppi itsessään ja sen julkiset metodit pysyivät samoina).
- Muutetut tiedostot:
  - `BoxOfDice/GameEngine.swift` (korjaus: `allowedCombinations`, `hasValidMoves()`, `validMoves()`, `maxTilesPerMove`; vanha `allowedSubsets`/`isSelectionAllowed(Set)`-jälkisuodatus poistettu hausta, `isSelectionAllowed` säilyy `canConfirm`:in käyttämänä)
  - `BoxOfDiceTests/GameEngineSearchTests.swift` (uusi, testit — ei vielä kytketty testikohteeseen)
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Ei mitään. Puhtaasti sisäinen algoritmimuutos; julkinen käyttäytyminen (`validMoves()`, `bestHint()`, `hasValidMoves()`) tuottaa täsmälleen samat tulokset kuin ennen.
- Ajetut testit ja buildit (komennot, ympäristö, tulos): Koska projektissa ei ole yksikkötestikohdetta eikä ympäristössä ole täyttä Xcodea, testien logiikka ajettiin manuaalisesti tämän istunnon aikana `swiftc`-komentoriviltä koostamalla `GameEngine.swift` + `GameMode.swift` + `GameSettings.swift` + testilogiikkaa vastaava ajuri (`swift 6.4, arm64-apple-macosx, -O`) erilliseen tilapäishakemistoon (ei osa repositoriota). Tulokset: (1) uusi haku verrattuna brute-force-referenssiin (alkuperäinen bittimaskialgoritmi, pidetty ajurissa vain vertailua varten) läpikäytiin 51 296 tapauksessa — laudat 1, 2, 3, 5, 8, 12, 15 ja 18 laattaa; pienillä laudoilla (≤8) KAIKKI avointen laattojen osajoukot, suuremmilla koko lauta, tyhjä lauta ja 40 satunnaista osajoukkoa; noppasummat 0..3×laattamäärä; molemmat `moveRule`-arvot — kaikki 51 296 tapausta täsmäsivät (ei eroja, ei duplikaatteja). (2) täyden 18 laatan laudan (`anyCombination`) mittaus samalla koneella, noppasummilla 9/18/27: brute force ~0.0355–0.0358 s per haku, optimoitu haku 9.5×10⁻⁷–1.4×10⁻⁵ s per haku, mitattu nopeutus n. 2 500×–37 000×. `swiftc -typecheck` `GameEngine.swift`+`GameMode.swift`+`GameSettings.swift`:lle onnistui virheittä (aidosti tyyppitarkistettu, ei vain jäsennetty). Kaikki muutetut/uudet tiedostot läpäisivät myös `swiftc -parse`.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: Yllä kuvatut mittaukset ja korrektuustarkistukset ajettiin TÄMÄN kehityskoneen (macOS, Command Line Tools, ei Xcode) Swift-kääntäjällä erillisenä ajurina, EIVÄT varsinaisen XCTest-ajon kautta eikä iOS/watchOS-laitteella tai -simulaattorilla — absoluuttiset ajat eivät kuvaa laitteen suorituskykyä, vain suhteellisen nopeutuksen samalla ajolla samalla koneella. `BoxOfDiceTests/GameEngineSearchTests.swift` sisältää saman logiikan XCTestina, mutta sitä ei ole ajettu XCTestin kautta, koska testikohde puuttuu. Watch-kohteen todellista käännöstä (WatchKit/SwiftUI vaativat watchOS-SDK:n, jota ei ole tässä ympäristössä) ei voitu suorittaa; vain `swiftc -parse` onnistui Watch-tiedostoille.
- Android-/Apple-vertailun tulos tai seuraava tarkistus: Android tutkimatta, ei muutettu. Algoritmin ja kutsumäärän tarkistus Androidissa on oma erillinen tehtävä (ks. BOD-004:n Android-vertailuohje tämän dokumentin yläosassa).
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-003, iOS + watchOS: yhteinen GameEngine ja korjattu Watch-siemen

- Päivämäärä: 9.9.2026
- Tunnus ja alusta: BOD-003, iOS ja watchOS
- Tila ennen → jälkeen: Suunniteltu/Koodihavainto → Toteutettu, varmistamatta (molemmat alustat)
- Ongelman varmistus (koodi / toisto ja olosuhteet): Luettu `BoxOfDice/GameEngine.swift` ja `WatchApp/WatchGameCore.swift` nykytilassa. Vahvistettu koodista: watchOS:lla oli oma, erillinen kopio pelilogiikasta (`Tile`, `MoveRecord`, `GameState`, `GameSettings`, siirtojen validointi, `roll`/`toggleTile`/`confirmSelection`/`undoLastMove` suoraan `GameViewModel`:issa) ilman `diceMode`/`moveRule`-tukea lainkaan. `WatchApp/WatchGameCore.swift`:n `newGame(settings:seed:isTimed:)` otti `seed`-parametrin vastaan mutta ei koskaan käyttänyt sitä missään — Watchin nopat olivat siis aina järjestelmän satunnaisgeneraattorista riippumatta annetusta siemenestä. Ei toistettu laitteella; havainto perustuu koodin lukemiseen.
- Ennen → jälkeen -käyttäytyminen: Ennen: iOS ja watchOS saattoivat teoriassa antaa eri lopputuloksia samoilla asetuksilla/toiminnoilla, koska pelilogiikka oli kaksi erillistä toteutusta; Watchin siemen ei koskaan vaikuttanut noppiin. Jälkeen: molemmat alustat kutsuvat samaa `GameEngine`-structia (samat `Tile`, `MoveRecord`, `GameState`, `DiceMode`, `MoveRule`, `GameSettings`, `SeededRandomNumberGenerator`), joka elää `BoxOfDice/GameEngine.swift`-tiedostossa ja on liitetty myös Watch-kohteeseen (ks. tiedostomuutokset alla). Watchin `GameViewModel` on nyt ohut kääre `GameEngine`:n ympärillä — samalla rakenteella kuin iOS:n `GameViewModel` on aina ollut — ja välittää `seed`-parametrin suoraan `engine.reset(settings:seed:)`:lle, joten sama siemen + samat asetukset + sama toimintojono tuottaa saman pelitilan molemmilla alustoilla. Ilman siementä (`seed: nil`) moottori nollaa generaattorinsa ja käyttää järjestelmän satunnaisuutta, kuten aiemminkin. `diceMode`/`moveRule` ovat nyt olemassa myös Watchilla (moottorin läpi), joskin Watchin nykyinen UI ei vielä tarjoa niiden valintaa käyttäjälle — molemmat alustat välittävät niille edelleen samat oletusarvot (`.alwaysTwoDice`, `.anyCombination`) kuin ennen yhdistämistä, eli havaittava käyttäytyminen ei muuttunut siltä osin. Aiemmat BOD-001- (tehtävän peruutus/`gameGeneration`) ja BOD-002-korjaukset (`effectiveDiceAnimationSpeed`, `stopTimer()`:n suora loppuajan lasku) säilyivät molemmilla alustoilla; niitä ei purettu tässä yhdistämisessä.
- Korjauksen toteutus ja mahdollinen poikkeama suunnitelmasta: Toteutus vastaa tavoitetta. Yksi tietoinen rajaus tavoitteen kirjaimellisesta tulkinnasta: `DiceMode`/`MoveRule`:n `.title`-lokalisointitekstit (jotka olivat olemassa iOS:n `GameSettings.swift`:ssä mutta joita ei käytetä missään UI:ssa toistaiseksi) poistettiin kokonaan siirron yhteydessä sen sijaan, että niitä olisi siirretty yhteiseen tiedostoon — koska ne ovat lokalisointia (`L10n`), joka tehtävän vaatimusten mukaan pidetään erossa yhteisestä pelilogiikasta, ja koska ne olivat käyttämättömiä kummallakaan alustalla. Tämä ei muuta havaittavaa käyttäytymistä, koska niitä ei kutsuttu mistään. `GameMode` (title/subtitle, L10n-riippuvainen) jätettiin tarkoituksella alustakohtaiseksi kahdeksi erilliseksi tiedostoksi kuten ennenkin — sitä ei pyydetty yhdistettäväksi, ja sen tekstit eroavat jo nyt lievästi alustojen välillä. `DiceAnimationSpeed` jätettiin myös alustakohtaiseksi (ei pelisääntö, jo yhtenäistetty käyttäytymiseltään BOD-002:ssa).
- Muutetut tiedostot:
  - `BoxOfDice/GameEngine.swift` (laajennettu: sisältää nyt myös `DiceMode`, `MoveRule`, `GameSettings`, jotka olivat aiemmin `GameSettings.swift`:ssä; header-kommentti päivitetty kuvaamaan jaettua käyttöä)
  - `BoxOfDice/GameSettings.swift` (`DiceMode`, `MoveRule`, `GameSettings` poistettu — elävät nyt `GameEngine.swift`:ssä; muu sisältö [`L10n`, `AppLanguage`, `DiceAnimationSpeed`, `ChallengeMode`, `GameThemeName`, `SettingsStorageKey`, `StatisticsStorageKey`] koskematta)
  - `WatchApp/WatchGameCore.swift` (`Tile`, `MoveRecord`, `GameState`, `GameSettings`:n omat kopiot poistettu; `GameViewModel` kirjoitettu uudelleen ohueksi `GameEngine`-kääreeksi; `seed`-parametri välitetään nyt oikeasti eteenpäin)
  - `WatchApp/WatchContentView.swift` (`currentSettings` päivitetty kutsumaan `GameSettings.from(mode:diceMode:moveRule:)`:ia kolmella parametrilla, oletusarvot `.alwaysTwoDice`/`.anyCombination` — käyttäytyminen ennallaan)
  - `BoxOfDice.xcodeproj/project.pbxproj` (lisätty `BoxOfDice/GameEngine.swift`:lle eksplisiittinen `PBXFileReference`+`PBXBuildFile`+`Sources`-jäsenyys "BoxOfDice Watch App" -kohteeseen — samalla kaavalla kuin projektissa jo ennestään jaetaan `Assets.xcassets`/`PrivacyInfo.xcprivacy`: tiedosto on fyysisesti `BoxOfDice/`-kansiossa, jonka iOS-kohde jo sisällyttää automaattisesti `fileSystemSynchronizedGroups`-mekanismilla, ja Watch-kohteelle jäsenyys lisättiin eksplisiittisesti. Lisätty myös projektin "Shared"-virtuaaliryhmään Xcode-navigaattorin siisteyden vuoksi. `plutil -lint` vahvisti tiedoston säilyneen validina plist-muodossa muutoksen jälkeen.)
  - `BoxOfDiceTests/GameEngineTests.swift` (uusi, testit — ei vielä kytketty testikohteeseen)
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Ei mitään tallennusavaimiin — `SettingsStorageKey`/`StatisticsStorageKey` koskematta kummallakaan alustalla, kuten vaatimuksissa pyydettiin. `GameSettings`-tyypin sisäinen sijainti lähdekoodissa muuttui, mutta se ei ole `Codable`/tallennettu suoraan; ei vaikutusta.
- Ajetut testit ja buildit (komennot, ympäristö, tulos): `swiftc -typecheck BoxOfDice/GameEngine.swift BoxOfDice/GameMode.swift BoxOfDice/GameSettings.swift -parse-as-library` onnistui virheittä (aidosti tyyppitarkistettu yhdessä, ei vain jäsennetty erikseen). Kaikki muutetut Watch- ja iOS-tiedostot läpäisivät `swiftc -parse`:n. `plutil -lint` vahvisti `project.pbxproj`:n pysyneen validina. Lisäksi `BoxOfDiceTests/GameEngineTests.swift`:n testilogiikka (sallittu/virheellinen valinta, voitto, siirtojen loppuminen, yhden nopan sääntö, enintään kahden laatan sääntö, samalla siemenellä toistuva peli, reset+uusi siemen) ajettiin manuaalisesti erillisenä `swiftc`-ajurina (swift 6.4, arm64-apple-macosx, tämä kehityskone) todellista `GameEngine`+`GameMode`+`GameSettings`-lähdekoodia vastaan — kaikki tapaukset onnistuivat ("ALL PASS"). Tämän aikana havaittiin ja korjattiin testien oma virhe: siemenet 1 ja 2 tuottavat tällä generaattorilla saman ensimmäisen heiton (empiirisesti todettu), joten "eri siemenet voivat poiketa" -testissä käytettiin siemeniä 1 ja 42, jotka empiirisesti todettiin poikkeaviksi.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: Ei täyttä Xcodea tässä ympäristössä — kumpaakaan sovelluskohdetta ei voitu oikeasti kääntää (`xcodebuild`) tai ajaa simulaattorilla/laitteella. `WatchApp/WatchContentView.swift`, `WatchSupportViews.swift` ja muut SwiftUI/WatchKit-riippuvaiset tiedostot läpäisivät vain `swiftc -parse`:n (jäsennys), ei tyyppitarkistusta, koska tämän koneen SDK:sta puuttuu WatchKit ja SwiftUI:n makroplugin. `BoxOfDiceTests/GameEngineTests.swift` ei ole ajettu XCTestin kautta (testikohde puuttuu) — sen sijasta ajettu manuaalinen ajuri, joka on todistettavasti samaa logiikkaa mutta ei täsmälleen sama ajopolku (esim. XCTest-attribuutit, ajastus, raportointi puuttuvat). Watchin UI:ssa ei ole diceMode/moveRule-valintaa käyttäjälle — tätä ei pyydetty lisättäväksi, mutta se tarkoittaa, ettei tätä yhdistämistä ole voitu todentaa visuaalisesti Watch-näkymässä eri sääntöasetuksilla.
- Android-/Apple-vertailun tulos tai seuraava tarkistus: Android tutkimatta, ei muutettu. Tämän BOD-003-korjauksen jälkeen "sama Swift-lähdekoodi" ei ole Android-vaatimus (ks. dokumentin alkuperäinen BOD-003-Android-vertailuohje); Android-puolen sääntöjen ja siementen vertailu on oma tehtävänsä.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-002, iOS + watchOS: animaatioasetus ei saa vaikuttaa ajastettuun tulokseen

- Päivämäärä: 9.9.2026
- Tunnus ja alusta: BOD-002, iOS ja watchOS
- Tila ennen → jälkeen: Koodihavainto → Toteutettu, varmistamatta (molemmat alustat)
- Ongelman varmistus (koodi / toisto ja olosuhteet): Luettu `BoxOfDice/GameViewModel.swift` ja `WatchApp/WatchGameCore.swift` nykytilassa. Vahvistettu koodista: molemmilla alustoilla `rollDice()` laski heittoanimaation (ja siten myös vuorovaikutuksen lukituksen) keston suoraan käyttäjän `diceAnimationSpeed`-asetuksesta riippumatta pelimuodosta, ja ajastin (`elapsedSeconds`) käynnistyy ensimmäisestä heitosta — pidempi käyttäjän valitsema animaatio siis kasvatti suoraan ajastetun pelin lopputulosta. iOS:ssa näkyvä 3D-noppa-animaatio (`Dice3DView`, `ContentView.swift`) luki saman raa'an asetuksen erikseen omalla polullaan (`diceAnimationSpeed.tumbleDuration`) `GameViewModel`-luokan kutsusta riippumatta, joten pelkkä `rollDice()`-korjaus ei olisi riittänyt yhtenäistämään näkyvää animaatiota ja lukitusta. `stopTimer()` ei kummallakaan alustalla laskenut lopullista `elapsedSeconds`-arvoa suoraan aloitusajasta, vaan jätti sen viimeisen ~100–250 ms:n jaksoittaisen ajastinpäivityksen varaan. Ei toistettu laitteella tai simulaattorissa; havainto perustuu koodin lukemiseen.
- Ennen → jälkeen -käyttäytyminen: Ennen: Speed Run- ja Big Box Speed -pelien lopputulos riippui käyttäjän valitsemasta animaationopeudesta (Short/Normal/Long), ja lopullinen aika saattoi jäädä jopa yhden ajastinjakson verran vanhentuneeksi. Jälkeen: molemmat `GameViewModel`-luokat laskevat uuden `effectiveDiceAnimationSpeed`-arvon (`isTimed ? .normal : diceAnimationSpeed`) ja käyttävät sitä sekä animaation että lukituksen kestoon; ajastetuissa pelimuodoissa asetus ei vaikuta lopputulokseen, myöskään asetuksen vaihtaminen kesken pelin. iOS:n `ContentView` lukee näkyvän noppa-animaation keston nyt `viewModel.effectiveDiceAnimationSpeed.tumbleDuration`-arvosta suoran asetuksen sijaan, joten näkyvä animaatio ja lukitus eivät voi ajautua eri kestoihin. `stopTimer()` laskee `elapsedSeconds`-arvon suoraan `gameStartTime`-arvosta juuri pelin päättyessä eikä jätä sitä jaksoittaisen päivityksen varaan.
- Korjauksen toteutus ja mahdollinen poikkeama suunnitelmasta: Toteutus vastaa BOD-002-tavoitteen rajattua ratkaisua (vakioitu normaali kesto ajastetuissa pelimuodoissa, käyttäjän asetus muualla, ei muutoksia pisteytyskaavaan eikä automaattisen heiton muuhun käyttäytymiseen). Ei poikkeamaa suunnitelmasta. Pistekaava (`finalScore`, `finalScore(baseScore:elapsedSeconds:)`) ei koskettu.
- Muutetut tiedostot:
  - `BoxOfDice/GameViewModel.swift` (korjaus: `effectiveDiceAnimationSpeed`, `rollDice()`, `stopTimer()`)
  - `BoxOfDice/ContentView.swift` (korjaus: näkyvä nopan animaatiokesto luetaan `viewModel.effectiveDiceAnimationSpeed`-arvosta)
  - `WatchApp/WatchGameCore.swift` (korjaus: `effectiveDiceAnimationSpeed`, `rollDice()`, `stopTimer()`)
  - `BoxOfDiceTests/GameViewModelTimedAnimationTests.swift` (uusi, testit — ei vielä kytketty testikohteeseen)
  - `WatchAppTests/WatchGameCoreRegressionTests.swift` (laajennettu BOD-002-testeillä — ei vielä kytketty testikohteeseen)
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Ei mitään. `effectiveDiceAnimationSpeed` on laskettu ominaisuus, ei tallenneta. Käyttäjän tallennettu `settings.diceAnimationSpeed`-asetus säilyy koskemattomana ja vaikuttaa edelleen tavallisissa pelimuodoissa.
- Ajetut testit ja buildit (komennot, ympäristö, tulos): `swiftc -parse` kaikille muutetuille lähdetiedostoille ja molemmille uusille/laajennetuille testitiedostoille — pelkkä syntaksitarkistus (parse-tila, ei tyyppitarkistusta, ei WatchKit/SwiftUI-tuontia, ei XCTest-tuontia), kaikki päättyivät onnistuneesti (exit 0). Tämä ei todista käännöstä eikä käyttäytymistä; testejä ei ajettu.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: Ympäristössä ei ole täyttä Xcodea (`xcodebuild` vaatii Xcodea), joten kumpaakaan kohdetta ei voitu kääntää tai ajaa oikeasti. Projektissa ei ole yksikkötestikohdetta kummallekaan alustalle; uudet/laajennetut testitiedostot vaativat käsin lisättävän testikohteen Xcodessa ennen ajoa. Lisätty `testElapsedSecondsFinalizedDirectlyFromStartTimeAtGameEnd`-testi vahvistaa `elapsedSeconds`-arvon olevan järkevä ja lasketaan suoraan todellisesta kellonajasta, mutta ei pysty deterministisesti pakottamaan täsmällistä "jää yhden ajastinjakson taakse" -reunatapausta, koska testi käyttää oikeaa kelloa eikä pistettä ei ole korvattu testattavalla väärennetyllä kellolla; tämä rajoite on kirjattu myös testin kommenttiin. Näkyvän animaation ja lukituksen yhtenäisyyttä ei ole varmistettu silmämääräisesti laitteella tai simulaattorissa, vain koodin lukemisen ja `totalRollDurationNanoseconds`/`tumbleDuration`-arvojen vertailun perusteella (`testVisibleAnimationDurationMatchesInteractionLockDuration`).
- Android-/Apple-vertailun tulos tai seuraava tarkistus: Android tutkimatta, ei muutettu.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — BOD-001, watchOS: vanha heitto-/ajastintehtävä ei saa muuttaa uutta peliä

- Päivämäärä: 9.9.2026
- Tunnus ja alusta: BOD-001, watchOS
- Tila ennen → jälkeen: Koodihavainto → Toteutettu, varmistamatta
- Ongelman varmistus (koodi / toisto ja olosuhteet): Luettu `WatchApp/WatchGameCore.swift` nykytilassa. Vahvistettu koodista: `rollDice()`:n `rollTask`-sulkeuma jatkoi tilan kirjoittamista (`dice`, `isRolling`, `gameState`, palaute) `Task.sleep`-kutsun jälkeen tarkistamatta `Task.isCancelled`-tilaa eikä sitä, kuuluuko tehtävä yhä käynnissä olevaan peliin. `newGame()` peruutti `rollTask`in, mutta peruutus ei estänyt jo käynnissä olevan `sleep`-jatkeen suoritusta ilman erillistä tarkistusta. `startTimer()`:n silmukka tarkisti `Task.isCancelled`-tilan vain silmukan alussa ennen `sleep`-kutsua, ei sen jälkeen, joten peruutus kesken unen ei estänyt yhtä ylimääräistä `elapsedSeconds`-kirjoitusta. Ei toistettu laitteella tai simulaattorissa; havainto perustuu koodin lukemiseen ja päättelyyn asynkronisen suorituksen kulusta.
- Ennen → jälkeen -käyttäytyminen: Ennen: vanhan pelin heitto- tai ajastintehtävä saattoi kirjoittaa nopat, `isRolling`-arvon, pelivaiheen, kuluneen ajan tai antaa palautetta uuden pelin päälle, jos `newGame()` kutsuttiin kesken heittoanimaation tai ajastimen ollessa käynnissä. Jälkeen: lisätty `gameGeneration`-laskuri, jota kasvatetaan jokaisessa `newGame()`-kutsussa. `rollTask` ja `timerTask` tallentavat oman sukupolvensa ennen `await`-kohtaa ja tarkistavat sen jälkeen sekä `Task.isCancelled`-tilan että sukupolven täsmäävyyden ennen tilan muuttamista; muuten tehtävä palaa tekemättä mitään. `startTimer()`:n silmukka tekee tämän tarkistuksen jokaisen `sleep`-kutsun jälkeen, ei vain silmukan alussa.
- Korjauksen toteutus ja mahdollinen poikkeama suunnitelmasta: Toteutus vastaa BOD-001-tavoitetta ja hyväksymistestien kuvaamaa käyttäytymistä. Ei poikkeamaa. `newGame()` nollaa lisäksi `rollTask`-viittauksen suoraan peruutuksen jälkeen (ei toiminnallinen muutos, siisteys).
- Muutetut tiedostot:
  - `WatchApp/WatchGameCore.swift` (korjaus)
  - `WatchAppTests/WatchGameCoreRegressionTests.swift` (uusi, regressiotestit — ei vielä kytketty testikohteeseen)
- Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset: Ei mitään. `gameGeneration` on muistinvarainen, ei tallenneta eikä synkronoida.
- Ajetut testit ja buildit (komennot, ympäristö, tulos): `swiftc -parse WatchApp/WatchGameCore.swift -sdk $(xcrun --show-sdk-path)` — pelkkä syntaksitarkistus (parse-tila, ei tyyppitarkistusta eikä WatchKit/SwiftUI-tuontia), päättyi onnistuneesti (exit 0). Tämä ei todista käännöstä eikä käyttäytymistä.
- Ajamatta jääneet tarkistukset ja tunnetut rajoitteet: Ympäristössä ei ole täyttä Xcodea (`xcodebuild` vaatii Xcodea, käytössä vain Command Line Tools), joten watchOS-kohteen todellista buildia, simulaattoriajoa tai laitetestiä ei voitu suorittaa. Projektissa ei ole ennestään yksikkötestikohdetta Watch-sovellukselle; lisätty `WatchAppTests/WatchGameCoreRegressionTests.swift` sisältää kolme testiä (vanha heittotehtävä ei muuta uutta peliä, vanha ajastin ei jatka uudessa pelissä, 20 nopeaa peräkkäistä uuden pelin aloitusta jättävät pelin siistiin tilaan), mutta niitä ei ole ajettu — tiedosto vaatii käsin lisättävän testikohteen Xcodessa ("Unit Testing Bundle", liitetty "BoxOfDice Watch App" -kohteeseen) ennen ajoa. Todellista laitetoistoa alkuperäisestä viasta ei tehty ennen korjausta eikä sen jälkeen.
- Android-/Apple-vertailun tulos tai seuraava tarkistus: Android tutkimatta, ei muutettu.
- Commit (vain jos olemassa): ei tehty.
- Julkaisuversio ja päivä (vain jos julkaistu): ei julkaistu.

### 9.9.2026 — Seurannan perustaminen

- Työ: dokumentaatio, ei pelikoodin korjaus.
- Lisätty: tämä seuranta ja `CLAUDE_KIRJAUSOHJE.md`.
- Lähde: keskustelun iOS/watchOS-koodiarvio ja kuusi korjauspromptia.
- Android: tutkimatta; Android-repositoriota ei ole käsitelty.
- Testit: sovellusbuildia tai toimintatestejä ei ajettu. Seurantatunnukset ja dokumenttilinkit tarkistettu.
- Commit / julkaisu: ei tehty.

### Kopioitava merkintäpohja

```text
Päivämäärä:
Tunnus ja alusta:
Tila ennen → jälkeen:
Ongelman varmistus (koodi / toisto ja olosuhteet):
Ennen → jälkeen -käyttäytyminen:
Korjauksen toteutus ja mahdollinen poikkeama suunnitelmasta:
Muutetut tiedostot:
Tallennusdataan / yhteensopivuuteen vaikuttavat muutokset:
Ajetut testit ja buildit (komennot, ympäristö, tulos):
Ajamatta jääneet tarkistukset ja tunnetut rajoitteet:
Android-/Apple-vertailun tulos tai seuraava tarkistus:
Commit (vain jos olemassa):
Julkaisuversio ja päivä (vain jos julkaistu):
```

### 11.9.2026 — BOD-017, iOS + iPadOS: vaaka-asentojen korjaukset (GameOverView, moninpeli, ContentView, CelebrationView)

Käyttäjän pyyntö: "korjaa landscape tilat. kaikki ei näy ruudulla. esimerkiksi kun peli loppuu ja tulee lopetusruutu niin se ei näy kokonaan. tarkasta ja korjaa kaikki käännetyt asennot iphossa ja ipadissa".

- **Tunnus ja alusta**: BOD-017, iOS + iPadOS
- **Ongelmat ennen korjausta:**
  - `GameOverView`: Yksisarakkeinen kortti oli yli 480pt korkea; iPhonen vaakatilassa (korkeus 375–390pt) tuloskortin alalaita, laattalista sekä tärkeimmät toimintopainikkeet ("New Game", "Share") leikkautuivat näytön ulkopuolelle ilman mahdollisuutta vierittää.
  - `PassAndPlayViews`: Vuoropelin eräloppuruutu (`PassAndPlayRoundEndView`) ja lopputulosruutu (`PassAndPlayResultsView`) olivat myös kiinteitä pystysarakkeita ilman vaaka-asettelua tai `ScrollView`-käärettä, jolloin jatkopainikkeet ja tulostaulukot leikkautuivat vaakatilassa.
  - `CelebrationView`: Uuden ennätyksen merkki (`NewBestBadge`) ja täyden tyhjennyksen animaatio (`PerfectClearCelebration`) käyttivät suuria pystymarginaaleja (64pt / 70pt), jotka työnsivät tekstit vaakatilassa näytön reunojen yli.
  - `ContentView`: iPhonen vaakatilassa yläkulmien tilasto- ja asetuskuvakkeet (`cornerIcons`) leikkasivat pelilaudan puureunuksen päälle. Oikean sarakkeen noppakoko oli kiinteä eikä ottanut huomioon näytön matalaa pystytilaa, jolloin ohjaimet saattoivat siirtyä liian alas.
- **Toteutetut korjaukset:**
  - `GameOverView.swift`:
    - Lisätty `@Environment(\.verticalSizeClass) private var verticalSizeClass`.
    - Tunnistetaan kompakti vaakatila (`proxy.size.height < 560 || verticalSizeClass == .compact`).
    - Luotu `compactLandscapeCard`: mukautuva kahden sarakkeen kortti (vasen sarake: otsikko, tulos, aikatiedot, ennätyspaneeli; oikea sarake: avoimet laatat ja toimintopainikkeet).
    - Pienennetty fontteja (tulos 64pt -> 44pt) ja laattojen kokoa (36x34pt -> 32x30pt) kompaktissa tilassa.
    - Koko näkymä kääritty `ScrollView(.vertical, showsIndicators: false)` -kääreeseen `minHeight: proxy.size.height` -keskityksellä turvaverkoksi.
  - `PassAndPlayViews.swift`:
    - `PassAndPlayRoundEndView`: Lisätty 2-sarakkeinen korttiasettelu ja `ScrollView`-kääre.
    - `PassAndPlayResultsView`: Lisätty 2-sarakkeinen korttiasettelu (vasemmalla pelaajavoittaja ja Uusi peli, oikealla tiivis tuloslista) ja `ScrollView`-kääre.
  - `CelebrationView.swift`:
    - Lisätty pystykokoluokan tarkistus: `NewBestBadge` yläpadding 64 -> 20pt ja `PerfectClearCelebration` alapadding 70 -> 24pt kompaktissa tilassa.
  - `ContentView.swift`:
    - `iPhoneLandscapeGameView`: Siirretty tilasto- ja asetuskuvakkeet oikean sarakkeen otsikkoriville (`phoneLandscapeHeader`), jolloin puinen pelilauta vasemmalla saa täyden esteettömän tilan.
    - Noppakoko lasketaan dynaamisesti vapaan pystytilan mukaan (`heightConstrainedDie`).
    - Oikean puolen ohjauspaneeli kääritty `ScrollView(.vertical, showsIndicators: false)` -näkymään.
    - `iPadLandscapeGameView`: Ohjauspaneeli kääritty `ScrollView`-näkymään ja noppien koko suojattu matalille ikkunakorkeuksille (esim. Split View / Stage Manager).
  - `BoxOfDiceTests/OnboardingLayoutTests.swift`:
    - Lisätty `GameOverLayoutTests` kattamaan 7 eri laitegeometriaa (iPhone pysty/vaaka, pienin tuettu puhelin pysty/vaaka, iPad pysty/vaaka, iPad jaettu näkymä).

  - `BoxOfDiceApp.swift` & `BoxOfDice.xcodeproj`:
    - Lisätty iPhonen tuettuihin asentoihin `UIInterfaceOrientationPortraitUpsideDown` (aiemmin vain tavallinen Portrait ja Landscape Left/Right).
    - Lisätty iOS:n `AppDelegate` palauttamaan `.all` `supportedInterfaceOrientationsFor`:issa, jolloin laitteen kääntäminen ylösalaisin ei pakota sovellusta vaakatilaan, vaan säilyttää luonnollisen pystysuoran asennon (portrait).

- **Testit:**
  - `BuildProject`: onnistui ilman virheitä.
  - `RunAllTests`: 85/85 testiä läpäisi hyväksytysti (kaikki aiemmat 83 testiä + 2 uutta kattavaa vaaka-asettelutestiä).


---

## BOD-018: Oletusteema, noppien oletustyyli ja asetusten fonttikoko

- **Päivämäärä:** 2026-09-11
- **Konteksti:** Käyttäjän toive: tarkasta että oletuksena eka kertaa pelatessa on vihreä tausta ja valkoiset nopat, sekä korjaa teemojen nimien liian pieni fonttikoko asetuksissa.
- **Tarkistus ja havainnot:**
  - `@AppStorage`-oletusarvot olivat jo `theme: "greenFelt"` (vihreä verka) ja `diceStyle: "ivory"` (luonnonvalkoinen runko, mustat silmäluvut).
  - Useissa näkymissä (`ContentView`, `GameModeSelectionView`, `SettingsView`, `StatsView`, `WatchContentView`, `WatchSupportViews`) valinnaisen teeman purkamisen fallback-arvona oli kuitenkin vanha `?? .classicWood`. Jos teema-avainta ei ollut alustettu tai se oli virheellinen, taustaksi tuli puuteema vihreän sijaan.
  - Asetuksissa (`SettingsView.swift`) teeman, kielen ja noppa-animaation valitsimien fontti oli `GameTypography.label(size: 16)` / `size: 15`. Koska kyseessä on tiivistetty fontti (`AvenirNextCondensed-DemiBold`), se näytti ruudulla liian pieneltä.
- **Tehdyt muutokset:**
  - Kaikki `?? .classicWood` -varalogiikat vaihdettu muotoon `?? .greenFelt` (iOS ja watchOS).
  - Asetusnäkymässä (`SettingsView.swift`) teemojen nimien, rivivalitsimien ja arvojen fonttikoko kasvatettu kokoon 18 pt (`GameTypography.label(size: 18)`).
  - Watchin asetuksissa (`WatchSupportViews.swift`) teemavalinnan ja valintapainikkeiden fonttikokoja kasvatettu parempaa luettavuutta varten.
- **Testit:**
  - `BuildProject`: onnistui ilman virheitä.
  - `RunAllTests`: 85/85 testiä läpäisty hyväksytysti.
