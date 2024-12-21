{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
     name = "desktop-ui";
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = with pkgs.buildPackages; [
      gtk4
      gtk4-layer-shell
      glib.dev
      cairo
      gtk-layer-shell
      gobject-introspection
      pkgconf
      graphene

      python3
      python3.pkgs.pip
      #python3.pkgs.pygobject4
      python3.pkgs.pygobject3
      python3.pkgs.loguru

      # gnome.adwaita-icon-theme
      # Fonts
      font-awesome
      material-symbols
    ];

  shellHook = ''
    export GDK_BACKEND=wayland
    echo "🐧 GTK4 Layer Shell Python env ready"
  '';

}
