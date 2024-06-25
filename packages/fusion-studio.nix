{ stdenv
, pkgs
, lib
, cacert
, curl
, runCommandLocal
, unzip
, appimageTools
, addOpenGLRunpath
, dbus
, libGLU
, xorg
, apr
, buildFHSEnv
, buildFHSEnvChroot
, bash
, writeText
, ocl-icd
, xkeyboard_config
, glib
, libarchive
, libxcrypt
, python3
, aprutil
, makeDesktopItem
, copyDesktopItems
, jq
, runCommand
, writeShellScript
, autoPatchelfHook

, studioVariant ? true

, common-updater-scripts
, writeShellApplication
}:
let
  fusion = (
    stdenv.mkDerivation rec {
      pname = "fusion${lib.optionalString studioVariant "-studio"}";
      version = "18.6.6";

      nativeBuildInputs = [
        appimageTools.appimage-exec
        addOpenGLRunpath
        copyDesktopItems
        autoPatchelfHook
        unzip
      ];

      buildInputs = with pkgs;[
        #TODO: trim this of unneeded fat
        libGLU
        xorg.libXxf86vm
        apr
        xorg.libxcb
        xorg.libX11
        xorg.libICE
        xorg.libSM
        xorg.libXrender
        xorg.libXext
        freetype
        libuuid
        fontconfig
        glib
        zlib
        libglvnd
        bzip2
        gcc
        libGLU
        alsaLib
        glib
        libxkbcommon
        opencl-headers
        alsa-lib
        aprutil
        bzip2
        dbus
        expat
        fontconfig
        freetype
        glib
        libGL
        libGLU
        libarchive
        libcap
        librsvg
        libtool
        libuuid
        libxcrypt # provides libcrypt.so.1
        libxkbcommon
        opencl-headers
        nspr
        ocl-icd
        python3
        python3.pkgs.numpy
        udev
        xdg-utils # xdg-open needed to open URLs
        xorg.libICE
        xorg.libSM
        xorg.libX11
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
        xorg.libXt
        xorg.libXtst
        xorg.libXxf86vm
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        xorg.xkeyboardconfig
        cudatoolkit
        xz
      ];

      src = runCommandLocal "${pname}-src.tar.gz"
        rec {
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-O4F+t93GR1xqHpsuvAvcVhe5Qgg1CTk5LbUYNChadFw=";

          impureEnvVars = lib.fetchers.proxyImpureEnvVars;

          nativeBuildInputs = [ curl jq ];

          # ENV VARS
          SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

          # Get linux.downloadId from HTTP response on https://www.blackmagicdesign.com/products/davinciresolve
          REFERID = "46d125c9aff2482aaddb76e604925b1e";
          DOWNLOADSURL = "https://www.blackmagicdesign.com/api/support/us/downloads.json";
          SITEURL = "https://www.blackmagicdesign.com/api/register/us/download";
          PRODUCT = "Fusion${lib.optionalString studioVariant " Studio"}";
          VERSION = version;

          USERAGENT = builtins.concatStringsSep " " [
            "User-Agent: Mozilla/5.0 (X11; Linux ${stdenv.hostPlatform.linuxArch})"
            "AppleWebKit/537.36 (KHTML, like Gecko)"
            "Chrome/77.0.3865.75"
            "Safari/537.36"
          ];

          REQJSON = builtins.toJSON {
            "firstname" = "NixOS";
            "lastname" = "Linux";
            "email" = "someone@nixos.org";
            "phone" = "+31 71 452 5670";
            "country" = "nl";
            "street" = "-";
            "state" = "Province of Utrecht";
            "city" = "Utrecht";
            "product" = PRODUCT;
          };

        } ''
        DOWNLOADID=$(
          curl --silent --compressed "$DOWNLOADSURL" \
            | jq --raw-output '.downloads[] | select(.name | test("^'"$PRODUCT $VERSION"'( Update)?$")) | .urls.Linux[0].downloadId'
        )
        echo "downloadid is $DOWNLOADID"
        test -n "$DOWNLOADID"
        RESOLVEURL=$(curl \
          --silent \
          --header 'Host: www.blackmagicdesign.com' \
          --header 'Accept: application/json, text/plain, */*' \
          --header 'Origin: https://www.blackmagicdesign.com' \
          --header "$USERAGENT" \
          --header 'Content-Type: application/json;charset=UTF-8' \
          --header "Referer: https://www.blackmagicdesign.com/support/download/$REFERID/Linux" \
          --header 'Accept-Encoding: gzip, deflate, br' \
          --header 'Accept-Language: en-US,en;q=0.9' \
          --header 'Authority: www.blackmagicdesign.com' \
          --header 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
          --data-ascii "$REQJSON" \
          --compressed \
          "$SITEURL/$DOWNLOADID")
        echo "resolveurl is $RESOLVEURL"

        curl \
          --retry 3 --retry-delay 3 \
          --header "Upgrade-Insecure-Requests: 1" \
          --header "$USERAGENT" \
          --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
          --header "Accept-Language: en-US,en;q=0.9" \
          --compressed \
          "$RESOLVEURL" \
          > $out
      '';

      # The unpack phase won't generate a directory
      sourceRoot = ".";

      installPhase =
        let
          appimageName = "Blackmagic_Fusion_${lib.optionalString studioVariant "Studio_"}Linux_${version}_installer.run";
        in
        ''
          set -x

          runHook preInstall

          test -e ${lib.escapeShellArg appimageName}
          appimage-exec.sh -x "$out" ${lib.escapeShellArg appimageName}

          echo "$out"

          runHook postInstall
        '';

      dontStrip = true;

      preFixup = ''
        ln -s "$(realpath ${libxcrypt}/lib/libcrypt.so)" $out/libcrypt.so.1
        addAutoPatchelfSearchPath $out
      '';

      postFixup = ''
        addOpenGLRunpath "Fusion"
        addOpenGLRunpath "FusionStudio"
        addOpenGLRunpath "fuscript"
      '';

      desktopItems = [
        (makeDesktopItem {
          name = "davinci-resolve";
          desktopName = "Davinci Resolve";
          genericName = "Video Editor";
          exec = "fusion-studio";
          comment = "Professional video editing, color, effects and audio post-processing";
          categories = [
            "AudioVideo"
            "AudioVideoEditing"
            "Video"
            "Graphics"
          ];
        })
      ];
    }
  );

  # TODO: evaluate if this can run without FHS
  fhs = buildFHSEnv {
    pname = "fusion-fhsenv";
    inherit (fusion) version;

    targetPkgs = pkgs: with pkgs; [
      # TODO: trim this of unneeded fat
      alsa-lib
      aprutil
      bzip2
      fusion
      dbus
      expat
      fontconfig
      freetype
      glib
      libGL
      libGLU
      libarchive
      libcap
      librsvg
      libtool
      libuuid
      libxcrypt # provides libcrypt.so.1
      libxkbcommon
      opencl-headers
      nspr
      ocl-icd
      python3
      python3.pkgs.numpy
      udev
      xdg-utils # xdg-open needed to open URLs
      xorg.libICE
      xorg.libSM
      xorg.libX11
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXrender
      xorg.libXt
      xorg.libXtst
      xorg.libXxf86vm
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.xcbutilwm
      xorg.xkeyboardconfig
      zlib
      xz
    ];

    runScript = "${bash}/bin/bash ${
        writeText "fusion-env"
        ''
        export LD_LIBRARY_PATH=${fusion}:/run/opengl-driver/lib
        export QT_XKB_CONFIG_ROOT="${xkeyboard_config}/share/X11/xkb"
        export QT_PLUGIN_PATH="${fusion}/libs/plugins:$QT_PLUGIN_PATH"
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/lib32:${fusion}/libs
        export LUA_PATH=$HOME/.fusion/BlackmagicDesign/Fusion/Modules/Lua/?.lua
        exe="$1"
        shift
        exec ${fusion}/$exe $*
        ''
      }";
  };

  run = "${fhs}/bin/fusion-fhsenv";
in
runCommand fusion.name
{
  udevRule = ''
    # BMD hardware (such as Speed Editor)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1edb", MODE="0666"
    # Fusion Activation Dongle
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="096e", MODE="0666"
  '';
} ''
  mkdir -p $out/bin
  # TODO: add desktop icon here, etc
  ln -s ${writeShellScript "fusion-wrapper" "exec ${run} Fusion $*"} $out/bin/fusion
  ln -s ${writeShellScript "fusion-server-wrapper" "exec ${run} FusionServer $*"} $out/bin/fusion-server
  ln -s ${writeShellScript "fuscript-wrapper" "exec ${run} fuscript $*"} $out/bin/fuscript
  mkdir -p $out/etc/udev/rules.d
  echo "$udevRule" > $out/etc/udev/rules.d/90-blackmagic-design.rules
''
