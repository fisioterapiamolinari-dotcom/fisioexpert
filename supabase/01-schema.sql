-- =====================================================================
-- Fisio Expert — App Allenamenti Pazienti
-- Script 01: tabelle, sicurezza (RLS), funzioni admin
--
-- Come si usa: Supabase → SQL Editor → New query → incolla TUTTO → Run.
-- Si può rilanciare: non duplica nulla.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- 1. TABELLE
-- ---------------------------------------------------------------------

-- Profilo di ogni utente (paziente o admin). Collegato al login di Supabase.
create table if not exists public.profili (
  id                  uuid primary key references auth.users(id) on delete cascade,
  nome_utente         text unique not null check (nome_utente ~ '^[a-z0-9._-]{3,30}$'),
  nome                text not null default '',
  cognome             text not null default '',
  email               text,            -- serve per l'aggancio al CRM del gestionale
  telefono            text,
  ruolo               text not null default 'paziente' check (ruolo in ('paziente','admin')),
  attivo              boolean not null default false,  -- lo attiva Gianmarco
  consenso_privacy_il timestamptz,
  consenso_versione   text,
  crm_id              text,            -- id/riga del paziente nel gestionale (facoltativo)
  creato_il           timestamptz not null default now()
);

-- Libreria esercizi (si riempie da sola quando scrivi una scheda).
create table if not exists public.esercizi (
  id            uuid primary key default gen_random_uuid(),
  nome          text not null unique,
  descrizione   text,
  link_video    text,
  link_immagine text,
  note          text,
  creato_il     timestamptz not null default now()
);

-- Scheda = il programma (es. "Ginocchio – fase 2").
create table if not exists public.schede (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  indicazioni text,                    -- indicazioni generali della scheda
  creata_da   uuid references public.profili(id) on delete set null,
  creato_il   timestamptz not null default now()
);

-- Righe della scheda: esercizio, giorno (1-4…), ordine, serie, ripetizioni, RPE…
create table if not exists public.scheda_esercizi (
  id           uuid primary key default gen_random_uuid(),
  scheda_id    uuid not null references public.schede(id) on delete cascade,
  esercizio_id uuid not null references public.esercizi(id) on delete restrict,
  giorno       int  not null default 1 check (giorno between 1 and 7),
  ordine       int  not null default 1,
  serie        int  check (serie between 1 and 20),
  ripetizioni  text,                   -- testo libero: "8-12", "30 sec", "max"
  rpe          text,                   -- testo libero: "7", "7-8"
  recupero     text,                   -- es. "90 sec"
  indicazioni  text,                   -- come eseguirlo
  note         text,
  creato_il    timestamptz not null default now()
);

-- Quale scheda è assegnata a quale paziente.
create table if not exists public.assegnazioni (
  id          uuid primary key default gen_random_uuid(),
  paziente_id uuid not null references public.profili(id) on delete cascade,
  scheda_id   uuid not null references public.schede(id) on delete cascade,
  data_inizio date not null default (now() at time zone 'Europe/Rome')::date,
  data_fine   date,
  stato       text not null default 'attiva' check (stato in ('attiva','sospesa','conclusa')),
  creato_il   timestamptz not null default now()
);

-- Una sessione = il paziente fa "Giorno N" in una certa data.
create table if not exists public.sessioni (
  id              uuid primary key default gen_random_uuid(), -- generato anche offline dal telefono
  paziente_id     uuid not null references public.profili(id) on delete cascade,
  assegnazione_id uuid not null references public.assegnazioni(id) on delete cascade,
  giorno          int  not null check (giorno between 1 and 7),
  data            date not null default (now() at time zone 'Europe/Rome')::date,
  completata      boolean not null default false,
  completata_il   timestamptz,
  note            text,
  creato_il       timestamptz not null default now()
);

-- Ogni serie registrata: ripetizioni, carico, RPE.
create table if not exists public.serie_registrate (
  id                 uuid primary key default gen_random_uuid(),
  sessione_id        uuid not null references public.sessioni(id) on delete cascade,
  scheda_esercizio_id uuid not null references public.scheda_esercizi(id) on delete cascade,
  numero_serie       int  not null check (numero_serie between 1 and 30),
  ripetizioni        int  check (ripetizioni between 0 and 1000),
  carico_kg          numeric(6,2) check (carico_kg between 0 and 1000),
  rpe                numeric(3,1) check (rpe between 0 and 10),
  fatta              boolean not null default true,
  creato_il          timestamptz not null default now(),
  unique (sessione_id, scheda_esercizio_id, numero_serie)  -- serve per la sincronizzazione offline
);

-- Registro dei consensi privacy (prova per il GDPR, non si cancella dal paziente).
create table if not exists public.consensi (
  id          uuid primary key default gen_random_uuid(),
  paziente_id uuid not null references public.profili(id) on delete cascade,
  versione    text not null,
  accettato_il timestamptz not null default now(),
  user_agent  text
);

create index if not exists idx_scheda_esercizi_scheda on public.scheda_esercizi(scheda_id, giorno, ordine);
create index if not exists idx_assegnazioni_paziente  on public.assegnazioni(paziente_id);
create index if not exists idx_sessioni_paziente      on public.sessioni(paziente_id, data desc);
create index if not exists idx_serie_sessione         on public.serie_registrate(sessione_id);
create index if not exists idx_consensi_paziente      on public.consensi(paziente_id);

-- ---------------------------------------------------------------------
-- 2. FUNZIONI DI SUPPORTO
-- ---------------------------------------------------------------------

-- L'utente collegato è admin?
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profili where id = auth.uid() and ruolo = 'admin');
$$;

-- L'utente collegato è un paziente attivato da Gianmarco?
create or replace function public.is_attivo()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profili where id = auth.uid() and attivo);
$$;

-- La scheda è assegnata all'utente collegato?
create or replace function public.scheda_mia(p_scheda uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.assegnazioni
                 where scheda_id = p_scheda and paziente_id = auth.uid());
$$;

-- La sessione appartiene all'utente collegato?
create or replace function public.sessione_mia(p_sessione uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.sessioni
                 where id = p_sessione and paziente_id = auth.uid());
$$;

-- Alla registrazione crea il profilo. Ruolo sempre "paziente", sempre NON attivo:
-- i dati mandati dal telefono non possono mai renderlo admin.
create or replace function public.nuovo_utente()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profili (id, nome_utente, nome, cognome, email, telefono)
  values (
    new.id,
    lower(coalesce(nullif(m->>'nome_utente',''), split_part(new.email, '@', 1))),
    coalesce(m->>'nome', ''),
    coalesce(m->>'cognome', ''),
    nullif(m->>'email_contatto', ''),
    nullif(m->>'telefono', '')
  );
  return new;
end;
$$;

drop trigger if exists trg_nuovo_utente on auth.users;
create trigger trg_nuovo_utente after insert on auth.users
  for each row execute function public.nuovo_utente();

-- Un paziente può modificare nome, telefono ecc. ma NON ruolo, attivo, nome utente, crm_id.
-- (Dal SQL Editor di Supabase invece si può tutto: lì non c'è un utente collegato.)
create or replace function public.proteggi_profilo()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.ruolo       := old.ruolo;
    new.attivo      := old.attivo;
    new.nome_utente := old.nome_utente;
    new.crm_id      := old.crm_id;
    new.creato_il   := old.creato_il;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_proteggi_profilo on public.profili;
create trigger trg_proteggi_profilo before update on public.profili
  for each row execute function public.proteggi_profilo();

-- ---------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------

alter table public.profili          enable row level security;
alter table public.esercizi         enable row level security;
alter table public.schede           enable row level security;
alter table public.scheda_esercizi  enable row level security;
alter table public.assegnazioni     enable row level security;
alter table public.sessioni         enable row level security;
alter table public.serie_registrate enable row level security;
alter table public.consensi         enable row level security;

-- Chi non ha fatto login non vede niente, nemmeno la struttura.
revoke all on all tables in schema public from anon;

-- Chi ha fatto login può usare le tabelle, ma solo entro le regole RLS qui sotto.
-- (Serve se alla creazione del progetto "Automatically expose new tables" è spento.)
grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.profili, public.esercizi, public.schede, public.scheda_esercizi,
  public.assegnazioni, public.sessioni, public.serie_registrate, public.consensi
  to authenticated;

-- Ripulisce le regole prima di ricrearle (così lo script si può rilanciare).
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public' and tablename in
    ('profili','esercizi','schede','scheda_esercizi','assegnazioni','sessioni','serie_registrate','consensi')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- PROFILI: ognuno vede e modifica il proprio; l'admin tutti.
create policy "profilo: leggo il mio"      on public.profili for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "profilo: modifico il mio"   on public.profili for update to authenticated using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());
create policy "profilo: admin cancella"    on public.profili for delete to authenticated using (public.is_admin());
-- Nessuna regola di insert: il profilo lo crea solo il trigger di registrazione.

-- ESERCIZI: li vedono i pazienti attivi, li scrive solo l'admin.
create policy "esercizi: leggo"            on public.esercizi for select to authenticated using (public.is_admin() or public.is_attivo());
create policy "esercizi: admin scrive"     on public.esercizi for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- SCHEDE: il paziente attivo vede solo quelle assegnate a lui.
create policy "schede: leggo le mie"       on public.schede for select to authenticated using (public.is_admin() or (public.is_attivo() and public.scheda_mia(id)));
create policy "schede: admin scrive"       on public.schede for all    to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "righe scheda: leggo le mie" on public.scheda_esercizi for select to authenticated using (public.is_admin() or (public.is_attivo() and public.scheda_mia(scheda_id)));
create policy "righe scheda: admin scrive" on public.scheda_esercizi for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- ASSEGNAZIONI: il paziente vede le proprie, solo l'admin assegna.
create policy "assegnazioni: leggo le mie" on public.assegnazioni for select to authenticated using (public.is_admin() or (public.is_attivo() and paziente_id = auth.uid()));
create policy "assegnazioni: admin scrive" on public.assegnazioni for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- SESSIONI: il paziente attivo crea e aggiorna solo le proprie, su assegnazioni sue.
create policy "sessioni: leggo"            on public.sessioni for select to authenticated using (public.is_admin() or paziente_id = auth.uid());
create policy "sessioni: creo"             on public.sessioni for insert to authenticated with check (
  public.is_admin() or (
    paziente_id = auth.uid() and public.is_attivo()
    and exists (select 1 from public.assegnazioni a where a.id = assegnazione_id and a.paziente_id = auth.uid())
  ));
create policy "sessioni: aggiorno"         on public.sessioni for update to authenticated
  using (public.is_admin() or (paziente_id = auth.uid() and public.is_attivo()))
  with check (public.is_admin() or (
    paziente_id = auth.uid()
    and exists (select 1 from public.assegnazioni a where a.id = assegnazione_id and a.paziente_id = auth.uid())
  ));
create policy "sessioni: admin cancella"   on public.sessioni for delete to authenticated using (public.is_admin());

-- SERIE: il paziente scrive solo dentro le proprie sessioni.
create policy "serie: leggo"               on public.serie_registrate for select to authenticated using (public.is_admin() or public.sessione_mia(sessione_id));
create policy "serie: creo"                on public.serie_registrate for insert to authenticated with check (public.is_admin() or (public.is_attivo() and public.sessione_mia(sessione_id)));
create policy "serie: aggiorno"            on public.serie_registrate for update to authenticated
  using (public.is_admin() or (public.is_attivo() and public.sessione_mia(sessione_id)))
  with check (public.is_admin() or public.sessione_mia(sessione_id));
create policy "serie: cancello"            on public.serie_registrate for delete to authenticated using (public.is_admin() or (public.is_attivo() and public.sessione_mia(sessione_id)));

-- CONSENSI: il paziente registra il proprio consenso e lo rilegge; non lo modifica.
create policy "consensi: leggo"            on public.consensi for select to authenticated using (public.is_admin() or paziente_id = auth.uid());
create policy "consensi: registro il mio"  on public.consensi for insert to authenticated with check (paziente_id = auth.uid());

-- ---------------------------------------------------------------------
-- 4. FUNZIONI SOLO ADMIN (chiamate dal pannello admin)
-- ---------------------------------------------------------------------

-- Export di tutti i dati di un paziente (richiesta GDPR di accesso/portabilità).
create or replace function public.esporta_dati_paziente(p_paziente uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Operazione riservata all''amministratore'; end if;
  return jsonb_build_object(
    'esportato_il', now(),
    'profilo',      (select to_jsonb(p) from public.profili p where p.id = p_paziente),
    'consensi',     coalesce((select jsonb_agg(c order by c.accettato_il) from public.consensi c where c.paziente_id = p_paziente), '[]'),
    'assegnazioni', coalesce((select jsonb_agg(jsonb_build_object(
                       'assegnazione', a,
                       'scheda', (select to_jsonb(s) from public.schede s where s.id = a.scheda_id),
                       'esercizi', (select jsonb_agg(jsonb_build_object('riga', se, 'esercizio', e.nome) order by se.giorno, se.ordine)
                                    from public.scheda_esercizi se join public.esercizi e on e.id = se.esercizio_id
                                    where se.scheda_id = a.scheda_id)))
                     from public.assegnazioni a where a.paziente_id = p_paziente), '[]'),
    'sessioni',     coalesce((select jsonb_agg(jsonb_build_object(
                       'sessione', s,
                       'serie', (select jsonb_agg(r order by r.scheda_esercizio_id, r.numero_serie)
                                 from public.serie_registrate r where r.sessione_id = s.id))
                       order by s.data)
                     from public.sessioni s where s.paziente_id = p_paziente), '[]')
  );
end;
$$;

-- Cancellazione definitiva di un paziente e di tutti i suoi dati (diritto all'oblio).
-- Cancella anche il login: non si può annullare.
create or replace function public.elimina_paziente(p_paziente uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'Operazione riservata all''amministratore'; end if;
  if p_paziente = auth.uid() then raise exception 'Non puoi eliminare il tuo account admin'; end if;
  delete from auth.users where id = p_paziente;  -- a cascata: profilo, assegnazioni, sessioni, serie, consensi
end;
$$;

-- Reimposta la password di un paziente (i pazienti con solo nome utente non ricevono email).
create or replace function public.reimposta_password(p_paziente uuid, p_nuova text)
returns void language plpgsql security definer set search_path = public, auth, extensions as $$
begin
  if not public.is_admin() then raise exception 'Operazione riservata all''amministratore'; end if;
  if length(p_nuova) < 8 then raise exception 'La password deve avere almeno 8 caratteri'; end if;
  update auth.users
     set encrypted_password = extensions.crypt(p_nuova, extensions.gen_salt('bf')),
         updated_at = now()
   where id = p_paziente;
end;
$$;

-- Le funzioni non sono chiamabili da chi non ha fatto login.
revoke execute on function public.esporta_dati_paziente(uuid)   from public, anon;
revoke execute on function public.elimina_paziente(uuid)        from public, anon;
revoke execute on function public.reimposta_password(uuid,text) from public, anon;
revoke execute on function public.nuovo_utente()                from public, anon, authenticated;
revoke execute on function public.proteggi_profilo()            from public, anon, authenticated;
grant  execute on function public.esporta_dati_paziente(uuid)   to authenticated;
grant  execute on function public.elimina_paziente(uuid)        to authenticated;
grant  execute on function public.reimposta_password(uuid,text) to authenticated;
