# Contributing

Keep pull requests small.

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Do not add API keys. Do not make the default test suite call DummyJSON. A separate opt-in check is fine.

Commit prefixes: `feat`, `fix`, `docs`, `test`, `refactor`.
