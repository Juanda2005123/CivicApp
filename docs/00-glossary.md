# Document 0: Glossary

One place to look up what a VIGÍA term means and how it is spelled in each layer: the **Spanish word the user sees**,
the **English name in Dart code** and the **database object** in `data model/schema.sql`.

- Spanish UI strings come from the copy deck (`docs/design/03-design-system.md` §8) or from the code that already ships.
  Strings marked *(proposed)* are not in the UI yet. Use them as the default when the feature arrives, and remove the
  mark once they ship.
- "—" means the term has no counterpart in that layer.
- Rules are cited by ID (`RN-xx`, see `docs/03-business-rules.md`). If a definition here disagrees with the business rules
  or the schema, those win: fix this file.

## 1. Actors and identity

| Term | UI (Spanish) | Code | Database | Definition |
|---|---|---|---|---|
| Citizen | Ciudadano | `AuthUser`, `Profile` | `auth.users` + `user_profile` | The single role of the app: a registered user who reports and interacts. There is no admin role in the mobile client. |
| Guest / anonymous visitor | Visitante *(proposed)* | — | — | Browses the map, feed and details without an account. Cannot report, vote, comment or earn XP. |
| Distinguished overseer | Veedor Mayor | — | `civic_rank` (level 4) | Not a separate role: a citizen who reached the highest rank. Their badges add credibility to their posts. |
| Profile | Mi perfil | `Profile`, `ProfileModel` | `user_profile` | Public data of a citizen. Its key `id_user` is the Auth UID. Created by `SignUpUseCase` right after the Auth account (AGENTS.md §8). |
| Reference city | Ciudad de residencia | `Profile.cityName`, `City` | `user_profile.reference_city` | City chosen at registration from the closed `coverage_city` list. Stored by **name**, not id (RN-14). |
| Last city | — | — | `user_profile.last_city` | Last city the user browsed. Used to place the map when GPS is denied or out of coverage (RN-14). |
| Session | Sesión activa | — | Supabase Auth session | Exists after login or a sign-up with no e-mail confirmation pending. Logout always calls `signOut`. |

## 2. Reports

| Term | UI (Spanish) | Code | Database | Definition |
|---|---|---|---|---|
| Report / incident | Reporte (vial) | `Incident` | `road_incident` | A georeferenced record of road or public-space damage. "Report" and "incident" mean the same thing: the UI says *reporte*, the code and schema say *incident*. |
| Tracking code | Código de seguimiento | `Incident.trackingCode` | `road_incident.tracking_code` | Public, unique, human-readable id shown after publishing, e.g. `#VIG-8492`. Displayed in monospace. |
| Category | Categoría del daño | `IncidentCategory` | `incident_category` | Type of damage, 7 in total. Migration `003` stores the names in Spanish; `displayNameSpanish` also maps the old English seeds (see §2.1). |
| Severity | Gravedad del daño | `IncidentSeverity` | `road_incident.severity` | Severity as the reporter perceives it: Baja / Media / Alta / Crítica (`LOW`…`CRITICAL`). Never shown by color alone. |
| Status | Estado *(proposed)* | `IncidentStatus` | `road_incident.current_status` | Lifecycle of a report (see §2.2). |
| Evidence photo | Fotos de evidencia | `IncidentPhoto`, `PickedPhoto` | `incident_photo`, bucket `incident-evidence` | 0–3 photos per report, JPG/PNG/WebP, ≤ 5 MB each (RN-02), uploaded with UUID names. The table stores the Storage **path**. `PickedPhoto` is the domain's own type, so the domain never sees `XFile`. |
| Address nomenclature | Nomenclatura vial | — | `road_incident.formatted_address` | Colombian structured address (Calle/Carrera/Avenida… + number + cross street + plot), assembled in the wizard. |
| Neighborhood | Barrio o sector | `Incident.neighborhood` | `road_incident.neighborhood` | Required on every report (RN-01). Not asked at registration. |
| Estimated dimensions | Dimensiones aproximadas | `Incident.estimatedDimensions` | `road_incident.estimated_dimensions` | Optional free text, e.g. `~1.2m x 18cm`. |
| Nearby incident | Es este / Es otro daño | `NearbyIncident` | — | An active report of the same category within **150 m** of the new pin (HU-09). Shown so the user can back it instead of filing a duplicate. |
| Reporting wizard | Reportar daño · Paso N de 5 | `ReportWizardScreen`, `ReportWizardBloc` | — | Five steps as built (HU-07–HU-12): location and address → category and severity (then the nearby check) → photos → title, description and dimensions → review and publish (+100 XP). `docs/01` and `docs/02` still describe the original 4-step design. |
| Edit window / frozen report | — | — | — | The author may edit or delete only within 30 min **and** with < 5 upvotes. After that the report is frozen (RN-03). |

### 2.1 Categories (`incident_category.name` → UI)

| Original seed (`seeds.sql`) | Name after migration `003` = UI (Spanish) |
|---|---|
| Pothole or Road Hazard | Hueco o bache en calzada |
| Traffic Light | Semáforo dañado o apagado |
| Abandoned Public Work | Obra pública abandonada |
| Damaged Sidewalk | Andén o paso peatonal roto |
| Water Leak | Fuga de agua o alcantarillado |
| Road Signage | Señalización vial dañada |
| Other | Otro daño vial |

### 2.2 Report status (`current_status`)

| Database | Code | UI (Spanish) | Meaning |
|---|---|---|---|
| `REPORTED` | `reported` | Reportado | Default after publishing. |
| `UNDER_REVIEW` | `underReview` | En revisión | A resolution proposal is pending. |
| `COMMUNITY_VALIDATED` | `communityValidated` | Validado por la comunidad | Reached 10 upvotes (see *Community validation*). |
| `RESOLVED` | `resolved` | Resuelto | Repair confirmed through a resolution (RN-11). |

## 3. Community interaction

| Term | UI (Spanish) | Code | Database | Definition |
|---|---|---|---|---|
| Upvote / endorsement | Apoyo, apoyar un reporte | `EndorseIncidentUseCase` | `incident_upvote` | One vote per user per report. Tapping again revokes it (toggle, RN-04). Authors cannot vote on their own reports (RN-05). |
| Community validation | Reporte validado | — | `COMMUNITY_VALIDATED` | A report that reached **10 upvotes**. Gives its author +500 XP once; the bonus stays even if votes later drop. |
| Comment / thread | Comentario / Conversación *(proposed)* | — | `incident_comment`, `comment_photo` | Chronological and immutable. Up to 1 optional photo. Its author can delete it only within 5 min (RN-06). |
| Follow / subscription | Seguir reporte *(proposed)* | — | `incident_follow` | Opt-in alerts for a report. Authors follow their own reports automatically (RN-07). |
| Feed | Comunidad *(proposed)* | — | — | Scrolling list of report cards, filtered and sorted the same way as the map. |
| City switcher | — | — | `coverage_city` | Header component with accent-tolerant fuzzy search, plus chips for recent cities and the top 5 capitals. |

## 4. Resolution (RN-11)

| Term | UI (Spanish) | Code | Database | Definition |
|---|---|---|---|---|
| Resolution proposal | Reportar como reparado *(proposed)* | — | `incident_resolution` | Claim that the damage was repaired, with 1 recent photo and a description. Only **one** `PENDING` proposal per report (`idx_single_active_resolution`). |
| Proponent | — | — | `id_proponent_user` | The citizen who submits the proposal. Gets +50 XP if it is accepted. |
| Confirmation | Confirmar *(proposed)* | — | `resolution_confirmation` | A neighbor vouches for the repair. **3** confirmations → `APPROVED_BY_COMMUNITY`. |
| Objection | Objetar *(proposed)* | — | `resolution_objection` | A neighbor disputes the evidence. **3** objections → `REJECTED_BY_COMMUNITY`. |
| Rejection reason | — | — | `rejection_reason` | Required when the report author rejects a proposal (`REJECTED_BY_AUTHOR`). |
| Expiration | — | — | `EXPIRED` | 7 days with no quorum and no answer from the author. Frees the slot for a new proposal. |

Proposal states: `PENDING`, `APPROVED_BY_AUTHOR` (the author proposed it, or accepted it), `APPROVED_BY_COMMUNITY`,
`REJECTED_BY_AUTHOR`, `REJECTED_BY_COMMUNITY`, `EXPIRED`.

## 5. Gamification

| Term | UI (Spanish) | Code | Database | Definition |
|---|---|---|---|---|
| Experience points (XP) | Puntos de reputación | `Profile.experiencePoints` | `user_profile.experience_points` | Earned by taking part, using the schedule in RN-08 (+100 report, +10 vote cast or received, +15 comment, +500 validation, +50 accepted resolution, −10 when a vote is revoked). |
| Civic rank | Rango cívico | `RankSeal` (UI) | `civic_rank` | Level picked by the highest `min_xp` ≤ the user's XP (RN-09). Names come from `civic_rank.name`. |
| Badge | Insignia *(proposed)* | — | `civic_badge`, `user_badge` | Milestone award, granted automatically (RN-10). |
| Civic dashboard | Mi perfil | `dashboard` feature | — | The profile summary screen users land on after login and registration: identity, rank, XP and impact metrics. |

### 5.1 Ranks

| Level | `min_xp` | Database / English | UI (Spanish) |
|---|---|---|---|
| 1 | 0 | Urban Observer | Observador Urbano |
| 2 | 1000 | Active Neighbor | Vecino Activo |
| 3 | 2500 | Road Guardian | Guardián Vial |
| 4 | 4000 | Master Overseer | Veedor Mayor |

### 5.2 Badges (`civic_badge.key_code`)

| Key | English name | UI (Spanish) *(proposed)* | Condition |
|---|---|---|---|
| `FIRST_CIVIC_STEP` | First Civic Step | Primer paso cívico | First report published. |
| `ACTIVE_VOICE` | Active Voice | Voz activa | 10 comments. |
| `POTHOLE_HUNTER` | Pothole Hunter | Cazahuecos | 5 reports in *Pothole or Road Hazard*. |
| `HIGH_IMPACT_REPORT` | High Impact Report | Reporte de alto impacto | One of your reports was validated. |
| `COMMUNITY_GUARDIAN` | Community Guardian | Guardián de la comunidad | 50 upvotes given. |

## 6. Geography

| Term | UI (Spanish) | Code | Database | Definition |
|---|---|---|---|---|
| Coverage city | Ciudad | `City` | `coverage_city` | Closed catalog: the 32 departmental capitals plus urban municipalities with more than 100,000 inhabitants, based on DANE data (RN-12). |
| DANE | — | — | — | Colombia's national statistics department. Source of the urban catalog. |
| Conurbation calibration | — | `CityRepositoryImpl` | — | Per-city radii embedded in the app and merged with the remote rows (AGENTS.md §13, item 3). |
| Bounding box | — | — | — | Valid coordinates: latitude −4.2° to 13.5°, longitude −79.0° to −66.8° (RN-12). |
| Excluded roads | — | — | — | Rural trails (*trochas*) and national concession highways (ANI / Invías) are out of scope. |
| Coordinates | Coordenadas geográficas | `Coordinates` | `latitude`, `longitude` | Shown in monospace. The domain uses its own `Coordinates` type, never `Position` from `geolocator`. |

## 7. Notifications (RN-13)

Stored in `notification` and shown in the alert center (bell icon). Push: `COMMUNITY_VALIDATION`, `RESOLUTION_PROPOSAL`,
`REPORT_RESOLVED`. In-app only: `NEW_UPVOTE`, `NEW_COMMENT`, `RANK_UP`, `NEW_BADGE`. The matrix may change during the
notifications sprint.

## 8. Project and engineering vocabulary

| Term | Meaning |
|---|---|
| `RN-xx` | Business rule (*regla de negocio*), `docs/03-business-rules.md`. |
| `HU-xx` | User story (*historia de usuario*), sprint backlogs `docs/05-…` and `docs/06-…`. |
| `§N` | Section N of `AGENTS.md`, unless another document is named. |
| Screen / Page / Component | Lab 2 vocabulary: a Screen is a routed `Scaffold`; a Page is hosted by a Screen and has no `Scaffold`; a Component is a small reusable widget (AGENTS.md §6). |
| Shell | The host **Screen** with the `BottomNavigationBar` (Mapa · Comunidad · Mi perfil). It stays fixed and remembers the selected tab; each tab is a **Page** without its own `Scaffold`. Built in HU-13 as `HomeScreen` (route `/home`) with two tabs, Mapa and Mi perfil, plus the "Reportar daño" button; HU-19 adds Comunidad. Login and registration land here, on Mi perfil. |
| Entity, Repository, UseCase, DataSource, RepositoryImpl, Bloc | Clean Architecture pieces. Table and rules in AGENTS.md §4–5. |
| Token | A design value (color, text style, spacing, radius, duration) defined in `lib/core/theme/`. Widgets use tokens, never literals (AGENTS.md §6b). |
| Sello comunitario | The visual direction of the design system: paper surfaces, the seal, the dotted ring and monospace data. |
| Publishable key | The only Supabase key the app holds (`SUPABASE_ANON_KEY` in `.env`). Never the `service_role` key. |
| PQRSD | Colombian formal petitions to the government (*peticiones, quejas, reclamos, sugerencias, denuncias*). Explicitly out of scope: VIGÍA is citizen-led. |
