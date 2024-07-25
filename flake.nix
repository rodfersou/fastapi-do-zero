{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unstable = nixpkgs-unstable.legacyPackages.${system};
        python = pkgs.python312;
      in
      with pkgs; {
        devShells.default = mkShell {
          name = "dev-environment";
          packages = [
            python
            isort
            mypy
            poetry
            ruff
          ] ++ (
            if ("$INSIDE_DOCKER" != "true") then [
              pre-commit
              entr
              httpie
              jq
              lazygit
              ripgrep
              silver-searcher
              tmux
              tree
            ] else [
            ]
          );
          shellHook = ''
            export INSIDE_NIX=true
            export DEBUG=''${DEBUG:-true}
            if [[ $INSIDE_DOCKER != "true" ]]; then
              export POETRY_VIRTUALENVS_IN_PROJECT="true"
            fi
            unset PYTHONPATH
            poetry env use ${python.executable}
        
            export PATH="$(poetry env info -p)/bin:$PATH"
            export MYPYPATH="$(poetry env info -p)/${python.sitePackages}"
          '';
        };
      }
    );
}
