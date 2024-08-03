{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312;
      in
      with pkgs; {
        devShells.default = mkShell {
          packages = [
            python
            mypy
            poetry
            ruff
            shellcheck
          ] ++ (
            if ("$INSIDE_DOCKER" != "true") then [
              entr
              gh
              git-ignore
              httpie
              jq
              lazygit
              pre-commit
              ripgrep
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
            poetry env use ${python.executable}

            unset PYTHONPATH
            export MYPYPATH="$(poetry env info -p)/${python.sitePackages}"
            export PATH="$(poetry env info -p)/bin:$PATH"
          '';
        };
      }
    );
}
