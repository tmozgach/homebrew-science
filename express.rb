class Express < Formula
  desc "Streaming quantification for sequencing"
  homepage "http://bio.math.berkeley.edu/eXpress/"
  url "https://pachterlab.github.io/eXpress/downloads/express-1.5.1/express-1.5.1-src.tgz"
  sha256 "0c5840a42da830fd8701dda8eef13f4792248bab4e56d665a0e2ca075aff2c0f"
  revision 7
  head "https://github.com/adarob/eXpress.git"

  # doi "10.1038/nmeth.2251"
  # tag "bioinformatics"

  bottle do
    cellar :any
    sha256 "ec9ceeca8fca3aa5d54a6daa07ef75fa7ec973d8fb8a4055ee7a6794cfbd93c3" => :sierra
    sha256 "8e9c84c337b7e3fcb6ee2b410fb6d29416e1b4c6fc442ede8090df6dfc81ee48" => :el_capitan
    sha256 "4b8cf3976c2555bc58b7e6f5add4a1c7f0b1151e7625e630b5827e6058109a6b" => :yosemite
    sha256 "963c647325403042dfc4e4f948377ab2bdde8ad6d1c8a1a04caba886c635ceef" => :x86_64_linux
  end

  depends_on "bamtools"
  depends_on "boost"
  depends_on "cmake" => :build
  depends_on "protobuf" => :recommended
  depends_on "gperftools" => :recommended

  def install
    inreplace "CMakeLists.txt", "set(Boost_USE_STATIC_LIBS ON)", ""

    # Fix undefined reference to `deflate'
    inreplace "src/CMakeLists.txt", 'libbamtools.a"', 'libbamtools.a" "-lz"'

    mkdir "bamtools"
    ln_s Formula["bamtools"].include/"bamtools", "bamtools/include"
    ln_s Formula["bamtools"].lib, "bamtools/"
    system "cmake", ".", *std_cmake_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/express 2>&1", 1)
  end
end
