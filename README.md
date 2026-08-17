# Presentation for Nix Meetup Bern

```bash
nix build
```

Develop and compile ad-hoc with:

```bash
nix run .#watch
```

NOTE This script is intended to be run on Linux as it uses `xdg-open` you can use plain `typst watch src/main.typ` on other plattforms.

To present:

```bash
nix run .#present
```
