# iOS 15 -yhteensopivuus, 23.9.2026

Pyynnön mukaisesti iOS-sovelluksen, testikohteen ja projektin vähimmäisversio muutettiin iOS 15.0:aan. watchOS-kohteen omaa alarajaa ei muutettu.

Uudemmilla iOS-versioilla sovellus käyttää edelleen samaa `NavigationStack`-navigointia (iOS 16+), `ShareLink`-jakoa (iOS 16+), automaattisesti sopivaa asetusriviä (iOS 16+), piilotettua vieritystaustaa (iOS 16+), koon mukaan määräytyvää vierityksen pomppimista (iOS 16.4+) ja nykyistä fonttipainoa. Niiden näkymärakennetta tai grafiikkaa ei vaihdettu. iOS 15 käyttää `NavigationView`-konttia, samaan jakotekstiin `UIActivityViewController`-arkkia ja kaksirivistä asetusriviä. `onChange`-sulut muutettiin iOS 15:n tukemaan yksiparametriseen muotoon; käsittelijöiden toiminta säilyi.

Kääntäjä löysi testikoodista iOS 17:n `Color.resolve(in:)`-käytön. Noppatyylien väritestissä käytetään nyt iOS 15:n `UIColor`-värikomponentteja ja samoja väri-/kontrastirajoja.

Varmistus:

- Xcode 27.0:n iOS Simulator Debug -build iOS 15.0 -targetilla onnistui.
- Rakennetun `BoxOfDice.app`-paketin `MinimumOSVersion` on 15.0.
- XCTest-ajo erillisessä iOS 27 -simulaattorissa: **86 testiä, 0 epäonnistumista** (136,2 s varsinaista testiaikaa).
- `git diff --check` puhdas.

Tässä ympäristössä on vain iOS 27 -simulaattoriruntime. iOS 15:n todellisen käytön, asetusrivien asettelun, navigoinnin ja jakoarkin tarkistus iOS 15 -laitteella jää erilliseksi hyväksymisvaiheeksi. Käännös ja uuden iOS:n testit eivät yksin todista vanhan käyttöjärjestelmän ajonaikaista toimintaa.
