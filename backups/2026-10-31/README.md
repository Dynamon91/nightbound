# NIGHTBOUND — backup del 31 ottobre 2026

Questo snapshot contiene i sorgenti di **Hero Bat V2–V6**, il prototipo HTML del menu e i README di riferimento.

## Stato del salvataggio
- Repository esistente: `Dynamon91/nightbound` (progetto Godot, branch main).
- **Sorgenti in questa cartella:** copiati nel repository e recuperabili con Git.
- **Immagini PNG, modelli GLB, GIF, MP4 e musica:** backup conservati anche nella ChatGPT Library, cartella `/Nightbound/Backups/2026-10-31/`. I file binari non sono inclusi in questo commit: il connettore GitHub in questa sessione non carica direttamente file locali.
- Non dichiarare il gioco completo né testato in Godot solo perché i file sorgenti sono presenti.

## Backup binari (ChatGPT Library)
1. `NIGHTBOUND_RECOVERY_VISUALS_MODELS_2026-10-31.zip` — 50,7 MiB, 34 file selezionati, arte/immagini, Hero Bat GLB V3–V6, sorgenti, pacchetti asset e demo intro/menù.
   SHA-256: `cbc551090f4894efc622e0ad1eee2ba740e89ca78c0f0a57d7652d1416a754e6`
2. `NIGHTBOUND_RECOVERY_MUSIC_2026-10-31.zip` — 108,32 MiB, 15 pacchetti musicali V1–V15.
   SHA-256: `752201d0937ccb71d640a53dfe359f218be1bcaa5158f72e64a4053919b87a54`
3. `NIGHTBOUND_RECOVERY_MANIFEST_2026-10-31.json` — manifest con dimensioni e hash.

## Contenuto immagini
Mockup originale, lineup Hero Bat/Lira/nemici/NPC, arte dei livelli e castello, concept dell'intro e diversi mockup del menu. I file originali sono nel backup visuali, non in questo commit.

## Ripristino
1. Clonare il repository `https://github.com/Dynamon91/nightbound`.
2. Recuperare dalla Library ChatGPT i due ZIP nella cartella indicata.
3. Confrontare i checksum SHA-256 dei due ZIP con quelli sopra.
4. Estrarre gli archivi e copiare selettivamente asset e sorgenti, verificando le licenze e importazioni Godot.
5. Il menu HTML e i modelli GLB sono prototipi; l'integrazione nel progetto principale deve essere testata.

*Backup creato su richiesta per evitare la perdita dei file.*

## File binari disponibili anche su GitHub
- [Immagine originale di sfondo del menu](images/nightbound_title_background.png) — PNG binario salvato come Git blob.
- [Menu HTML interattivo standalone](intro_menu/Nightbound_Menu_Interattivo.html) — include l'immagine dello sfondo incorporata.
- [Sorgenti dei modelli V2–V6](source/) e relativi README.

**Limite attuale:** gli altri PNG, GLB, GIF, MP4 e i pacchetti audio si trovano negli archivi di backup ChatGPT Library indicati sopra; non sono ancora stati caricati come singoli file binari su GitHub.
