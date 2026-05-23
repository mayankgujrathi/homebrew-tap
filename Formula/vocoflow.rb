class Vocoflow < Formula
  desc "Tray-first voice dictation app"
  homepage "https://github.com/mayankgujrathi/vocoflow"
  version "0.1.2"
  license "MIT"

  on_macos do
    url "https://github.com/mayankgujrathi/vocoflow/releases/download/v0.1.2/vocoflow-v0.1.2-macos.tar.gz"
    sha256 "7a353aa41b204610bb3073d5e6486959d3ad14ff664be919624fe260b0d77949"
  end

  on_linux do
    url "https://github.com/mayankgujrathi/vocoflow/releases/download/v0.1.2/vocoflow-v0.1.2-linux.AppImage"
    sha256 "31a6c173c5dc62cd96cdaaf982b9862b78875c31318f46c0c2136b17cf7809b7"
  end

  def package_available?(probe_cmd)
    system "bash", "-lc", "#{probe_cmd} >/dev/null 2>&1"
  rescue StandardError
    false
  end

  def install_linux_deps
    return unless OS.linux?

    os_release = File.exist?("/etc/os-release") ? File.read("/etc/os-release").downcase : ""

    distro_family = if os_release.match?(/\b(debian|ubuntu|linuxmint|pop|zorin|elementary)\b/)
      :debian
    elsif os_release.match?(/\b(arch|manjaro|endeavouros|garuda)\b/)
      :arch
    elsif os_release.match?(/\b(fedora|rhel|centos|rocky|almalinux)\b/)
      :fedora
    end

    if distro_family.nil?
      opoo "Skipping Linux dependency auto-install: unsupported distro family. Proceeding with normal install."
      return
    end

    opoo "Installing Linux runtime dependencies for #{distro_family} family."

    case distro_family
    when :debian
      packages = %w[
        libgtk-3-0 libwebkit2gtk-4.1-0 libjavascriptcoregtk-4.1-0 libsoup-3.0-0
        libatk1.0-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2 libasound2
        libwayland-client0 libx11-6 libxi6 libxtst6 libxrandr2 libxinerama1
        libxcursor1 libxcb1 libxcb-render0 libxcb-shape0 libxcb-xfixes0
        libxkbcommon0 libxkbcommon-x11-0 libxdo3 libudev1 libayatana-appindicator3-1
        libfuse2 libfuse2t64 inotify-tools
      ]

      available = packages.select do |pkg|
        package_available?("apt-cache show #{pkg}")
      end

      if available.empty?
        opoo "No matching Debian packages found from dependency list. Continuing without auto-install."
      else
        system "bash", "-lc", "DEBIAN_FRONTEND=noninteractive apt-get install -y #{available.join(" ")} >/dev/null 2>&1"
      end
    when :arch
      packages = %w[
        gtk3 webkit2gtk-4.1 libsoup3 at-spi2-core gdk-pixbuf2 pango cairo alsa-lib
        wayland libx11 libxi libxtst libxrandr libxinerama libxcursor libxcb
        xcb-util-renderutil xcb-util xcb-util-wm xcb-util-keysyms libxkbcommon
        libxkbcommon-x11 xdotool systemd libayatana-appindicator fuse2 inotify-tools
      ]

      available = packages.select do |pkg|
        package_available?("pacman -Si #{pkg}")
      end

      if available.empty?
        opoo "No matching Arch packages found from dependency list. Continuing without auto-install."
      else
        system "bash", "-lc", "pacman -S --noconfirm --needed #{available.join(" ")} >/dev/null 2>&1"
      end
    when :fedora
      packages = %w[
        gtk3 webkit2gtk4.1 javascriptcoregtk4.1 libsoup3 atk gdk-pixbuf2
        pango cairo alsa-lib wayland libX11 libXi libXtst libXrandr libXinerama
        libXcursor libxcb xcb-util-renderutil xcb-util xcb-util-wm xcb-util-keysyms
        libxkbcommon libxkbcommon-x11 xdotool systemd-libs
        libayatana-appindicator-gtk3 libappindicator-gtk3 fuse inotify-tools
      ]

      available = packages.select do |pkg|
        package_available?("dnf list --available #{pkg}")
      end

      if available.empty?
        opoo "No matching Fedora packages found from dependency list. Continuing without auto-install."
      else
        system "bash", "-lc", "dnf install -y --skip-broken #{available.join(" ")} >/dev/null 2>&1"
      end
    end
  end

  def install
    libexec.mkpath
    bin.mkpath

    if OS.mac?
      app_bundle = buildpath.glob("*.app").first || buildpath.glob("**/*.app").first
      if app_bundle
        cp_r app_bundle, libexec/"Vocoflow.app"
        cp libexec/"Vocoflow.app/Contents/MacOS/vocoflow", libexec/"vocoflow"
        (libexec/"vocoflow").chmod 0755
        app_resources = app_bundle/"Contents/Resources/resources"
        rm_rf libexec/"resources"
        cp_r app_resources, libexec/"resources" if app_resources.exist?
      else
        fallback_exe = buildpath.glob("**/vocoflow").find { |p| p.file? && p.executable? }
        raise "macOS app bundle (*.app) or fallback vocoflow executable not found in formula payload" if fallback_exe.nil?

        cp fallback_exe, libexec/"vocoflow"
        (libexec/"vocoflow").chmod 0755
      end

      (bin/"vocoflow").write <<~SH
        #!/bin/bash
        exec "#{libexec}/vocoflow" "$@"
      SH
      (bin/"vocoflow").chmod 0755
    else
      install_linux_deps
      (share/"applications").mkpath
      (share/"icons/hicolor/256x256/apps").mkpath
      appimage = buildpath.glob("*.AppImage").first || buildpath.glob("**/*.AppImage").first
      raise "Linux AppImage not found in formula payload" if appimage.nil?
      cp appimage, libexec/"vocoflow.AppImage"
      (libexec/"vocoflow.AppImage").chmod 0755
      (bin/"vocoflow").write <<~SH
        #!/bin/bash
        exec "#{libexec}/vocoflow.AppImage" "$@"
      SH
      (bin/"vocoflow").chmod 0755

      desktop_file = buildpath/"vocoflow.desktop"
      desktop_file.write <<~DESKTOP
        [Desktop Entry]
        Type=Application
        Name=Vocoflow
        Exec=#{bin}/vocoflow
        Icon=vocoflow
        Categories=Utility;
        Terminal=false
      DESKTOP
      (share/"applications").install desktop_file

      system "bash", "-lc", "cd #{buildpath} && #{libexec}/vocoflow.AppImage --appimage-extract vocoflow.png >/dev/null 2>&1 || true"
      extracted_icon = buildpath/"squashfs-root/vocoflow.png"
      if extracted_icon.exist?
        cp extracted_icon, share/"icons/hicolor/256x256/apps/vocoflow.png"
      else
        opoo "Could not extract vocoflow icon from AppImage; desktop entry will use system fallback icon."
      end

      system "bash", "-lc", "command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database #{share}/applications >/dev/null 2>&1 || true"
      system "bash", "-lc", "command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t #{share}/icons/hicolor >/dev/null 2>&1 || true"
      system "bash", "-lc", "command -v xdg-desktop-menu >/dev/null 2>&1 && xdg-desktop-menu forceupdate >/dev/null 2>&1 || true"
    end
  end

  test do
    if OS.mac?
      app_bundle = libexec/"Vocoflow.app"
      if app_bundle.exist?
        app_bin = app_bundle/"Contents/MacOS/vocoflow"
        raise "macOS app executable not found at #{app_bin}" unless app_bin.exist?
        settings_index = app_bundle/"Contents/Resources/resources/settings_window/index.html"
        raise "macOS settings window entrypoint not found at #{settings_index}" unless settings_index.exist?
      else
        fallback_bin = libexec/"vocoflow"
        raise "macOS fallback executable not found at #{fallback_bin}" unless fallback_bin.exist?
      end
    else
      rm_rf testpath/"squashfs-root"
      system "#{libexec}/vocoflow.AppImage", "--appimage-extract"
      extracted_bin = testpath/"squashfs-root/usr/bin/vocoflow"
      raise "Extracted AppImage binary not found at #{extracted_bin}" unless extracted_bin.exist?
      extracted_settings_index = testpath/"squashfs-root/usr/resources/settings_window/index.html"
      raise "Extracted settings window entrypoint not found at #{extracted_settings_index}" unless extracted_settings_index.exist?
    end
  end
end
