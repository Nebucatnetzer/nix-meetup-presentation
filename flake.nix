{
  description = "Presentation for Nix Meetup Bern";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      fonts = pkgs.symlinkJoin {
        name = "typst-fonts";
        paths = [
          pkgs.fira
          pkgs.fira-code
          pkgs.fira-math
        ];
      };
      pdfName = "presentation";
      pkgs = nixpkgs.legacyPackages.${system};
      presentation = pkgs.stdenvNoCC.mkDerivation {
        inherit TYPST_FONT_PATHS;
        name = "zhf-presentation";
        src = ./src;
        buildInputs = [
          pkgs.polylux2pdfpc
          typstEnvironment
        ];
        buildPhase = ''
          mkdir $out
          typst compile main.typ $out/${pdfName}.pdf
          polylux2pdfpc main.typ
          cp main.pdfpc $out/${pdfName}.pdfpc
        '';
      };
      system = "x86_64-linux";
      TYPST_FONT_PATHS = "${fonts}/share/fonts";
      typstEnvironment = pkgs.typst.withPackages (p: [
        p.metropolis-polylux
        p.polylux
      ]);
    in
    {
      packages.${system} = {
        default = presentation;
        present = pkgs.writeShellScriptBin "present" ''
          ${pkgs.pdfpc}/bin/pdfpc "${presentation}/${pdfName}.pdf"
        '';
        watch = pkgs.writeShellScriptBin "typst-watch" ''
          ${typstEnvironment}/bin/typst watch src/main.typ --open xdg-open ${pdfName}.pdf
        '';
      };
      devShells.${system}.default = pkgs.mkShellNoCC {
        env = {
          inherit TYPST_FONT_PATHS;
        };
        packages = [
          pkgs.pdfpc
          pkgs.polylux2pdfpc
          pkgs.tinymist
          pkgs.typstyle
          typstEnvironment
        ];
      };
    };
}
