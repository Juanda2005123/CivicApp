# Supabase and data — reference (condensed from the course)

Sources: "Instalación de supabase", "Configurando los servicios", "Inicio de Sesión con Supabase y Flutter", "Escribir en la base de
datos", "Leer de la base de datos", "Storage, CDN y caché", "image_picker desde Clean Architecture", Labs 5–7, realtime lessons.
All Supabase calls live in **DataSources** (`data/datasources/`). Nothing above `data/` imports `supabase_flutter`.

## Setup

- `await Supabase.initialize(url: …, publishableKey: …)` in `main()` after `WidgetsFlutterBinding.ensureInitialized()`, then
  `initDependencies()`. The **publishable** key is safe in the client; the `service_role`/secret key never is. This repo reads
  them from `.env` via `AppEnv` (`.env` is git-ignored, `.env.example` is committed).
- Register `SupabaseClient` in GetIt (`sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)`) and inject it into
  data sources, instead of reading `Supabase.instance.client` inside them (course labs 5 do this; it also makes tests easy).
- CLI (no install; uses `npx`): `npx supabase login` · `init` · `link --project-ref <ref>` · `migration new <name>` ·
  `db push` · `migration list` · `migration fetch --linked` · `config diff` / `config push` · `seed buckets --linked`.
  Course `config.toml` for auth: `[auth] enabled = true`, `[auth.email] enable_signup = true`, `enable_confirmations = false`.

## Auth

```dart
final res = await client.auth.signUp(email: e, password: p, data: {...});   // AuthResponse { user, session }
await client.auth.signInWithPassword(email: e, password: p);
await client.auth.signOut();                                                  // always, or the session survives the UI
final user = client.auth.currentUser;                                        // persisted across app restarts
client.auth.onAuthStateChange.listen((d) { /* signedIn / signedOut / tokenRefreshed */ });
```

- `user != null && session != null` → created and signed in. `user != null && session == null` → e-mail must be confirmed first
  (default Supabase behaviour; the course turns confirmation off for learning). Weak password / invalid e-mail → `AuthException`.
- Common messages: `Invalid login credentials`, `Email not confirmed`, `User already registered` (only when confirmation is off).
- Auth stores only credentials (hashed password). Everything else (name, username, city, photo) goes in a table keyed by the Auth
  UID. Deleting the Auth user cascades if the FK is `on delete cascade`.
- Session restore on app start: `getCurrentUser` use case → Bloc emits authenticated/unauthenticated → route accordingly.

## Tables, migrations, permissions

- Every schema change is a migration file (`supabase/migrations/<timestamp>_<name>.sql`). **Never edit an applied migration**; create
  another. Order of creation = order of application (`posts` before `likes`).
- Tables the app touches need `grant select, insert, update, delete on public.<t> to authenticated;` — missing grant →
  `permission denied for table <t>` (`42501`). RLS: enable per table with explicit policies (`using (auth.uid() = id)`); this repo
  already has RLS configured — test with a real session after every policy change.
- Constraint errors surface as `PostgrestException`: `23514` check violated, `23503` foreign key, `23505` duplicate key,
  `42501` permission.
- This repo's DDL/DML are split: `data model/schema.sql` (DDL) and `data model/seeds.sql` (DML). Keep that separation.

## Reading

```dart
final rows = await client.from('posts').select('id, content, created_at')
    .eq('profile_id', uid).ilike('content', '%flutter%')
    .order('created_at', ascending: false).range(0, 9);          // range ends are INCLUSIVE → 10 rows
```

- Filters first, modifiers after; nothing travels until `await`. Result: `List<Map<String, dynamic>>`.
- `.single()` = exactly one row (else `PGRST116 Cannot coerce…`); `.maybeSingle()` = zero or one (returns `null`).
- Paginate **always with `order`**; fewer rows than the page size ⇒ no more pages.
- Related data: `select('id, author:profiles!profile_id(username, full_name), likes(count)')`. `alias:table` renames the key;
  `!fk_column` disambiguates multiple relationships (`PGRST201`); `likes(count)` arrives as `[{count: n}]`;
  `!inner` + filter on the alias filters by the related table.
- `.or('a.eq.1,b.eq.2')` — **one `.or()` per query**; group with `and(...)`. `count(CountOption.exact)` doesn't download rows.
- Map rows → entities in the data source (or a `*_model.dart`); snake_case columns ↔ camelCase fields only there.

## Writing

```dart
await client.from('t').insert({'col': v});                                  // keys are COLUMN names
final row = await client.from('t').insert({...}).select().single();         // get the created row back
await client.from('t').insert([{...}, {...}]);                              // batch: one request, one transaction
await client.from('likes').upsert({...}, onConflict: 'post_id,profile_id'); // idempotent
await client.from('t').update({...}).eq('id', id);                          // update/delete REQUIRE a filter
await client.from('t').delete().eq('id', id);
```

Catch `PostgrestException` in the data source and rethrow `Exception('clear message')`.

## Storage

- Bucket = container with rules; path = `<userId>/<uuid>.<ext>`; **store the path in the table, not the URL** (URLs depend on
  project and bucket type; public → `getPublicUrl(path)` builds a string without a network call, private →
  `createSignedUrl(path, 3600)` per image, `createSignedUrlsResult` for a batch).
- **Use a fresh UUID file name on every upload**, then save the new path, then delete the old file (upload → point → delete: a
  failure mid-way leaves an orphan file, never a dangling reference). Same-name overwrite is served stale by the CDN and
  `ImageCache`; upload with `cacheControl: '31536000'` when the name never repeats.
- Buckets are declared in `supabase/config.toml` (`[storage.buckets.<name>]`, `public`, `file_size_limit`, `allowed_mime_types`) and created
  with `npx supabase seed buckets --linked`. Uploading needs a `storage.objects` policy even on public buckets.
- Device pickers (`image_picker`, `geolocator`) follow the "library on the frontier" rule: SDK types stay in the DataSource; the
  domain defines its own type (`PickedPhoto { Uint8List bytes, String extension }`); the UseCase enforces limits (size ≤ 2 MB);
  the screen only throws an event (`AvatarChangeRequested`).

## Realtime

```dart
client.from('messages').stream(primaryKey: ['id']).eq('conversation_id', id).order('created_at');
// or single events:
final controller = StreamController<Message>();
final channel = client.channel('public:messages').onPostgresChanges(
  event: PostgresChangeEvent.insert, schema: 'public', table: 'messages',
  callback: (p) => controller.add(Message.fromJson(p.newRecord)),
).subscribe();
controller.onCancel = () => client.removeChannel(channel);          // avoid leaks
```

The table must have Realtime enabled (replication). The repository exposes `Stream<…>`; the UseCase exposes the same stream; the
Bloc listens (see the stream template in `code-templates.md`) and cancels in `close()`.

## Plain REST (non-Supabase) data sources

`http` package in the DataSource only: `Uri.parse` with `Uri.encodeComponent` for user input, check `statusCode == 200`, `jsonDecode`,
unwrap envelopes (`body['data']`), map to entities. If the API can't do something (search), that rule belongs in the **UseCase**
(`SearchProductsUseCase` filters the full catalog). Web builds may need the CORS-enabled proxy the course provides.
