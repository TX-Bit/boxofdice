# Box of Dice: kauppatekstien luonnos (7 kieltä)

Kirjoitettu 9.9.2026 osana BOD-014:ää (`docs/CLAUDE_UUDET_OMINAISUUDET.md`, Prompt 4). **Nämä ovat luonnoksia, ei julkaisuvalmiita kauppatekstejä.**

## Tila ja rajoitteet

- **Vain luonnos.** Ennen App Storeen tai Google Playhin lähettämistä on tarkistettava erikseen: kunkin kentän merkkimääräraja (App Storen kuvaus, aliotsikko, avainsanat; Google Playn lyhyt/pitkä kuvaus), tekstin täsmäävyys julkaistavaan buildiin, ja mahdolliset kauppakohtaiset tyyliohjeet.
- Tekstit kuvaavat **vain tässä työssä (BOD-011–013) todella toteutettuja Apple-alustan (iOS/iPadOS/watchOS) ominaisuuksia**. Ei mainita päivän haastetta, pilvisynkronointia, premium-ominaisuuksia, tilauksia eikä mitään "taattua onnistumista" tai vastaavaa liioittelevaa väitettä.
- Android-ominaisuuksia ei mainita eikä esitetä julkaistuina tai edes toteutettuina — tämä työ ei koskenut Androidia.
- Kaikki tekstit ovat tekoälyn kääntämiä; ei äidinkielisen puhujan tarkistusta (sama rajoite kuin `docs/LOKALISOINTI.md`:ssä).
- Teksteille tehtiin 10.9.2026 kielioppikatselmus sovelluksen käännösten katselmuksen yhteydessä. Korjattiin: saksan "unbegrenzt" (= rajoittamaton) → "ohne Zeitlimit" (ajastamaton) kolmessa kohdassa, saksan "leeres Feld" → "leeres Spielfeld" (sama laatta/lauta-sekaannus kuin sovelluksessa), italian "senza tempo" (= ajaton) → "senza limite di tempo" kahdessa kohdassa, sekä espanjan kuvatekstin "sin reloj" → "sin cronómetro". Katselmuksen teki tekoäly, ei ihminen.

## 1. Lyhyt kuvaus: Pikapeli ja aloitusopastus

### Englanti (en)
**Quick Game** is a new, untimed nine-tile mode — a shorter, simpler way to play Box of Dice. Roll two dice, close any combination of open tiles that matches the total, and once only tiles 1–6 remain you switch to a single die. Lower is better; an empty board scores zero. New players are guided through their very first roll with a short, skippable practice round right on the board — no separate tutorial screens, no account needed.

### Suomi (fi)
**Pikapeli** on uusi, ajastamaton yhdeksän laatan pelimuoto — lyhyempi ja yksinkertaisempi tapa pelata Noppalautaa. Heitä kaksi noppaa, sulje mikä tahansa avointen laattojen yhdistelmä, joka vastaa summaa, ja kun jäljellä ovat enää laatat 1–6, siirryt yhteen noppaan. Mitä pienempi tulos, sen parempi — tyhjä lauta on nolla pistettä. Uudet pelaajat opastetaan ensimmäiseen heittoonsa lyhyellä, ohitettavissa olevalla harjoituskierroksella suoraan laudalla — ei erillisiä opastusnäyttöjä, ei tiliä.

### Saksa (de)
**Schnellspiel** ist ein neuer Neun-Felder-Modus ohne Zeitlimit — eine kürzere, einfachere Art, Box of Dice zu spielen. Würfle mit zwei Würfeln, schließe eine beliebige Kombination offener Felder, die der Summe entspricht, und sobald nur noch die Felder 1–6 offen sind, wechselst du zu einem einzigen Würfel. Weniger ist besser — ein leeres Spielfeld ergibt null Punkte. Neue Spieler werden mit einer kurzen, überspringbaren Übungsrunde direkt auf dem Spielfeld durch ihren ersten Wurf geführt — keine separaten Anleitungsbildschirme, kein Konto nötig.

### Ranska (fr)
**Partie rapide** est un nouveau mode à 9 cases, sans chronomètre — une façon plus courte et plus simple de jouer à Box of Dice. Lancez deux dés, fermez n'importe quelle combinaison de cases ouvertes correspondant au total, et dès qu'il ne reste que les cases 1 à 6, vous passez à un seul dé. Moins, c'est mieux — un plateau vide vaut zéro point. Les nouveaux joueurs sont guidés lors de leur premier lancer par un court tour d'entraînement, que l'on peut ignorer, directement sur le plateau — pas d'écrans de tutoriel séparés, pas de compte nécessaire.

### Espanja (es)
**Partida rápida** es un nuevo modo sin límite de tiempo con nueve casillas — una forma más corta y sencilla de jugar a Box of Dice. Lanza dos dados, cierra cualquier combinación de casillas abiertas que coincida con el total y, cuando solo queden abiertas las casillas 1 a 6, pasarás a usar un solo dado. Menos es mejor: un tablero vacío vale cero puntos. A los nuevos jugadores se les guía en su primer lanzamiento con una breve ronda de práctica que se puede omitir, directamente en el tablero — sin pantallas de tutorial aparte, sin necesidad de cuenta.

### Italia (it)
**Partita rapida** è una nuova modalità senza limite di tempo con nove caselle — un modo più breve e semplice di giocare a Box of Dice. Lancia due dadi, chiudi qualsiasi combinazione di caselle aperte che corrisponda al totale e, quando restano aperte solo le caselle 1-6, passerai a un solo dado. Meno è meglio: un tabellone vuoto vale zero punti. I nuovi giocatori vengono guidati nel loro primo lancio con un breve turno di pratica facoltativo, direttamente sul tabellone — niente schermate di tutorial separate, nessun account necessario.

### Brasilianportugali (pt-BR)
O **Jogo rápido** é um novo modo sem cronômetro, com nove casas — uma forma mais curta e simples de jogar Box of Dice. Lance dois dados, feche qualquer combinação de casas abertas que corresponda à soma e, quando restarem abertas apenas as casas de 1 a 6, você passa a usar um só dado. Menos é melhor — um tabuleiro vazio vale zero pontos. Novos jogadores são guiados no primeiro lançamento por uma breve rodada de prática, que pode ser pulada, direto no tabuleiro — sem telas de tutorial separadas, sem necessidade de conta.

## 2. Kolme lyhyttä kuvakaappaustekstiä

| # | en | fi | de | fr | es | it | pt-BR |
|---|---|---|---|---|---|---|---|
| 1 | Quick Game: 9 tiles, no timer | Pikapeli: 9 laattaa, ei ajastinta | Schnellspiel: 9 Felder, ohne Zeitlimit | Partie rapide : 9 cases, sans chrono | Partida rápida: 9 casillas, sin cronómetro | Partita rapida: 9 caselle, senza cronometro | Jogo rápido: 9 casas, sem cronômetro |
| 2 | Learn in your first roll | Opi jo ensimmäisellä heitolla | Lerne mit deinem ersten Wurf | Apprenez dès votre premier lancer | Aprende desde tu primer lanzamiento | Impara fin dal primo lancio | Aprenda já no primeiro lançamento |
| 3 | Lower is better — beat your best | Mitä pienempi, sen parempi — voita ennätyksesi | Weniger ist besser — schlage deinen Rekord | Moins, c'est mieux — battez votre record | Menos es mejor — supera tu récord | Meno è meglio — batti il tuo record | Menos é melhor — supere seu recorde |

## 3. What's New -luonnos

### Englanti (en)
- New: Quick Game — a shorter, untimed nine-tile mode.
- New: a short, skippable practice round for your very first game.
- Added German, French, Spanish, Italian, and Brazilian Portuguese.
- Small fixes and improvements.

### Suomi (fi)
- Uutta: Pikapeli — lyhyempi, ajastamaton yhdeksän laatan pelimuoto.
- Uutta: lyhyt, ohitettavissa oleva harjoituskierros ensimmäistä peliäsi varten.
- Lisätty saksa, ranska, espanja, italia ja brasilianportugali.
- Pieniä korjauksia ja parannuksia.

### Saksa (de)
- Neu: Schnellspiel — ein kürzerer Neun-Felder-Modus ohne Zeitlimit.
- Neu: eine kurze, überspringbare Übungsrunde für dein allererstes Spiel.
- Deutsch, Französisch, Spanisch, Italienisch und brasilianisches Portugiesisch hinzugefügt.
- Kleinere Korrekturen und Verbesserungen.

### Ranska (fr)
- Nouveau : Partie rapide — un mode à 9 cases plus court, sans chronomètre.
- Nouveau : un court tour d'entraînement, à ignorer si vous le souhaitez, pour votre toute première partie.
- Ajout de l'allemand, du français, de l'espagnol, de l'italien et du portugais brésilien.
- Petites corrections et améliorations.

### Espanja (es)
- Nuevo: Partida rápida, un modo de nueve casillas más corto y sin límite de tiempo.
- Nuevo: una breve ronda de práctica, que se puede omitir, para tu primera partida.
- Se añadieron alemán, francés, español, italiano y portugués de Brasil.
- Pequeñas correcciones y mejoras.

### Italia (it)
- Novità: Partita rapida — una modalità più breve, senza limite di tempo, con nove caselle.
- Novità: un breve turno di pratica, facoltativo, per la tua primissima partita.
- Aggiunti tedesco, francese, spagnolo, italiano e portoghese brasiliano.
- Piccole correzioni e miglioramenti.

### Brasilianportugali (pt-BR)
- Novidade: Jogo rápido — um modo mais curto, sem cronômetro, com nove casas.
- Novidade: uma breve rodada de prática, que pode ser pulada, para o seu primeiro jogo.
- Adicionados alemão, francês, espanhol, italiano e português do Brasil.
- Pequenas correções e melhorias.

## Käytetyt tuotenimet ja termit (ei käännetä eri tavoin eri kentissä)

- Tuotenimi: "Box of Dice" (kaikissa kielissä muuttumattomana).
- Pelimuodon nimi: englanti "Quick Game", suomi "Pikapeli", saksa "Schnellspiel", ranska "Partie rapide", espanja "Partida rápida", italia "Partita rapida", pt-BR "Jogo rápido" — samat käännökset kuin sovelluksen omassa `AppLanguage`/`GameMode`-käyttöliittymässä (`docs/LOKALISOINTI.md`), ei erillisiä markkinointitermejä.

## Ennen kaupan lähetystä tarkistettava

- [ ] Jokaisen kentän merkkimäärä kaupan rajoihin nähden (lyhennä tarvittaessa, älä käännä lyhennettyä versiota uudelleen).
- [ ] Tekstien täsmääminen todelliseen julkaistavaan build-versioon (versio-/build-numero, näkyvät ominaisuudet).
- [ ] Kuvakaappausten kuvatekstien täsmääminen todellisiin kuvakaappauksiin joka kielellä.
- [ ] Ihmisen (mieluiten äidinkielisen puhujan) katselmus kaikille seitsemälle kielelle ennen julkaisua — ei tehty tässä työssä.
- [ ] App Store- ja Google Play -kohtaiset lisävaatimukset (esim. avainsanakenttä, ikäluokitus, kauppakohtaiset kuvakoot) tarkistettava erikseen; tämä dokumentti ei kata niitä.
