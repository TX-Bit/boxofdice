# Claude: kirjausohje korjausprompteihin

Liitä seuraava ohje jokaisen korjauspromptin yhteyteen. Tunnukset BOD-001–BOD-006 vastaavat keskustelun kuutta promptia järjestyksessä.

```text
Pidä työstä kirjaa tiedostossa docs/KORJAUSSEURANTA.md.

Lue seuranta ennen muutoksia ja tunnista tätä tehtävää vastaava BOD-tunnus.
Varmista havainto nykyisestä koodista. Säilytä valmiit käyttäjän muutokset.

Päivitä vain tutkimasi alustojen tilat. Lisää korjauksen jälkeen muutoslokiin
päivämäärä, BOD-tunnus, alusta, ennen/jälkeen-käyttäytyminen, muutetut tiedostot,
mahdolliset tallennusdatamuutokset ja tarkat ajetut testit tuloksineen.
Kirjaa myös ajamatta jääneet testit, epäonnistumiset ja rajoitteet.

Älä merkitse suunnitelmaa tehdyksi korjaukseksi tai koodimuutosta testatuksi
ilman näyttöä. Pelkkä build ei varmista käyttäytymistä. Älä merkitse Androidia
korjatuksi tai virheettömäksi Apple-version perusteella.

Jos toteutus poikkeaa seurannan tavoitteesta, kirjaa syy ja päivitä tavoite
vastaamaan tehtyä ratkaisua. Säilytä aikaisemmat lokimerkinnät.
Lisää commit ja julkaisuversio vain, jos ne ovat olemassa; älä tee niitä
pelkän kirjausohjeen perusteella. Anna lopuksi lyhyt yhteenveto ja linkki lokiin.
```

## Prompti myöhempään Android-kartoitukseen

Anna tämä Android-repositoriossa työskentelevälle Claudelle yhdessä ajantasaisen `KORJAUSSEURANTA.md`-tiedoston kanssa:

```text
Vertaa tämän Android-projektin toimintaa liitteen Box of Dice -korjausseurantaan.
Tee ensin kartoitus; älä muuta sovelluskoodia tässä vaiheessa.

Tutki BOD-001–BOD-006 erikseen nykyisestä Android-koodista. Apple-version löydös
on tarkistuslista, ei näyttö Android-viasta. Kirjaa jokaisesta:
- löytyykö vastaava ominaisuus ja missä tiedostoissa se toteutetaan
- löytyykö sama ongelma, onko se jo estetty vai puuttuuko ominaisuus
- koodiperustelu ja mahdollinen toistotesti tuloksineen
- tarvittava Android-kohtainen korjaus ja hyväksymistesti
- erot Apple-version tavoitekäyttäytymiseen ja tallennusformaattiin.

Käytä samoja BOD-tunnuksia. Merkitse tutkimatta jäävät asiat rehellisesti.
Vertaa satunnaisuudessa myös algoritmia ja noppaluvuksi muunnosta; sama seed
ei yksin takaa samoja heittoja eri kielillä. Vertaa aikapisteissä koko pelin
ajastusta, älä pelkkää animaatiota. Testaa palautumisessa prosessin kuolema.

Tallenna Android-repositorioon docs/ANDROID_VERTAILU.md, jossa on päiväys,
vertailuun käytetyn Apple-seurannan päiväys/commit jos saatavilla, BOD-kohtainen
taulukko, tiedostoviitteet ja testinäyttö. Älä ylikirjoita olemassa olevaa
vertailua lukematta sitä; päivitä taulukko ja säilytä aiemmat lokimerkinnät.
Älä väitä muuttaneesi Apple-repositorion seurantaa, jos sinulla ei ole siihen pääsyä.
```
