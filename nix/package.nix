{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  hyprland,
  coreutils,
  gnused,
  bash,
  src,
  version,
}:

stdenvNoCC.mkDerivation {
  pname = "scottbass3-greeter";
  inherit src version;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    dest=$out/share/scottbass3-greeter
    mkdir -p $dest
    cp -r components hypr services theme GreeterSurface.qml shell.qml $dest/
    install -Dm644 tmpfiles.conf $out/lib/tmpfiles.d/scottbass3-greeter.conf
    install -Dm644 config.example.json README.md -t $out/share/doc/scottbass3-greeter

    # greetd's command. The greeter user's PATH is nearly empty on NixOS, and
    # Hyprland passes its own to the greeter it starts.
    makeWrapper ${hyprland}/bin/start-hyprland $out/bin/scottbass3-greeter \
      --add-flags "-- -c $dest/hypr/greeter.lua" \
      --prefix PATH : ${
        lib.makeBinPath [
          quickshell
          hyprland
          coreutils
          gnused
          bash
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "greetd greeter for Hyprland built on Quickshell, with the scottbass3-shell lock screen look";
    homepage = "https://github.com/scottbass3/greeter";
    license = lib.licenses.gpl3Plus;
    mainProgram = "scottbass3-greeter";
    platforms = lib.platforms.linux;
  };
}
