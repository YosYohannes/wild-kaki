# WildKaki

A running app that works offline, where every run reveals one wild animal, chosen by how, where and when you ran.

## Status

Flutter app, builds as a debug APK. The whole app is one pixel-art scene (sky, river, meadow) that follows the clock. Activities and sleep are read from Health Connect: everything Health Connect counts is an activity, once it starts after first launch. Each waiting activity hides an animal in a bush on the far bank (up to three at a time): tap a bush to meet the animal, the bench for the collection, the lamppost for Recent (the last 7 days), and pull down to sync. Tapping the animals in the scene makes them run off with a sound. Debug builds have Developer tools in Settings that write a fake run or a fake sleep into Health Connect.

Public holidays (they give a day-off hat) come from the free Nager.Date service by the phone's country code, cached on the phone for 30 days, with the bundled Singapore list as the fallback. There is no server of ours: the request carries only the country code and the phone's IP address.

The weather in the scene's sky comes from the free Open-Meteo service for a representative city of the phone's time zone (no location permission), cached for 20 minutes, and falls back to clear. It only changes how the scene looks; the request carries only the rounded city coordinates and the phone's IP address.

When the app opens it asks GitHub for the latest release of this repository (at most every six hours). If that release is newer, a banner offers it; Update opens the APK that matches the phone in the browser, and Later hides that version. The request carries only the phone's IP address, and Settings has a switch to turn it off. To follow a fork, build with `--dart-define=UPDATE_REPO=owner/name`.

Animals and the rules that pick them live in `lib/animals/`: 15 bases and 94 animals including legends (`docs/animals.md`), picked by the rules in `docs/rules.md`. Only animals you have found appear in the scene.

In the collection, an animal you have not met yet can show as a dark silhouette once you have met something from its family; tap it for a hint about its habits (never its name). The rules are in `docs/hints.md`.

Not yet verified on a device: Health Connect permission flow, pull-to-refresh feel and the launcher icon.

## Docs

- `docs/product-design.md`: the original product design, written when the app was called Trail Buddy
- `docs/rules.md`: one page on how an activity becomes an animal, with the chances
- `docs/rule-parameters.md`: what a rule can look at, the values it can take and the fallback when a value is missing
- `docs/animals.md`: the bases, species, affinities, colour species, hats and the assets to make
- `docs/hints.md`: when the collection hints at an animal you have not met, the habit lines and the legend riddles

## Layout

- `lib/main.dart`: app start, portrait lock, edge-to-edge bars, sync and holiday refresh on launch and resume
- `lib/world/`: the pixel world (`pixel_buffer.dart`, `sky.dart`, `world_painter.dart`)
- `lib/scene/`: scene screen, actors and sprite loading
- `lib/animals/`: the animal list (`animals.dart`), what an animal needs (`animal.dart`), the rules (`rules.dart`) and the public holidays (`holidays.dart`, `holidays_live.dart`)
- `lib/data/`: model, local store (shared_preferences), Health Connect sync, controller
- `lib/ui/`: theme, collection, animal, recent, settings, reveal and developer pages
- `assets/sprites/`: sprite PNGs written by `tools/make_sprites.py` (animals are 32x32); change the script, run it, rebuild
- `assets/sounds/`: the tap sounds (short WAV blips)
- `assets/icons/`: [pixelarticons](https://github.com/halfmage/pixelarticons) (MIT, licence in `assets/icons/LICENSE-pixelarticons.txt`)
- `assets/fonts/`: Tiny5 (OFL, licence in `tools/Tiny5-OFL.txt`)
- `android/`: Flutter Android host with the Health Connect manifest entries and the `app.wildkaki/health` channel
- `test/`: unit and golden tests; PNGs in `test/goldens`

## Run

```
flutter pub get
flutter test
flutter run
```

Needs the Flutter SDK, JDK 17 and the Android SDK. Health Connect needs Android 8+ (minSdk 26) with the Health Connect app installed.
