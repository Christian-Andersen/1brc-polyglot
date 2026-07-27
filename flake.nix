{
  description = "Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    pythonWithRich = pkgs.python3.withPackages (p: [p.rich]);
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        git
        prek
        just
        jdk21
        pythonWithRich
        nodejs
        bun
        uv
        typescript
      ];
    };
  };
}
