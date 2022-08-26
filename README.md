# Nix Cloud Scripts

Nix Cloud Scripts serves as a central point to distribute simple scripts and tools that simplifies work with cloud environments.
Scripts are written to favor the use of `nix-shell`, since they provide the complete environment to run the script.
Right now, the repository structure is flat. This may change in the future such that we categorize scripts to their domain, e.g. `aws` or `nocode`.

You can find installation instructions on the [official website](https://nixos.org/download.html#nix-install-linux).

## Run a script

If you have `nix` and `nix-shell` installed on your system, you can run the scripts directly using:

```
./template.sh
```

If you don’t have `nix-shell` on your system, you have to take care of the needed dependencies and run it explicitly using bash, e.g.

```
bash ./template.sh
```

## Adding a script

Please use the templates `template.sh` and `template-aws.sh`. It contains a description as well.
