-- =====================================================================
-- Script 02: rende admin l'account di Gianmarco.
-- Lancialo DOPO aver creato l'utente in Authentication → Users → Add user.
-- Sostituisci l'email se ne hai usata un'altra.
-- =====================================================================

update public.profili
   set ruolo = 'admin', attivo = true, nome = 'Gianmarco', cognome = 'Molinari'
 where id = (select id from auth.users where email = 'gianmarcomolinari@outlook.it');

-- Controllo: deve comparire una riga con ruolo = admin.
select nome_utente, nome, cognome, ruolo, attivo from public.profili where ruolo = 'admin';
