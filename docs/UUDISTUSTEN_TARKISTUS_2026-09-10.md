# Uudistusten tarkistus 10.9.2026

Tarkastettu Clauden toteutus suhteessa `CLAUDE_UUDET_OMINAISUUDET.md`:n tehtäviin BOD-011–014. **Pikapelin peruslogiikka on kunnossa, mutta opastusta ja lokalisaatiota ei vielä voi hyväksyä kokonaan valmiiksi.**

## 1. Korjattava ennen julkaisua: ensimmäisen opastuksen taustatallennus

**Tila: toistettu iOS-simulaattorissa. Watchissa sama rakenne havaittu koodista, ei ajettu.**

- `BoxOfDice/ContentView.swift:164`: taustalle siirtyminen kutsuu aina `persistCurrentGame()`.
- `ContentView.swift:1040`: tallennus ei huomioi, että ensikäynnistyksen opastus on kesken.
- Opastuksella on oma mallinsa, mutta sen alla oleva normaali `GameViewModel` sisältää oletuksena 12 laatan Classic-pelin.
- `ContentView.swift:956`: seuraava käynnistys palauttaa tämän tallennuksen ennen opastuksen tarpeen tarkistamista.
- Watchin vastaavat kohdat: `WatchApp/WatchContentView.swift:252`, `:633`, `:697`.

Käyttäjäpolku: puhdas asennus → opastus näkyviin → sovellus taustalle ennen opastuksen päättämistä → sovellus myöhemmin käynnistyy uudelleen. Koodin palautusjärjestyksen perusteella tuloksena on Classic-peli, vaikka käyttäjän piti päästä opastuksen kautta yhdeksän laatan Pikapeliin.

**Ajonaikainen näyttö:** erillisessä tarkistuskopiossa lisätty XCTest esitti oikean `ContentView`-näkymän `UIHostingController`-ikkunassa, varmisti ettei alkutilassa ollut tallennusta ja vaihtoi näkymän scenePhase-ympäristön active → background. Alkutilan assert meni läpi. Jälkimmäinen assert epäonnistui: `GameSaveStore.load()` palautti `gameMode=classic`, `tileCount=12`, kaikki laatat auki. Testi ei tehnyt varsinaista prosessin tappoa/uudelleenkäynnistystä; palautuksen seuraus on varmistettu koodipolusta.

**Korjausohje Claudelle:** estä normaalin pelin tallentaminen silloin, kun ensikäynnistyksen opastus on kesken, molemmilla alustoilla. Älä estä asetuksista avatun uusintaopastuksen alla olevan oikean pelin tallennusta. Opastuksen valmistumisen ja ohituksen pitää käynnistää ja tallentaa uusi Pikapeli. Säilytä oikeiden vanhojen tallennusten palautusprioriteetti. Lisää integraatiotestit ensikäynnistyksen taustalle siirtymiselle ja uusintaopastuksen aikaisen pelin säilymiselle; pelkkä `OnboardingViewModel`-yksikkötesti ei kata tätä.

## 2. Watchin opastus jäi osittain vajaaksi

**Tila: koodihavainto, ei Watch-käyttöliittymäajoa.**

`WatchApp/WatchOnboardingView.swift` käyttää samaa opastusmallia, mutta ei näytä valittujen laattojen summaa. Valintavaiheessa näkyvät esimerkkiohje, laatat ja Vahvista-painike, joka pysyy väärällä summalla poissa käytöstä. Aloittelija ei näe, paljonko valinnasta puuttuu. iOS näyttää `Selected %lld` -summan.

Watchin loppuvaiheesta puuttuu myös iOS:n `Empty board = 0.` -selitys. Watchin normaalissa pelinäkymässä ei ole noppien summan näyttöä; iOS:n uusi oletus `showDiceTotal = true` ei siksi toteuta summan näkyvyyttä kellossa. Opastuksen esimerkkiteksti kyllä kertoo heiton summan 8.

**Korjausohje:** lisää Watchiin valinnan summa, tavoitesumma ja nollapisteen selitys. Toteuta normaalin pelin summan näkyvyys sovitun oletuksen mukaan. Käytä yhteisiä käännösavaimia ja varmista kapean kellonäkymän luettavuus.

## 3. Käännöksissä on vielä korjattavaa

**Tila: koodin ja merkkijonojen tarkistus.**

Tarkat avaimet ja ehdotukset kaikille seitsemälle kielelle: [KIELITARKISTUS_2026-09-10.md](KIELITARKISTUS_2026-09-10.md).

Keskeiset asiat:

- Saksan `Nur ein Würfel verwenden` → `Nur einen Würfel verwenden`.
- Yksikkö/monikko puuttuu: esimerkiksi `1 turns`, `1 vuoroa` ja `1 turnos`.
- `Shortest clear` on käännetty nopeudeksi, vaikka mittari laskee siirtoja.
- Suomen ”Näytä silmäluku” tarkoittaa tässä noppien summan näyttämistä.
- iOS:n laattojen VoiceOver-kutsut eivät vastaa käännettyjä avaimia (`TileView.swift:49`). Käännöstiedoston eheys ei riitä, jos käyttöliittymä ei kutsu avainta.

Clauden viimeisimmät artikkeli-, kongruenssi-, lista- ja kauppatekstikorjaukset on huomioitu. Niitä ei raportoida enää avoimina vikoina.

## 4. Hyvin toteutetut kohdat

| Tehtävä | Näyttö |
|---|---|
| BOD-011: yhdeksän laatan Pikapeli | Oma `quickGame`-tunnus, 9 laattaa ja 45 alkupistettä, aluksi kaksi noppaa, yksi noppa kun suuret laatat suljettu, ei ajastinta. QuickGameTests läpi. |
| Classicin säilyminen | Classic edelleen 12 laattaa. Pikapeli ei korvaa vanhaa enum-tunnusta. Tallennusten ja tilastojen testit läpi. |
| Pikapelin tilastot | Oma tilastointi; ei sekoitu Classicin tuloksiin. |
| Opastuksen pelilogiikka | Oma malli, heitto 3 + 5, hyväksyy 8:n ja 3 + 5:n lisäksi myös 1 + 2 + 5:n. Väärä summa ei lukitse peliä. Kahdeksan mallin testiä läpi. |
| Opastuksen päättäminen | Ensikäynnistyksen valmistuminen/ohitus käynnistää Pikapelin. Asetuksista avatulla opastuksella erillinen paluupolku. Kooditarkistus; koko vuorovaikutusketjua ei ajettu käyttöliittymätestinä. |
| iOS:n summan oletusasetus | Oletus on true sekä pelinäkymässä että asetuksissa; aiemmin tallennettu false säilyy. |
| Viisi uutta kieltä | de/fr/es/it/pt-BR mukana kummankin kohteen resursseissa; en ja fi säilyvät. Avainten ja formaattiparametrien tarkistukset läpi. |
| Dokumentointi | Toteutukset ja testien rajoitteet on kirjattu. Kauppatekstit ovat paikallisia luonnoksia. |

## 5. Testinäyttö ja rajat

Oma ajo erillisessä iPhone 17 Pro / iOS 27 -simulaattorissa, Xcode-beta:

- Projektin nykyinen XCTest-kokonaisuus: **62 testiä, 0 epäonnistumista**, noin 84,5 sekuntia varsinaista testiaikaa.
- Erillinen ensikäynnistyksen integraatiotesti: **1 testi, 1 odotetun vaatimuksen epäonnistuminen**. Todentaa kohdassa 1 kuvatun Classic-tallennuksen.
- 12 `.strings`-tiedoston syntaksi, duplikaattiavaimet ja formaattiparametrit: ei virheitä.
- Watch-lähteiden tarkistus ei korvaa Watch-ajonaikaista testausta. Käytettävissä ei ole Watch-simulaattorin runtimea.
- iPadin, iPhonen vaaka-asennon, kaikkien kielten kaikkien opastusvaiheiden, VoiceOverin ja suurimpien tekstikokojen kattavaa visuaalista ajoa ei tehty tässä tarkistuksessa.
- Opastuksen iOS-asettelu on pystysuora, sisältää kiinteitä laattamittoja eikä vieritystä. Matala vaakanäkymä on siksi erityinen tarkistuskohde; sitä ei tässä merkitä toistetuksi leikkautumisviaksi.
- Clauden lokin väite, ettei ympäristössä ole iPad-simulaattoria, ei vastaa tämän tarkistuksen laitelistaa: iPad-simulaattoreita on saatavilla. Tarkistus on siis tekemättä, ei ympäristön perusteella mahdoton.
- QuickGameTestsin vanhaa Classicia kuvaava tallennustesti luo tallennuksen nykyisellä koodilla. Se ei yksin todista aidon vanhan julkaisuversiotallennuksen migraatiota.

Testiajo tehtiin kopiosta `/private/tmp/BODFeaturesReview0910`; tuotantokoodia ei muutettu. Swift-lähdekoodin tiivisteet täsmäsivät varsinaiseen projektiin ajojen jälkeen. Dokumentteihin ja lopuksi suomen merkkijonoihin tuli samanaikaisesti Clauden tarkennuksia. Suomen muutokset luettiin erikseen: sanajärjestys, Valinta-otsikko ja Noppalauta-pelissä-yhdyssana; ne eivät muuta toistettua tallennusvikaa. 62 testin tulos koskee ennen näitä viimeisiä suomen sanamuutomuutoksia otettua kopiota.

Paikalliset todisteet (väliaikaisia, eivät versionhallinnan pysyviä artefakteja):

- `/private/tmp/BODFeaturesReview0910-tests.log`
- `/private/tmp/BODFeaturesReview0910.xcresult`
- `/private/tmp/BODLifecycleReview0910-tests.log`
- `/private/tmp/BODLifecycleReview0910.xcresult`

Epäonnistuneen testin jälkeinen Xcoden diagnostiikkakeräys antoi lisäksi `simctl`-polkuvirheen. Varsinainen XCTest ehti suorittua ja raportoi nimenomaan odottamattoman Classic-tallennuksen; diagnostiikkavirhe ei ollut assertin syy.

## Android-vertailu

Androidia ei tutkittu. Käytä siellä samoja hyväksymiskriteerejä: 9 laatan tila omalla tunnuksellaan ja tilastoillaan, 1/2 nopan sääntö, opastuksen erillinen tallennustila, ensimmäisen opastuksen taustoitus ja prosessin uudelleenkäynnistys, uusintaopastuksen aikaisen oikean pelin säilyminen sekä käännösten monikot ja saavutettavuustekstit. Älä merkitse Android-vikaa toistetuksi Apple-havainnon perusteella.

## Korjausjärjestys

1. Ensikäynnistyksen taustatallennus ja sitä kattava integraatiotesti.
2. Watchin puuttuvat summat ja loppuohje.
3. Käännösten merkitys-/kielioppivirheet, monikot ja VoiceOver-avaimet.
4. Opastuksen kaikki vaiheet iPhonen molemmissa suunnissa, iPadissa ja Watchissa sekä suurilla teksteillä.
5. Päivitä seurannan hyväksyntä vasta näiden tarkistusten jälkeen.
