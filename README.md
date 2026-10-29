# WildKaki

An offline running app where every run reveals one wild animal, chosen by how, where and when you ran.

## Status

Flutter app, builds as a debug APK. The whole app is one pixel-art scene (sky, river, meadow) that follows the clock. Activities and sleep are read from Health Connect: everything Health Connect counts is an activity, once it starts after first launch. Each waiting activity hides an animal in a bush on the far bank (up to three at a time): tap a bush to meet the animal, the bench for the collection, the lamppost for Recent (the last 7 days), and pull down to sync. Tapping the animals in the scene makes them run off with a sound. Debug builds have Developer tools in Settings that write a fake run or a fake sleep into Health Connect.

Animals and the rules that pick them live in `lib/animals/`. For now there are three animals (fox, duck, bird) and one rule: every activity brings a fox.

Not yet verified on a device: Health Connect permission flow, pull-to-refresh feel and the launcher icon.

## Docs

- `docs/product-design.md`: the original product design, written when the app was called Trail Buddy
- `docs/rules.md`: one page on how an activity becomes an animal, with the chances
- `docs/rule-parameters.md`: what a rule can look at, the values it can take and the fallback when a value is missing
- `docs/animals.md`: the bases, species, affinities, colour species, hats and the assets to make

## Layout

- `lib/main.dart`: app start, portrait lock, edge-to-edge bars, sync on launch and resume
- `lib/world/`: the pixel world (`pixel_buffer.dart`, `sky.dart`, `world_painter.dart`)
- `lib/scene/`: scene screen, actors and sprite loading
- `lib/animals/`: the animal list (`animals.dart`), what an animal needs (`animal.dart`) and the rules (`rules.dart`)
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
