{
  description = "CI and development environment for Kubernetes cluster";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            kubeconform
            yamllint
            gitleaks
            kubectl
            kubernetes-helm
            kustomize
            fluxcd
          ];

          shellHook = ''
            echo "Kubernetes GitOps Dev Environment Ready"
          '';
        };

        checks = {
          gitleaks = pkgs.runCommand "check-gitleaks" {
            nativeBuildInputs = [ pkgs.gitleaks ];
          } ''
            gitleaks dir ${./.} --config ${./.gitleaks.toml} --verbose
            touch $out
          '';

          kubeconform = pkgs.runCommand "check-kubeconform" {
            nativeBuildInputs = [ pkgs.kubeconform ];
          } ''
            kubeconform -summary -ignore-missing-schemas ${./infrastructure} ${./apps} ${./flux-system}
            touch $out
          '';

          yamllint = pkgs.runCommand "check-yamllint" {
            nativeBuildInputs = [ pkgs.yamllint ];
          } ''
            yamllint -d "{extends: relaxed, rules: {line-length: disable, truthy: disable, trailing-spaces: disable, new-line-at-end-of-file: disable}}" ${./infrastructure} ${./apps} ${./flux-system}
            touch $out
          '';
        };
      });
}
