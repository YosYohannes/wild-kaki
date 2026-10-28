# Trail Buddy

An offline running app where every run reveals one wild animal, chosen by how, where and when you ran.

## Status

Early. The rules engine (run summary in, buddy or hint out) is built and tuned in Python first. The Android app comes after.

## Layout

- `trailbuddy/`: rules engine and run simulator
- `catalog/animals.toml`: the animals and their conditions
- `tests/`: engine tests

## Run

```
python3 -m unittest
python3 -m trailbuddy.sim --profile casual --weeks 52
```
