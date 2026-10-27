# Supabase — App Allenamenti Pazienti

**Progetto attivo:** `https://gaymgwkjpmrysuiltvvu.supabase.co` · publishable key `sb_publishable_vHYG8XJx6bRHuN0zu_Zejw_IQrfZ9fl` (pubblica per design).
Admin: `gianmarcomolinari@outlook.it`.

## Passo 1: crea il progetto (5 minuti)

1. Vai su <https://supabase.com> → **Start your project** → accedi con GitHub (account `fisioterapiamolinari-dotcom`).
2. **New project**:
   - Name: `fisioexpert-allenamenti`
   - Database password: generala e salvala nel tuo gestore password (non serve a me).
   - Region: **Central EU (Frankfurt)** ← obbligatorio per il GDPR.
   - Piano: Free.
   - Security: **Enable Data API ON** · **Automatically expose new tables OFF** · **Enable automatic RLS ON**.
3. Aspetta che finisca (1–2 minuti).

## Passo 2: crea tabelle e sicurezza

1. Menu a sinistra → **SQL Editor** → **New query**.
2. Apri `01-schema.sql`, copia tutto, incolla, premi **Run**.
3. Deve dire `Success. No rows returned`.

## Passo 3: impostazioni di accesso

**Authentication → Sign In / Providers → Email**:
- Enable Email provider: **ON**
- **Confirm email: OFF** (i pazienti entrano con nome utente, non ricevono email di conferma)
- Allow new users to sign up: **ON** (i pazienti si registrano da soli; restano bloccati finché non li attivi tu)

**Authentication → URL Configuration**:
- Site URL: `https://fisioexpert.it/login.html`
- Redirect URLs: aggiungi `https://fisioexpert.it/**`

## Passo 4: il tuo account admin

1. **Authentication → Users → Add user → Create new user**
   - Email: `info@fisioexpert.it` (o quella che preferisci)
   - Password: scegline una forte
   - Auto Confirm User: **ON**
2. **SQL Editor** → New query → incolla `02-rendi-admin.sql` (cambia l'email se serve) → **Run**.
   Deve comparire una riga con `ruolo = admin`.

## Passo 5: mandami due valori

**Project Settings → API Keys** (o **Data API**):
- **Project URL** (tipo `https://abcdefgh.supabase.co`)
- **Publishable key** (`sb_publishable_…`) oppure, se vedi solo quella, la **anon key**.

Sono pubbliche per design: finiscono nelle pagine HTML.
**Non mandarmi mai** la `service_role` / `secret key`, né la password del database.

---

## Come funziona la sicurezza

| Chi | Cosa vede / fa |
|---|---|
| Non loggato | Niente |
| Paziente appena registrato | Solo il proprio profilo. Nessuna scheda finché non lo attivi tu |
| Paziente attivo | Le schede assegnate a lui, le sue sessioni e serie. Non può cambiarsi ruolo né attivarsi |
| Admin (tu) | Tutto: pazienti, esercizi, schede, assegnazioni, storico; export ed eliminazione |

- **Registrazione con nome utente:** dietro le quinte Supabase vuole un'email, quindi la pagina
  di login userà `nomeutente@utenti.fisioexpert.it` come indirizzo interno (nessuna email parte).
  Conseguenza: il paziente **non può recuperare la password da solo**. Gliela reimposti tu dal
  pannello admin (funzione `reimposta_password`).
- **Export GDPR:** funzione `esporta_dati_paziente` → file JSON con tutto.
- **Diritto all'oblio:** funzione `elimina_paziente` → cancella login e tutti i dati, irreversibile.
- **Consenso privacy:** ogni accettazione resta nella tabella `consensi` con data e versione.
