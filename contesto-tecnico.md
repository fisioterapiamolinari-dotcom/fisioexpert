# Contesto tecnico — Fisio Expert (Sito & Automazioni)

> File di contesto stabile del progetto. Contiene tutto ciò che serve per generare o
> modificare pagine HTML, form e workflow n8n senza chiedere informazioni già presenti qui.
> Ultimo aggiornamento: agosto 2026.

---

## 1. CONTESTO

- **Studio:** Fisio Expert Roma — fisioterapista **Gianmarco Molinari**.
- **Dominio:** `https://fisioexpert.it`
- **Email mittente:** `Gianmarco FisioExpert <info@fisioexpert.it>` (reply-to `info@fisioexpert.it`).
- **WhatsApp business / notifiche personali:** `+39 328 273 8164` → `393282738164`
- **WhatsApp mittente (Meta Phone Number ID):** `1052997891230176`
- **P.IVA:** 14315091000
- **Fuso orario:** `Europe/Rome` (usalo sempre in date, Calendar, Luxon).
- **Calendar di lavoro:** `fisioterapiamolinari@gmail.com` (cachedResultName "Lavoro").
- **Istanza n8n:** `https://gianmarcomolinari.app.n8n.cloud`

### Studi
| Studio | Indirizzo | Giorni |
|---|---|---|
| EUR | Viale Pasteur 56 | Mar/Gio 13:00–20:00 · Sab 08:00–14:00 |
| Fleming | Via Città di Castello 20 | Mer/Ven 09:00–20:00 |

Durata seduta standard: **45 minuti**.

---

## 2. DESIGN SYSTEM (vale per ogni pagina HTML)

```css
--ink: #1a1a1a;  --ink-soft: #4a4a4a;  --ink-muted: #8a8a8a;
--accent: #f47920;  --accent-light: rgba(244,121,32,0.12);  --accent-dark: #d4660e;
--warm: #f8f4ef;  --warm-dark: #ede8e0;  --white: #ffffff;
--border: rgba(26,26,26,0.1);
--serif: 'DM Serif Display', Georgia, serif;   /* titoli */
--sans: 'DM Sans', system-ui, sans-serif;      /* corpo */
--mono: 'Montserrat', system-ui, sans-serif;   /* logo, label, eyebrow */
```

Ogni pagina è **self-contained**: CSS e JS inline nello stesso file, nessun build step,
nessuna dipendenza npm. I font arrivano da Google Fonts via `<link>`.

---

## 3. LOGO E ASSET (regola fissa)

Asset in root del repo:
- `/logo.png` — wordmark 671×135, 4,4 KB. **È l'unico logo valido.**
- `/logo-small.png` — 716×144, per generare il base64 delle pagine offline.
- `/gianmarco.jpg` — foto 1200×805, 38 KB.
- `/favicon.ico`

### Regole d'uso
- **Pagine del sito (online):** riferimento a `/logo.png`. **Mai base64.**
- **Pagine-modulo offline** (`moduli-fisioexpert`, `questionario-visita`, `test-funzionali`):
  base64 inline, perché girano su iPad in studio senza rete. Usa l'asset di `logo-small.png`.
- **Header:** `height: 36px; width: auto; display: block` — identico su desktop e mobile.
  Non mettere override a 30px nei media query.
- **Footer:** `height: 24px` con `filter: invert(1); opacity: 0.85`.
- **Sempre** `width="671" height="135"` sul tag `<img>`: riserva lo spazio ed evita il
  layout shift (CLS) mentre l'immagine carica.
- **Fallback testuale** con id proprio, mai `nextElementSibling`:

```html
<a href="https://fisioexpert.it" class="logo-link">
  <img src="/logo.png" width="671" height="135" alt="fisio·expert" class="header-logo"
       onerror="this.style.display='none'; document.getElementById('logoFallback').style.display='block';">
  <span id="logoFallback" class="logo-fallback">fisio<b>·</b>expert</span>
</a>
```

⚠️ Esiste un vecchio asset `logo-fisioexpert-header.png` (808×302) con margine trasparente
enorme e puntino arancione sgranato. **Non usarlo.** A parità di `height` il marchio si
vede il 40% più piccolo: è l'origine storica delle altezze incoerenti (30/32/36/56/72px).

---

## 4. DEPLOY

- **Repo:** `github.com/fisioterapiamolinari-dotcom/fisioexpert` — branch `main`, root.
- **Hosting:** GitHub Pages + `CNAME` → `fisioexpert.it`. Presente `.nojekyll`.
- **Flusso:** l'utente carica i file **direttamente dall'interfaccia web di GitHub**
  (Add file → Upload files, oppure la matita per editare inline). Non usa VS Code né git
  da terminale. Quando proponi una modifica, tienilo presente: meglio blocchi piccoli da
  sostituire con la matita che file interi da ricaricare, se il file è grande.
- Online in 1–2 minuti dal commit. Per verificare usare **finestra anonima** (la cache
  del browser nasconde gli aggiornamenti).
- ⚠️ Nomi file **case-sensitive**. Le pagine-modulo sono state rinominate in minuscolo con
  trattini (`questionario-visita.html`, `template-soap.html`, `return-to-play.html`,
  `test-funzionali.html`, `scheda-esercizi.html`): non tornare ai nomi con spazi.
- Le pagine blog vivono in **`/blog/`** (vedi canonical). Le altre in root.

---

## 5. FOGLI GOOGLE (ID + struttura)

### 5.1 Super Agenda — `1QGMNLXBhSTmuZPVWKhHp2BCF3SufZ8EvwTto2e1oJO4`

**Tab "CRM"** — `sheetId = 25314751`
- **Header su riga 2, primi dati su riga 3** (`headerRow: 2`, `firstDataRow: 3`).
- Colonne: `Nome` (A), `Cognome` (B), `Nome Completo` (C), `Telefono` (D), `Email` (E),
  `Problema` (F), `Note` (G), `Luogo` (H), `Prezzo` (I), `Reminder Inviato` (J).
- Alcuni workflow leggono anche "Prima Visita" (sì/no) — verificarne la presenza prima di usarla.
- Match paziente ↔ evento Calendar: `Nome Completo` vs titolo evento, con normalizzazione flessibile.

**Tab "Agenda2026"** — `sheetId = 308272554`
- Colonne: `Data`, `Nome Paziente`, `Luogo`, `Pagato`, `Check`, `Prezzo Lordo`, `Tara`,
  `Prezzo Netto`, `Fattura N°`, `Note`, `Mese`.
- Append giornaliero delle visite svolte.

### 5.2 FisioExpert - Recensioni — `1Sppano6ttmVpkg1VOkvNnZ3v45pTo3w_fX4uWISj3hw`
- **Tab "Richieste Recensione"** — `gid = 2074500212` (in un nodo compare anche `2006620288`).
  Colonne: `Nome Paziente`, `Telefono`, `Email`, `Data Ultima Visita`, `Data Invio Richiesta`,
  `Canale Invio`, `Stato Invio`, `Recensione Ricevuta`, `Data Prossimo Invio`, `Note`.
- **Tab "Visite"**
  Colonne: `ID Evento Calendar`, `Nome Paziente`, `Data Visita`, `Ora`, `Durata (min)`,
  `Tipo Visita`, `Richiesta Recensione Inviata`, `Data Invio Richiesta`.

### 5.3 Fatture 2026 — `17K8qxZJ3Rk2HQI9TEwgrhho5RaCI8AWuHjkAIVY5tCA`
- Tab principale `gid = 1984522596`.
- Tab **CRM**: A `Nome Completo`, B `Indirizzo Res.`, C `CAP`, D `Codice Fiscale`, E `Sesso` (M/F).
- Struttura oltre la colonna E **non nota**: chiedere all'utente se un workflow la tocca.

---

## 6. WORKFLOW n8n ATTUALI

### WF1 — Prenotazione (Webhook)
Trigger: `POST /webhook/fisioexpert-booking` (responseMode: responseNode).
Flusso: rispondi 200 → leggi CRM → verifica paziente (email o telefono normalizzati) →
Edit Fields → IF "Paziente esiste?" → email conferma SMTP + (se nuovo) crea paziente in CRM
(`appendOrUpdate`, match su Email).
Email: data `dd/mm/yyyy`, orario dal body, link policy cancellazione, avviso WhatsApp giorno prima.
🔴 **Bug aperto:** i rami dell'IF "Paziente esiste?" risultano invertiti o vuoti; "Edit Fields"
alimenta sia l'email sia l'IF. Da rivedere se si interviene qui.

### WF2 — Promemoria + dati fattura (Schedule 18:00)
Eventi Calendar di **domani** → CRM → incrocio per nome (JS fuzzy) → filtra chi ha email valida →
prepara link form fattura + link pagamento SumUp → mail SMTP → segna `Reminder Inviato = SI`.

### WF3 — Reminder WhatsApp con AI Agent (Schedule 9:00)
AI Agent (`claude-sonnet-4-5-20250929`) con tool Get Events + Get Sheets → array JSON pazienti →
Code estrae il JSON → IF tipo=paziente → template WhatsApp `reminder_appuntamento` via Meta Graph →
fallback se paziente non trovato → notifica finale.

### WF4 — Registro visite (Schedule 21:00)
Eventi di **oggi** → JS calcola il Luogo:
- Lun → Parioli ⚠️ **studio non più attivo**, ramo da rimuovere dal codice JS
- Mar/Gio < 13:00 → Double A · Mar/Gio ≥ 13:00 → Eur
- Mer/Ven → Fleming
- Sab → Eur

Poi `Prezzo` dal CRM (match su `Nome Completo`) → append in "Agenda2026" (Data `dd/mm/yy`, Mese in italiano).

### WF5 — Richiesta recensioni (Schedule 9:05)
Eventi di **8 giorni fa** → estrae pazienti (salta "blocca/ferie/libero") → legge "Richieste
Recensione" → verifica idoneità (no richiesta < 3 mesi, no già recensito, no bloccato) → cerca
contatto nel CRM → pulisce telefono (`+39`) → template WhatsApp `richiesta_recensione_fisioswim` →
salva in "Richieste Recensione" + "Visite" → notifica Telegram.

---

## 7. CREDENZIALI E RIFERIMENTI

> 🔒 **Nessun token in chiaro in questo file.** Nei JSON usa sempre il riferimento alla
> credenziale n8n, mai il valore del token. Se un nodo richiede il Bearer di Meta, punta
> alla credenziale `eKTQazP1PUTwnzZg`.

### Credenziali n8n (ID da usare nei nodi)
| Servizio | ID | Nome |
|---|---|---|
| Google Sheets OAuth2 | `b7PQ2sKfA2K2yMtd` | Google Sheets OAuth2 API |
| Google Sheets OAuth2 (alt) | `Qpm8riz4rGDgJfdf` | Fisioterapiamolinari |
| Google Calendar (Lavoro) | `s9epdeTZ8jrnD4HH` | Fisioterapiamolinari@gmail.com |
| Google Calendar (alt) | `LVoZNUNNRfyRFJ2I` | Google Calendar OAuth2 API |
| SMTP | `0C1Z8cG4ksiAMz5B` | SMTP account |
| Anthropic API | `EVdPYpF9F221oBn4` | Anthropic account |
| HTTP Header Auth (Meta WhatsApp) | `eKTQazP1PUTwnzZg` | Header Auth account |
| Telegram | `UdHBiBEBc6stIEeV` | Recensioni_fisiobot |

### Meta WhatsApp
- Phone Number ID: `1052997891230176`
- Endpoint: `https://graph.facebook.com/v19.0/1052997891230176/messages`
- Header: `Content-Type: application/json` + auth via credenziale `httpHeaderAuth`.
- Template esistenti:
  - `reminder_appuntamento` (it) — params: 1) nome, 2) dataLeggibile
  - `richiesta_recensione_fisioswim` (it) — params: 1) primo_nome

### Altri riferimenti
- Telegram chat_id notifiche: `775886916`
- Link pagamento SumUp: `https://pay.sumup.com/b2c/X2SS8AOEG6`
- Link form dati fattura: `https://www.fisioexpert.it/dati-fattura.html?nome=<encoded>`
- instanceId n8n: `01f7b850201f6974812f19517360ecd1e7d6af0464daf929a8e396f935de11e7`

---

## 8. CONVENZIONI TECNICHE n8n

- **Lettura CRM:** `headerRow: 2`, `firstDataRow: 3` — l'header NON è in riga 1.
- **Telefono in scrittura su Sheets:** anteporre `'` per forzare il testo, altrimenti Sheets
  mangia lo zero iniziale e il `+`.
- **Normalizzazione nomi per il match:** lowercase + `normalize('NFD')` per togliere accenti +
  rimozione caratteri non alfanumerici + collapse spazi.
- **Telefono per Meta:** senza `+` nel campo `to` (`393282738164`); con `+39` per CRM e display.
- **Date IT (Luxon):** `setZone('Europe/Rome').setLocale('it').toFormat('cccc d MMMM yyyy')`, ora `HH:mm`.
- **WhatsApp:** nodo `httpRequest` v4.2, POST JSON, auth `httpHeaderAuth`.
- **Email:** nodo `emailSend` v2.1, credenziale SMTP, mittente `Gianmarco FisioExpert <info@fisioexpert.it>`.
- **CRM:** `appendOrUpdate`, match su `Email` o `Nome Completo` a seconda del caso.
- Nomi nodi, messaggi e commenti **in italiano**.

---

## 9. SITO & FORM

> **Architettura dati:** i form non scrivono direttamente nei fogli. Passano da una
> **Google Apps Script Web App** (`script.google.com/macros/.../exec`); `booking` invia in più
> al webhook n8n. Il codice Apps Script vive nel progetto Google collegato a ciascun foglio
> (Estensioni → Apps Script), **non** negli HTML.

### `booking.html` — prenotazione Studio EUR
- Studio fisso: EUR, Viale Pasteur 56. Mar/Gio 13:00–20:00, Sab 08:00–14:00. Slot da 45 min.
- Slot letti via `GET APPS_SCRIPT_URL?action=getSlots&studio=eur&date=YYYY-MM-DD`.
- 🔴 **Attenzione al fallback:** esiste (o è esistita) una variabile `theoreticalSlots` che
  mostra tutti gli orari come liberi quando Apps Script non risponde. È un bug grave — il
  paziente prenota su slot occupati. Verificare che sia rimossa prima di toccare la logica slot.
- Caricamento a due fasi: prima settimana allo step 1, poi i 3 mesi successivi a gruppi di 4
  con `Promise.allSettled`, per non saturare le connessioni del browser.
- Alla conferma fa **due invii in sequenza**:
  1. POST Apps Script (`text/plain`): `{action:'book', studio, studioName, date, time, duration, nome, cognome, telefono, email}` → crea evento Calendar.
  2. POST webhook n8n (`application/json`) → WF1 (CRM + email).
- Body al webhook n8n: `nome`, `cognome`, `nomeCompleto`, `telefono`, `email`, `studio`,
  `studioId`, `studioIndirizzo`, `data` (`YYYY-MM-DD`), `orario` (`HH:mm`), `durata`, `timestamp` (ISO).

### `bookingfleming.html`
Identico a `booking.html` (stesso Apps Script, stesso webhook). Cambia solo lo studio:
Fleming, Via Città di Castello 20, `studioId: 'fleming'`, Mer/Ven 09:00–20:00.
Raggiungibile solo digitando l'URL: non è linkata dal sito.

### `dati-fattura.html` → Apps Script → CRM di **Fatture 2026**
- POST, `Content-Type: text/plain;charset=utf-8`, body JSON.
- Campi: `nome` (= Nome Completo), `sesso` ("M"/"F"), `indirizzo`, `cap`, `cf`.
- Validazioni client + server:
  - CAP: `^\d{5}\s+.+\s+[A-Za-z]{2}$` (es. "00136 Roma RM")
  - CF: `^[A-Za-z]{6}\d{2}[A-Za-z]\d{2}[A-Za-z]\d{3}[A-Za-z]$`
- Match per Nome Completo (case-insensitive), append se non trovato. Usa `LockService`.
- Risposta: `{ ok:true, riga:N }` oppure `{ ok:false, error:"..." }`.

### `registrazione.html` → Apps Script → CRM di **Super Agenda**
- GET in querystring, `mode: 'no-cors'`. Campi: `nome`, `cognome`, `telefono`, `email`
  (lo script accetta anche `problema`, `note`).
- `appendRow([nome, cognome, nome+' '+cognome, telefono, email, problema, note])`.
- ⚠️ Non rispetta `headerRow: 2` e non scrive le colonne H–J (Luogo, Prezzo, Reminder).

### Pagine statiche
- `policy-cancellazione.html`: disdetta entro **24h**, penale **50%**, WhatsApp `+39 328 273 8164`,
  link `https://wa.me/393282738164`.
- `chi-sono.html`, `privacy-policy.html`, `pannello.html` (indice interno strumenti clinici).
- Pagine-modulo per iPad in studio: `moduli-fisioexpert`, `questionario-visita`, `test-funzionali`,
  `scheda-esercizi`, `template-soap`, `return-to-play`, `anamnesi`, `esercizi`, `protocollo`.
  Generano PDF client-side con jsPDF.

---

## 10. LAVORI APERTI

- [ ] WF1: rami dell'IF "Paziente esiste?" invertiti o vuoti.
- [ ] WF4: rimuovere il ramo `Lun → Parioli` dal codice JS (studio chiuso).
- [ ] Pagine-modulo: sostituire il vecchio logo base64 (808×302) con quello pulito, altezza 36px.
- [ ] `logo-fisioexpert-header.png`: cancellabile dal repo, nessuna pagina lo referenzia più.
- [ ] Struttura colonne F+ del CRM Fatture 2026: da definire con l'utente.

### Fatto ad agosto 2026
- Base64 sostituito da `/logo.png` e `/gianmarco.jpg` su index, chi-sono, articolo blog.
- Logo unificato a 36px su tutte le pagine online, vecchio asset 808×302 abbandonato.
- Rimosso il fallback `theoreticalSlots` dalle due pagine booking.

---

## 11. QUANDO MANCANO INFORMAZIONI

Chiedi all'utente **prima** di produrre codice se serve:
- struttura colonne del CRM Fatture 2026 oltre alla E;
- template WhatsApp non elencati alla sezione 7;
- credenziali o connessioni non presenti;
- la versione **attuale online** di un file, quando la copia nel progetto potrebbe essere
  più vecchia di quella deployata (è già successo con le pagine booking).
