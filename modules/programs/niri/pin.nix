{inputs, ...}: {
  flake.homeModules.niri-pin = {pkgs, ...}: let
    niriPinSource = pkgs.writeText "niri-pin.cpp" ''
      #include <QApplication>
      #include <QCoreApplication>
      #include <QCursor>
      #include <QFileInfo>
      #include <QGuiApplication>
      #include <QImageReader>
      #include <QJsonArray>
      #include <QJsonDocument>
      #include <QLabel>
      #include <QLocalServer>
      #include <QLocalSocket>
      #include <QMouseEvent>
      #include <QScreen>
      #include <QTextStream>
      #include <QWheelEvent>
      #include <QWindow>

      #include <algorithm>
      #include <cmath>
      #include <cstring>

      namespace {

      const auto socketName = QStringLiteral("niri-pin");

      class PinWindow final : public QLabel {
      public:
          explicit PinWindow(const QPixmap &pixmap)
          {
              setWindowTitle(QStringLiteral("Niri Pin"));
              setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
              setAttribute(Qt::WA_DeleteOnClose);
              setAttribute(Qt::WA_ShowWithoutActivating);
              setCursor(Qt::OpenHandCursor);
              setPixmap(pixmap);
              setScaledContents(true);

              QScreen *screen = QGuiApplication::screenAt(QCursor::pos());
              if (!screen) {
                  screen = QGuiApplication::primaryScreen();
              }

              const qreal devicePixelRatio = screen ? screen->devicePixelRatio() : 1.0;
              baseSize_ = QSizeF(pixmap.width() / devicePixelRatio,
                                pixmap.height() / devicePixelRatio);

              if (screen) {
                  const QSize available = screen->availableGeometry().size() * 0.9;
                  scale_ = std::min({1.0,
                                     available.width() / baseSize_.width(),
                                     available.height() / baseSize_.height()});
              }

              applyScale(scale_);
          }

      protected:
          void mousePressEvent(QMouseEvent *event) override
          {
              if (event->button() == Qt::RightButton) {
                  close();
                  event->accept();
                  return;
              }

              if (event->button() == Qt::LeftButton && windowHandle()
                  && windowHandle()->startSystemMove()) {
                  event->accept();
                  return;
              }

              QLabel::mousePressEvent(event);
          }

          void wheelEvent(QWheelEvent *event) override
          {
              if (event->angleDelta().y() == 0) {
                  event->ignore();
                  return;
              }

              const qreal steps = event->angleDelta().y() / 120.0;
              applyScale(scale_ * std::pow(1.1, steps));
              event->accept();
          }

      private:
          void applyScale(qreal scale)
          {
              scale_ = std::clamp(scale, 0.05, 8.0);
              const int width = std::max(1, qRound(baseSize_.width() * scale_));
              const int height = std::max(1, qRound(baseSize_.height() * scale_));
              setFixedSize(width, height);
          }

          QSizeF baseSize_;
          qreal scale_ = 1.0;
      };

      bool openPin(const QString &path, QString *error)
      {
          QImageReader reader(path);
          reader.setAutoTransform(true);
          const QPixmap pixmap = QPixmap::fromImage(reader.read());
          if (pixmap.isNull()) {
              *error = reader.errorString();
              return false;
          }

          auto *window = new PinWindow(pixmap);
          window->show();
          return true;
      }

      int runClient(QCoreApplication &app)
      {
          const QStringList arguments = app.arguments();
          if (arguments.size() < 2) {
              QTextStream(stderr) << "usage: niri-pin IMAGE...\n";
              return 2;
          }

          QJsonArray paths;
          for (qsizetype i = 1; i < arguments.size(); ++i) {
              paths.append(QFileInfo(arguments[i]).absoluteFilePath());
          }

          QLocalSocket socket;
          socket.setSocketOptions(QLocalSocket::AbstractNamespaceOption);
          socket.connectToServer(socketName);
          if (!socket.waitForConnected(500)) {
              QTextStream(stderr) << "niri-pin daemon is unavailable: " << socket.errorString() << '\n';
              return 1;
          }

          socket.write(QJsonDocument(paths).toJson(QJsonDocument::Compact) + '\n');
          if (!socket.waitForBytesWritten(500) || !socket.waitForReadyRead(2000)) {
              QTextStream(stderr) << "niri-pin daemon did not respond\n";
              return 1;
          }

          const QByteArray response = socket.readLine().trimmed();
          if (response != "ok") {
              QTextStream(stderr) << response << '\n';
              return 1;
          }
          return 0;
      }

      int runDaemon(int argc, char **argv)
      {
          QApplication app(argc, argv);
          QCoreApplication::setApplicationName(QStringLiteral("niri-pin"));
          QGuiApplication::setDesktopFileName(QStringLiteral("niri-pin"));
          app.setQuitOnLastWindowClosed(false);

          QLocalServer server;
          server.setSocketOptions(QLocalServer::AbstractNamespaceOption);
          if (!server.listen(socketName)) {
              QTextStream(stderr) << "cannot listen on " << socketName << ": "
                                  << server.errorString() << '\n';
              return 1;
          }

          QObject::connect(&server, &QLocalServer::newConnection, &server, [&server] {
              while (QLocalSocket *socket = server.nextPendingConnection()) {
                  QObject::connect(socket, &QLocalSocket::readyRead, socket, [socket] {
                      if (socket->property("handled").toBool() || !socket->canReadLine()) {
                          return;
                      }
                      socket->setProperty("handled", true);

                      const QJsonDocument request = QJsonDocument::fromJson(socket->readLine());
                      if (!request.isArray()) {
                          socket->write("invalid request\n");
                          socket->flush();
                          return;
                      }

                      for (const QJsonValue &value : request.array()) {
                          QString error;
                          if (!value.isString() || !openPin(value.toString(), &error)) {
                              error.replace('\n', ' ');
                              socket->write((QStringLiteral("cannot open image: ") + error + '\n').toUtf8());
                              socket->flush();
                              return;
                          }
                      }

                      socket->write("ok\n");
                      socket->flush();
                  });
                  QObject::connect(socket, &QLocalSocket::disconnected, socket,
                                   &QLocalSocket::deleteLater);
              }
          });

          return app.exec();
      }

      } // namespace

      int main(int argc, char **argv)
      {
          if (argc >= 2 && std::strcmp(argv[1], "--daemon") == 0) {
              return runDaemon(argc, argv);
          }

          QCoreApplication app(argc, argv);
          QCoreApplication::setApplicationName(QStringLiteral("niri-pin"));
          return runClient(app);
      }
    '';

    waytator = inputs.waytator.packages.${pkgs.stdenv.hostPlatform.system}.default;

    niriPin = pkgs.stdenv.mkDerivation {
      pname = "niri-pin";
      version = "0.1.0";
      src = niriPinSource;
      dontUnpack = true;

      nativeBuildInputs = [pkgs.pkg-config pkgs.qt6.wrapQtAppsHook];
      buildInputs = [pkgs.qt6.qtbase];

      buildPhase = ''
        runHook preBuild
        $CXX -std=c++20 -O2 "$src" -o niri-pin \
          $(pkg-config --cflags --libs Qt6Widgets Qt6Network)
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm755 niri-pin "$out/bin/niri-pin"
        runHook postInstall
      '';

      meta.mainProgram = "niri-pin";
    };

    captureRegion = ''
      TMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
      PIPE="$TMP_DIR/events"
      SCREENSHOT="$TMP_DIR/capture.png"
      STREAM_PID=

      cleanup() {
        [ -z "$STREAM_PID" ] || kill "$STREAM_PID" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rm -f -- "$PIPE" "$SCREENSHOT"
        ${pkgs.coreutils}/bin/rmdir -- "$TMP_DIR" 2>/dev/null || true
      }
      trap cleanup EXIT

      ${pkgs.coreutils}/bin/mkfifo "$PIPE"
      niri msg --json event-stream > "$PIPE" &
      STREAM_PID=$!
      exec 3< "$PIPE"

      niri msg action screenshot --path "$SCREENSHOT"

      ${pkgs.coreutils}/bin/timeout 15 ${pkgs.jq}/bin/jq -en \
        --arg path "$SCREENSHOT" \
        'first(inputs | select(.ScreenshotCaptured.path? == $path))' \
        <&3 >/dev/null 2>&1 || exit 0

      exec 3<&-
      kill "$STREAM_PID" 2>/dev/null || true
      wait "$STREAM_PID" 2>/dev/null || true
      STREAM_PID=
      [ -s "$SCREENSHOT" ] || exit 0
    '';

    pin = pkgs.writeScriptBin "niri-pin-to-screen" ''
      #!${pkgs.dash}/bin/dash
      set -eu
      ${captureRegion}
      ${niriPin}/bin/niri-pin "$SCREENSHOT"
    '';

    edit = pkgs.writeScriptBin "niri-edit-screenshot" ''
      #!${pkgs.dash}/bin/dash
      set -eu
      ${captureRegion}
      OUTPUT_DIR="$HOME/Pictures/Screenshots"
      OUTPUT="$OUTPUT_DIR/$(${pkgs.coreutils}/bin/date +'%y-%m-%d-%H-%M-%S').png"
      ${pkgs.coreutils}/bin/mkdir -p -- "$OUTPUT_DIR"
      ${pkgs.coreutils}/bin/cp -- "$SCREENSHOT" "$OUTPUT"
      ${waytator}/bin/waytator "$OUTPUT"
    '';

    ocr = pkgs.writeScriptBin "niri-region-ocr" ''
      #!${pkgs.dash}/bin/dash
      set -eu
      ${captureRegion}
      ${pkgs.tesseract}/bin/tesseract "$SCREENSHOT" stdout 2>/dev/null \
        | ${pkgs.wl-clipboard}/bin/wl-copy --type text/plain
    '';

    pickColor = pkgs.writeScriptBin "niri-pick-color" ''
      #!${pkgs.dash}/bin/dash
      set -eu
      niri msg pick-color \
        | ${pkgs.wl-clipboard}/bin/wl-copy --type text/plain
    '';
  in {
    home.packages = [
      pkgs.jq
      waytator
      niriPin
      pin
      edit
      ocr
      pickColor
    ];

    systemd.user.services.niri-pin = {
      Install.WantedBy = ["graphical-session.target"];
      Unit = {
        Description = "Resident Niri image pin service";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${niriPin}/bin/niri-pin --daemon";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    wayland.windowManager.niri.settings = {
      window-rule = [
        {
          match._props."app-id" = "^niri-pin$";
          open-floating = true;
          focus-ring.off = {};
          border = {
            on = {};
            active-color = "#cba6f7";
            inactive-color = "#cba6f7";
          };
        }
        {
          match._props."app-id" = "^dev\\.faetalize\\.waytator$";
          open-floating = true;
        }
      ];
      binds = {
        "Shift+Print" = {
          _props.repeat = false;
          spawn = "niri-pin-to-screen";
        };
        "Alt+Print" = {
          _props.repeat = false;
          spawn = "niri-edit-screenshot";
        };
        "Ctrl+Print" = {
          _props.repeat = false;
          spawn = "niri-region-ocr";
        };
        "Mod+Shift+C" = {
          _props.repeat = false;
          spawn = "niri-pick-color";
        };
      };
    };
  };
}
