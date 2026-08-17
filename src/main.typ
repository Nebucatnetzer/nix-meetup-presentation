// Update these for each event {

#let buildDate = "2026-08-17" // otherwise you get 1980-01-01

// }

#import "@preview/polylux:0.4.0": *
#import "@preview/metropolis-polylux:0.1.0" as metropolis
#import metropolis: focus, new-section

// polylux 0.4.0's toolbox.pdfpc.speaker-note uses the pre-0.13 `type(x) == "string"`
// check and panics on Typst 0.15, so emit the pdfpc metadata directly instead.
#let speaker-note(body) = [#metadata((t: "Note", v: body.text.trim())) <pdfpc>]
// `metropolis.new-section` is itself a `slide`, so it cannot be nested in one.
// This is its body inlined, which lets a speaker note ride along on the divider.
#let section-note-slide(name, note) = slide({
  set page(header: none, footer: none)
  show: pad.with(20%)
  set text(size: 1.5em)
  name
  toolbox.register-section(name)
  metropolis.progress-bar
  note
})


#show: metropolis.setup
#show image: it => align(center, it)

#toolbox.pdfpc.config(note-font-size: 40)

#slide[
  #set page(header: none, footer: none, margin: 3em)

  #text(size: 1.3em)[*Just a bunch of `nix run`*]

  #metropolis.divider

  #set text(size: .8em, weight: "light")
  Andreas Zweili, \@Nebucatnetzer

  #buildDate
]

#slide[
  = Overview

  #metropolis.outline
]

#new-section[Introduction]

#slide[
  = About me

  _Andreas Zweili_
  - System Engineer/DevOps \@Contria GmbH
  - Free Software enthusiast and Nix(OS) fan since 2021.
  - \@Nebucatnetzer basically everywhere online

  #speaker-note(```
  - More of a systems guy.
  - GitHub, Fediverse, Discourse, etc.
  ```)
]

#slide[
  = What are we going to see?

  - An actual production project
  - Small in scope
  - All tools are used
  - The direction I want to implement at work

  #speaker-note(```
  - No critical data
  - Main code is about 360 lines of Python.
  - Small but still a complete setup with all our tooling in one place.
  - Probably future setup.
  ```)
]

#slide[
  = Snappass

  #image("./images/20260817T194310--snappass-form.png")
]
#slide[
  = Snappass

  #image("./images/20260817T194323--snappass-link.png")
]

#new-section[What problems do we try to solve?]

#slide[
  = What problems do we try to solve?

  - Writing CI jobs is annoying
  - Bringing the dev environment and production closer together
  - Reliable services in development environment
  - No (or little) barriers between the developer and the tools
  - Ideally not being too complex
  #speaker-note(```
  - Yaml and bash, what a shitty combination
  - Containers could work as well but they introduce a barrier
  ```)
]

#new-section[Our solution]

#slide[
  = Writing CI jobs is annoying

  #image("./images/20260817T194712--ci-nix-run.png")
]
#slide[
  = Writing CI jobs is annoying

  #align(center, ```nix
  { pythonDevEnvironment, writeShellApplication }:
  writeShellApplication {
    name = "ci-test-snappass";
    runtimeInputs = [ pythonDevEnvironment ];
    text = ''
      DEBUG="True"
      NO_SSL="True"
      REDIS_HOST="redis" # GitLab service alias
      export DEBUG NO_SSL REDIS_HOST
      pytest -p no:cacheprovider --cov=snappass tests.py
    '';
  }
  ```)

  #speaker-note(```
  - `nix run` makes it a lot easier.
  - We moved from:
    - YAML with inline bash
    - to standalone standalone scripts
    - to shebangs with nix-shell
    - and finally to `nix run`.
  ```)
]

#slide[
  = Bringing the dev environment and production closer together

  #image("./images/20260817T194546--mr-pipeline.png")
]

#slide[
  = Bringing the dev environment and production closer together

  #image("./images/20260817T194559--ci-tests.png")
]
#slide[
  = Bringing the dev environment and production closer together

  #image("./images/20260817T194609--ci-release.png")
]

#slide[
  = Bringing the dev environment and production closer together

  #image("./images/20260817T194619--deployement.png")

  #speaker-note(```
  - We are not 100% there yet, e.g. in this project redis could be one script for both environments.
  - Main product now gets built with Nix to 99%, thank you composer...
  ```)
]

#slide[
  = Reliable services for dev environments (without barriers)

  - Nix
  - direnv
  - process-compose

  #speaker-note(```
  - Nix brings the reliability and the advantage of not providing a barrier
  - one tool one job
  ```)
]

#slide[
  = Ideally not being too complex

  #image("./images/20260819T171124--meme.jpg")

  #speaker-note(```
  - I struggle here sometimes, Nix can feel overwhelming and exotic at times, especially in a small team and I'm the main Nix guy.
  - However I still think it is worth it and using Nix makes things easier in a lot of ways.
  - Without Nix you would have to learn multiple different tools and Nix feels to me a lot more comfortable then say containers.
  - Beats our previous Vagrant setup by a mile and onboarding is fantastic.
  - Tooling is never a big issue anymore.
  ```)
]

#slide[
  = Ideally not being too complex

  #image("./images/20260817T195030--dev-run-code.png")

  #align(center, ```nix
  (pkgs.writeShellScriptBin "process-compose" ''
    nix run .#project-pkgs.process-compose
  '')
  ```)

  #speaker-note(```
  - Why not devenv or flake-parts
    - I like the devenv services and their directory layout
    - Tries to do too many things that IMO are already solved in Nixpkgs or elsewhere and I
      would rather use standard solutions.
    - Afraid of enshitification.
  - I worked with picnoir a bit and he proposed the idea about not using the module system at all.
  - `nix run` has the advantage that we don't need to do a direnv reload
  ```)
]

#section-note-slide([Demo Time], speaker-note(```
- `nix run .#project-pkgs.process-compose`
- `direnv allow`
- `dev` command
- look at the files -> normal config file for process-compose.yml
- `nix build .#image --out-link image`
```))
#slide[
  #toolbox.pdfpc.hidden-slide
  #image("./images/20260819T182335--process-compose-tui.png")
]

#new-section[Other learnings]

#slide[
  = Central pkgs repo

  ```nix
  {
    inputs = {
      contria-pkgs.url = "git+ssh://git@.../contria-pkgs.git";
      pre-commit-hooks.url = "github:cachix/git-hooks.nix";
      pre-commit-hooks.inputs.nixpkgs.follows = "contria-pkgs/nixpkgs";
    };
  ...
    let
      system = "x86_64-linux";
      contria-pkgs = inputs.contria-pkgs.packages.${...}.contria-pkgs;
      pkgs = inputs.contria-pkgs.packages.${system}.pkgs;
    in
  ```

  #speaker-note(```
  - specific packages from unstable
  - unfree enabled
  ```)
]

#slide[
  = Pkgs in outputs

  ```nix
  outputs = {...}:{
      packages.${system} = { inherit contria-pkgs pkgs project-pkgs; };
  }
  ```

  ```bash
  # lets you run
  nix run .#pkgs.foo
  ```
]

#new-section[Where I want to take this]
#slide[
  = What is already implemented?

  - Central repo contria-pkgs
  - The `nix run .#project-pkgs.foo` interface
  - Each repository has a dev environment based on Nix
  - Non-PHP repos are all pure flakes
]
#slide[
  = What is still missing?

  - Migrate the PHP projects this process-compose setup
  - Convert all CI jobs to single line `nix run` tasks
  - Packaging our other projects, some of them are still very imperative
  - NixOS?

  #speaker-note(```
  - Certain eco-systems make it a bit more difficult.
  - Time constraints.
  - I try to be cautious and not overwhelm our developers.
  - Final question is whether the endgame is NixOS hosts or Ubuntu+images forever.
  ```)
]

#new-section[Questions?]

#slide[
  = Sources

  - #link("https://direnv.net/")
  - #link("https://f1bonacc1.github.io/process-compose/")
  - #link("https://github.com/Nebucatnetzer/nix-meetup-presentation")
  - #link("https://github.com/pinterest/snappass")
]
