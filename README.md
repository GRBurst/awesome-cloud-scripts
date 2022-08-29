# Script-Cook

Single file library (pure bash) that generates all the boilerplate for your bash scripts.
By providing necessary information using an associative array, you get the following:

- Check if all required arguments are provided
- Check if the arguments are followed by the correct number of values
- Readable array to get values for all or single parameters
- Partially `usage` message which you can show in your help

It should cover all common use cases, but some corner cases may not be covered, yet.

Feel free to open an issue if you find yourself in need of a missing feature, if you have an idea to simplify its usage or if you have an idea to improve the lib in gereral.

## Run the template script

If you have `nix` and `nix-shell` installed on your system, you can run the scripts directly using:

```
./template.sh
```

If you don’t have `nix-shell` on your system, you have to take care of the needed dependencies and run it explicitly using bash, e.g.

```
bash ./template.sh
```

# Related

This project was created in companion with [nix-cloud-scripts](https://github.com/GRBurst/nix-cloud-scripts), a collection of scripts to ease your work with cloud environments.
