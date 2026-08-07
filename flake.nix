{
  description = "Development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        git
        prek
        just
        gcc
        gfortran
        fpc
        ocaml
        ghc
        ldc
        gnat
        vlang
        beamPackages.elixir
        beamPackages.erlang
        scala-cli
        babashka
        racket
        sbcl
        perl
        R
        php
        tcl
        gawk
        bash
        powershell
        octave
        jdk21
        julia
        kotlin
        nim
        odin
        (python314.withPackages (p: [p.rich p.polars p.numpy p.cython]))
        pypy311
        ruff
        ty
        nodejs
        bun
        typescript
        cargo
        clippy
        rustfmt
        go
        deno
        luajit
        stylua
        selene
        zig
        ruby
        dart
        crystal
        dotnet-sdk
        groovy
        rakudo
        chicken
        guile
        swi-prolog
        gnu-smalltalk
        haxe
        neko
        gforth
        gleam
        clang
        gnustep-make
        gnustep-libobjc
        gnustep-base
        nasm
        smlnj
        lean4
        duckdb
      ];
    };
  };
}
