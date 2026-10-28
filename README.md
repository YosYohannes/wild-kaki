# WildKaki

An offline running app where every run reveals one wild animal, chosen by how, where and when you ran.

## Status

Early. The app is one pixel-art scene (sky, river, meadow) that follows the clock. Waiting animals hide in bushes on the far bank, tap one to reveal it, and the bench opens the collection. All of it runs on mock data. The Health Connect sync from the first prototype is still there, behind Developer tools in debug builds.

## Layout

- `android/`: the Android app (Kotlin, Jetpack Compose)
- `tools/make_sprites.py`: writes every sprite and scene object as its own PNG into `android/app/src/main/res/drawable-nodpi/`. Animals are 32x32; change the script, run it, rebuild.

## Run

```
cd android
./gradlew :app:assembleDebug
```

Needs JDK 17 and the Android SDK. The APK is written to `android/app/build/outputs/apk/debug/`.
