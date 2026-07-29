{
  description = "Development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        git
        prek
        just
        jdk21
        (python314.withPackages (p: [p.rich p.polars p.numpy]))
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
      ];
    };
  };
}
