class Vocoflow < Formula
  desc "Tray-first voice dictation app"
  homepage "https://github.com/mayankgujrathi/vocoflow"
  version "0.0.2"
  license "MIT"

  on_macos do
    url "https://github.com/mayankgujrathi/vocoflow/releases/download/v0.0.2/vocoflow-v0.0.2-macos.tar.gz"
    sha256 "b56e242ee4d4669f6996588aee94065f84b732b5871dc4ffed57be5a24f85aa2"
  end

  on_linux do
    url "https://github.com/mayankgujrathi/vocoflow/releases/download/v0.0.2/vocoflow-v0.0.2-linux.AppImage"
    sha256 "b8de0e5357a66b03a01ad7610ceeb78156235ee4ae13c6a19a279da26008ec87"
  end

  def install
    if OS.mac?
      libexec.install "Vocoflow.app"
      bin.install_symlink libexec/"Vocoflow.app/Contents/MacOS/vocoflow" => "vocoflow"
    else
      appimage = Dir["*.AppImage"].first
      raise "Linux AppImage not found in formula payload" if appimage.nil?
      libexec.install appimage => "vocoflow.AppImage"
      chmod 0755, libexec/"vocoflow.AppImage"
      bin.install_symlink libexec/"vocoflow.AppImage" => "vocoflow"
    end
  end

  test do
    system "#{bin}/vocoflow", "--health-check"
  end
end
