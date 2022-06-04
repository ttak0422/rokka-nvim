{ lib, stdenv, nix-filter, rokka-util, plugins }:
let
  inherit (builtins) map elem;
  inherit (lib) flatten filter;
  inherit (lib.strings) concatStringsSep hasPrefix;
  inherit (lib.lists) unique foldl';
  inherit (stdenv) mkDerivation;

  packpath = "rokka";

  /* Type: uniqeWith :: (a -> b) -> [a] -> [a]

     Example:
       uniqueWith (x: x.name) [ { name = "foo"; age = 10; } { name = "bar"; age = 20; } { name = "foo"; age = 20; } ]
       => [ { name = "foo"; age = 10; } { name = "bar"; age = 20; } ]
  */
  uniqueWith = f:
    foldl' (acc: x: if elem (f x) (map f acc) then acc else acc ++ [ x ]) [ ];

  /* Type: elemWith :: (a -> b) -> a -> [a] -> bool

     Example:
       elemWith (x: x.name) { name = "foo"; age = 10; }  [ { name = "foo"; age = 20; } { name = "bar"; age = 30; } ]
       => true

       elemWith (x: x.age) { name = "foo"; age = 10; }  [ { name = "foo"; age = 20; } { name = "bar"; age = 30; } ]
       => false
  */
  elemWith = f: x: xs: elem (f x) (map f xs);
  # elem   

  # inherit default config.
  normalize = p:
    if p ? rokka then
      p
    else
      rokka-util.rokkaNvimPluginDefault // { plugin = p; };

  resolveDepends = plugins:
    let
      plugins' = map normalize plugins;
      f = ps:
        map (p:
          if p.depends == [ ] then
            [ p ]
          else
            [ p ] ++ (f (map (p': p' // { optional = p.optional; })
              (map normalize p.depends)))) ps;
      # in uniqueWith (p: { name = p.plugin.pname; optional = p.optional; }) 
    in (flatten (f plugins'));

  allPlugins = let
    # all = resolveDepends plugins;
    all = plugins;
    allStart = filter (p: !p.optional) all;
    allOpt = filter (p: p.optional) all;
    # allOpt' = filter (p: !(elemWith))
    # allOpt = filter (p: p.optional && !(elemWith (p': p'.plugin.pname) p allStart)) all;
    # in allStart ++ allOpt;
  in all;

  optimizePlugin = p:
    p.overrideAttrs (old: {
      src = nix-filter {
        root = p.src;
        exclude = [
          "LICENSE"
          "README"
          "README.md"
          "t"
          "test"
          "tests"
          "Makefile"
          ".gitignore"
          ".github"
        ];
      };
    });

  # start/opt directories must be created before this.
  locatePlugin = p:
    let
      dir = if p.optional then "opt" else "start";
      name = if isNull p.as then p.plugin.pname else p.as;
      rtp = if isNull p.rtp then "" else p.rtp;
      plugin = if true then optimizePlugin p.plugin else p.plugin;

    in "ln -sf ${plugin}/${rtp} $out/pack/${packpath}/${dir}/${name}";

  locatePlugins = map locatePlugin;

in mkDerivation {
  name = "rokka-pack";
  src = ./.;
  preferLocalBuild = true;
  installPhase = concatStringsSep "\n" ([
    "mkdir -p $out/pack/${packpath}/start"
    "mkdir -p $out/pack/${packpath}/opt"
    # ] ++ (locatePlugins allPlugins));
  ]);
}
