-- ============================================================
-- setup.sql — Script di installazione database
-- Esegui questo script una sola volta nel SQL Editor di Supabase
-- (https://supabase.com → progetto → SQL Editor → New query)
-- ============================================================

-- ── 1. CONFIGURAZIONE APP ────────────────────────────────────
-- Contiene tutte le impostazioni personalizzabili dall'app
create table if not exists config_app (
  chiave    text primary key,
  valore    text,
  tipo      text default 'text',   -- text | json | color | bool
  etichetta text,                  -- label mostrata nelle Impostazioni
  sezione   text default 'unita'  -- unita | colori | volontari | interventi | mezzi | attestati
);

-- Valori di default (personalizzabili poi dall'app)
insert into config_app (chiave, valore, tipo, etichetta, sezione) values
  ('unita.nomeBreve',       'La Mia Unità',                    'text',  'Nome breve',          'unita'),
  ('unita.nomeLungo',       'La Mia Unità di Protezione Civile','text', 'Nome completo',        'unita'),
  ('unita.nomeSezione',     '',                                'text',  'Sezione',             'unita'),
  ('unita.sottotitolo',     '',                                'text',  'Sottotitolo',         'unita'),
  ('unita.nomeSigla',       'LA MIA UNITÀ',                   'text',  'Sigla (maiuscolo)',   'unita'),
  ('unita.descrizione',     'Protezione Civile',               'text',  'Descrizione',         'unita'),
  ('unita.tipoVolontario',  'Volontario',                      'text',  'Tipo volontario',     'unita'),
  ('unita.logoUrl',         '',                                'text',  'URL logo',            'unita'),
  ('colori.primario',       '#1a7a4a',                         'color', 'Colore primario',     'colori'),
  ('colori.primarioLight',  '#25a863',                         'color', 'Colore primario chiaro','colori'),
  ('colori.primarioDark',   '#30d158',                         'color', 'Colore dark mode',    'colori'),
  ('attestati.ruoloFirmatario', 'Il Presidente',               'text',  'Ruolo firmatario',    'attestati'),
  ('volontari.squadre',     '[]',                              'json',  'Squadre',             'volontari'),
  ('volontari.tipi',        '["VOLONTARIO"]',                  'json',  'Tipi volontario',     'volontari'),
  ('volontari.mansioni',    '[]',                              'json',  'Mansioni',            'volontari'),
  ('interventi.tipiAttivita','["EMERGENZA","ESERCITAZIONE","CORSI","PREVENZIONE INFORTUNI","RAPPRESENTANZA","ASSEMBLEE E RIUNIONI","CONTROLLO TERRITORIO","SEGRETERIA","MAGAZZINO"]',
                                                               'json',  'Tipi attività',       'interventi'),
  ('mezzi.stati',           '["OPERATIVO","IN MANUTENZIONE","FERMO"]', 'json', 'Stati mezzi', 'mezzi')
on conflict (chiave) do nothing;

-- ── 2. UTENTI ────────────────────────────────────────────────
create table if not exists utenti (
  id            bigint generated always as identity primary key,
  nome          text not null,
  username      text not null unique,
  password      text not null,
  ruolo         text,
  tipo_accesso  text default 'standard',  -- master | standard
  permessi      jsonb default '{}',
  attivo        boolean default true,
  created_at    timestamptz default now()
);

-- ── 3. VOLONTARI ─────────────────────────────────────────────
create table if not exists volontari (
  id                bigint generated always as identity primary key,
  cognome           text not null,
  nome              text not null,
  codice_fiscale    text unique,
  data_nascita      date,
  luogo_nascita     text,
  indirizzo         text,
  telefono          text,
  email             text,
  squadra           text,
  tipo_volontario   text,
  mansione          text,
  specializzazione  text,
  gruppo            text,
  patenti           text,
  quattro_ore       boolean default false,
  dodici_ore        boolean default false,
  caposquadra       boolean default false,
  dae               boolean default false,
  scad_dae          date,
  emercom           boolean default false,
  cod_emercom       text,
  cdc_1_step        boolean default false,
  cdc_2_step        boolean default false,
  visita_medica     boolean default false,
  scad_visita       date,
  pronto_impiego    boolean default false,
  foto_url          text,
  note              text,
  attivo            boolean default true,
  created_at        timestamptz default now()
);

-- ── 4. INTERVENTI ────────────────────────────────────────────
create table if not exists interventi (
  id              bigint generated always as identity primary key,
  evento          text not null,
  luogo           text,
  data            date,
  data_fine       date,
  tipo_attivita   text,
  n_volontari     int default 0,
  n_ore           numeric(6,1) default 0,
  volontari_ids   int[] default '{}',
  note            text,
  is_macro        boolean default false,
  macro_id        bigint references interventi(id),
  created_at      timestamptz default now()
);

-- ── 5. MEZZI ─────────────────────────────────────────────────
create table if not exists mezzi (
  id          bigint generated always as identity primary key,
  automezzo   text not null,
  targa       text,
  tipo        text,
  stato       text default 'OPERATIVO',
  revisione   date,
  foto_url    text,
  note        text,
  created_at  timestamptz default now()
);

-- ── 6. DOCUMENTI ─────────────────────────────────────────────
create table if not exists documenti (
  id            bigint generated always as identity primary key,
  volontario_id bigint references volontari(id) on delete cascade,
  mezzo_id      bigint references mezzi(id) on delete cascade,
  tipo          text,
  nome_file     text,
  url           text,
  data_carico   timestamptz default now()
);

-- ── 7. SCHEMA CAMPI CUSTOM ───────────────────────────────────
create table if not exists schema_volontari (
  id        bigint generated always as identity primary key,
  campo_id  text not null unique,
  etichetta text not null,
  tipo      text default 'text',
  sezione   text default 'Altro',
  ordine    int default 0,
  visibile  boolean default true
);

-- ── 8. VALORI CAMPI CUSTOM ───────────────────────────────────
create table if not exists valori_custom (
  id            bigint generated always as identity primary key,
  volontario_id bigint references volontari(id) on delete cascade,
  campo_id      text not null,
  valore        text,
  unique(volontario_id, campo_id)
);

-- ── 9. VISTE VOLONTARI ───────────────────────────────────────
create table if not exists viste_volontari (
  id      bigint generated always as identity primary key,
  nome    text not null,
  filtri  jsonb default '{}',
  ordine  int default 0
);

-- ── 10. RICHIESTE ADESIONE ───────────────────────────────────
create table if not exists richieste_adesione (
  id          bigint generated always as identity primary key,
  nome        text,
  cognome     text,
  email       text,
  telefono    text,
  messaggio   text,
  letta       boolean default false,
  created_at  timestamptz default now()
);

-- ── 11. LOG ATTIVITÀ ─────────────────────────────────────────
create table if not exists log_attivita (
  id           bigint generated always as identity primary key,
  utente_nome  text,
  azione       text,
  created_at   timestamptz default now()
);

-- ── 12. STORAGE BUCKETS ──────────────────────────────────────
-- Esegui questi comandi separatamente se non li crea in automatico:
-- insert into storage.buckets (id, name, public) values ('documenti', 'documenti', true);
-- insert into storage.buckets (id, name, public) values ('attestati', 'attestati', true);
-- insert into storage.buckets (id, name, public) values ('loghi', 'loghi', true);

-- ── 13. RLS (Row Level Security) ─────────────────────────────
-- Per semplicità disabilitato: l'accesso è controllato dall'app via login.
-- In un deployment avanzato abilita RLS per ogni tabella.
alter table config_app          disable row level security;
alter table utenti              disable row level security;
alter table volontari           disable row level security;
alter table interventi          disable row level security;
alter table mezzi               disable row level security;
alter table documenti           disable row level security;
alter table schema_volontari    disable row level security;
alter table valori_custom       disable row level security;
alter table viste_volontari     disable row level security;
alter table richieste_adesione  disable row level security;
alter table log_attivita        disable row level security;

-- ── 14. UTENTE MASTER INIZIALE ───────────────────────────────
-- Cambia username e password dopo il primo accesso!
insert into utenti (nome, username, password, ruolo, tipo_accesso)
values ('Amministratore', 'admin', 'admin', 'Amministratore', 'master')
on conflict (username) do nothing;

-- ============================================================
-- FATTO! Ora:
-- 1. Copia URL e anon key da Project Settings → API
-- 2. Incollali in config.js
-- 3. Carica i 3 file (config.js, area-riservata.html, area-riservata.js)
-- 4. Apri l'app e accedi con admin/admin
-- 5. Vai in Impostazioni e configura la tua unità
-- ============================================================
