-- ============================================================
-- setup.sql — Esegui UNA SOLA VOLTA nel SQL Editor di Supabase
-- Project → SQL Editor → New query → incolla → Run
-- ============================================================

-- Utenti app (NON usa Supabase Auth)
create table if not exists utenti (
  id            bigint generated always as identity primary key,
  nome          text not null,
  username      text not null unique,
  password      text not null,
  ruolo         text,
  tipo_accesso  text default 'standard',
  permessi      jsonb default '{}',
  attivo        boolean default true,
  created_at    timestamptz default now()
);

-- Volontari
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

-- Interventi
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

-- Mezzi
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

-- Documenti (volontari e mezzi)
create table if not exists documenti (
  id            bigint generated always as identity primary key,
  volontario_id bigint references volontari(id) on delete cascade,
  mezzo_id      bigint references mezzi(id) on delete cascade,
  tipo          text,
  nome_file     text,
  url           text,
  data_carico   timestamptz default now()
);

-- Campi custom volontari (schema)
create table if not exists schema_volontari (
  id        bigint generated always as identity primary key,
  campo_id  text not null unique,
  etichetta text not null,
  tipo      text default 'text',
  sezione   text default 'Altro',
  ordine    int default 0,
  visibile  boolean default true
);

-- Valori campi custom
create table if not exists valori_custom (
  id            bigint generated always as identity primary key,
  volontario_id bigint references volontari(id) on delete cascade,
  campo_id      text not null,
  valore        text,
  unique(volontario_id, campo_id)
);

-- Viste volontari
create table if not exists viste_volontari (
  id      bigint generated always as identity primary key,
  nome    text not null,
  filtri  jsonb default '{}',
  ordine  int default 0
);

-- Richieste adesione
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

-- Log attività
create table if not exists log_attivita (
  id           bigint generated always as identity primary key,
  utente_nome  text,
  azione       text,
  created_at   timestamptz default now()
);

-- Disabilita RLS (l'accesso è controllato dall'app via login)
alter table utenti             disable row level security;
alter table volontari          disable row level security;
alter table interventi         disable row level security;
alter table mezzi              disable row level security;
alter table documenti          disable row level security;
alter table schema_volontari   disable row level security;
alter table valori_custom      disable row level security;
alter table viste_volontari    disable row level security;
alter table richieste_adesione disable row level security;
alter table log_attivita       disable row level security;

-- Storage buckets (esegui separatamente se dà errore)
insert into storage.buckets (id, name, public) values ('documenti', 'documenti', true) on conflict do nothing;
insert into storage.buckets (id, name, public) values ('attestati', 'attestati', true) on conflict do nothing;
insert into storage.buckets (id, name, public) values ('loghi',     'loghi',     true) on conflict do nothing;

-- ============================================================
-- FATTO. Ora apri l'app: al primo accesso ti chiederà
-- di creare il tuo account amministratore.
-- ============================================================
