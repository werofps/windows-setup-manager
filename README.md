\# Windows Setup Manager



\## Tekijä



Nimi: Tuukka



Kurssi: TAK



\## Projektin tarkoitus



Windows Setup Manager on PowerShellillä tehty Windows 11

\-automatisointityökalu.



Työkalun avulla käyttäjä voi käynnistää eri käyttötarkoituksiin

tarkoitettuja ohjelmia, verkkosivuja ja kansioita yhdellä valinnalla.



\## Profiilit



Työkalussa on kolme profiilia:



\- Gaming

\- Koulu

\- Videoeditointi



\## Ominaisuudet



Ohjelma pystyy:



\- käynnistämään ohjelmia

\- tarkistamaan, onko ohjelma jo käynnissä

\- avaamaan verkkosivuja

\- avaamaan kansioita

\- sulkemaan valittuja prosesseja

\- lukemaan asetukset JSON-tiedostoista

\- käsittelemään virheitä try/catch-rakenteella

\- kirjoittamaan tapahtumat lokitiedostoon



\## Projektin rakenne



WindowsSetupManager/



\- main.ps1

\- functions.ps1

\- config/

&#x20; - gaming.json

&#x20; - school.json

&#x20; - editing.json

\- logs/

&#x20; - launcher.log



\## Käynnistäminen



PowerShellissä:



```powershell

cd C:\\WindowsSetupManager

.\\main.ps1

