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

    opoo "Attempting Linux runtime dependency install for #{distro_family} family (best effort)."

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
        system "bash", "-lc", "DEBIAN_FRONTEND=noninteractive apt-get install -y #{available.join(" ")} >/dev/null 2>&1 || true"
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
        system "bash", "-lc", "pacman -S --noconfirm --needed #{available.join(" ")} >/dev/null 2>&1 || true"
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
        system "bash", "-lc", "dnf install -y --skip-broken #{available.join(" ")} >/dev/null 2>&1 || true"
      end
    end
  end

  def install
    if OS.mac?
      libexec.install "Vocoflow.app"
      (bin/"vocoflow").write_env_script libexec/"Vocoflow.app/Contents/MacOS/vocoflow"
    else
      install_linux_deps
      appimage = Dir["*.AppImage"].first
      raise "Linux AppImage not found in formula payload" if appimage.nil?
      libexec.install appimage => "vocoflow.AppImage"
      chmod 0755, libexec/"vocoflow.AppImage"
      (bin/"vocoflow").write_env_script libexec/"vocoflow.AppImage"

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
        (share/"icons/hicolor/256x256/apps").install extracted_icon => "vocoflow.png"
      else
        opoo "Could not extract vocoflow icon from AppImage; desktop entry will use system fallback icon."
      end
    end
  end

  test do
    system "#{bin}/vocoflow", "--health-check"
  end
end
