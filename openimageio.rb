class Openimageio < Formula
  desc "Library for reading, processing and writing images"
  homepage "http://openimageio.org"
  url "https://github.com/OpenImageIO/oiio/archive/Release-1.7.16.tar.gz"
  sha256 "12576b336e734ce196961b19847c166805c61f4729c9aa5d6a5957eb7a056539"
  revision 1
  head "https://github.com/OpenImageIO/oiio.git"

  bottle do
    cellar :any
    sha256 "a68f7cadae192d783844c6d5fb723f218110b0a396e140a69b391bd76c9b91f1" => :sierra
    sha256 "25488769e44197d58edac6efdb84c85739acaa7ecce90ec55c95ef4b910d1568" => :el_capitan
    sha256 "9b38d9aefe075675ddf08d8f6e9ddac2002d54717e90d6e7a84c78ad81a74944" => :yosemite
  end

  option "with-test", "Dowload 95MB of test images and verify Oiio (~2 min)"
  option "with-jpeg-turbo", "Build with libjpeg-turbo support, instead of libjpeg"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "openssl"
  depends_on "cfitsio"
  depends_on "field3d"
  depends_on "freetype"
  depends_on "giflib"
  depends_on "hdf5"
  depends_on "ilmbase"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "opencolorio"
  depends_on "openexr"
  depends_on "openjpeg"
  depends_on "webp"
  depends_on "ffmpeg" => :recommended
  depends_on "libraw" => :recommended
  depends_on "ptex" => :recommended
  depends_on "opencv" => :recommended
  depends_on :python3 => :optional
  depends_on "jpeg-turbo" => :optional

  depends_on "boost-python" => (build.with?("python3") ? ["with-python3"] : [])

  resource "j2kp4files" do
    url "http://pkgs.fedoraproject.org/repo/pkgs/openjpeg/j2kp4files_v1_5.zip/27780ed3254e6eb763ebd718a8ccc340/j2kp4files_v1_5.zip"
    sha256 "21cf3156ed2a2a39765c0d57f36c71d1291e9c30054775a2f0a8fdd2964f1799"
  end

  # DNS cannot resolve ftp.remotesensing.org to 140.211.15.132
  resource "tiffpic" do
    url "ftp://140.211.15.132/pub/libtiff/pics-3.8.0.tar.gz"
    mirror "http://dl.maptools.org/dl/libtiff/pics-3.8.0.tar.gz"
    mirror "ftp://ftp.ntua.gr/pub/graphics/tiff/pics-3.8.0.tar.gz"
    mirror "ftp://ftp.u-aizu.ac.jp/pub/graphics/image/ImageMagick/simplesystems.org/libtiff/pics-3.8.0.tar.gz"
    sha256 "e0e34732b61e1ce49eff2c7a079994c856d2a5f772f5228c84678272bc6829a9"
  end

  resource "bmpsuite" do
    url "http://entropymine.com/jason/bmpsuite/bmpsuite.zip"
    sha256 "7c7643003476da4e2b29ebbb0ed1ca28cf7eb21a04b4f474567c1bea5caba089"
    version "1.0.0"
  end

  resource "tgautils" do
    url "https://github.com/dunn/mirrors/raw/master/openimageio/TGAUTILS.ZIP"
    sha256 "1c05c376800d75332e544b665354b9e234f97352266b4dea40d5424d8bcb3299"
    version "1.0.0"
  end

  resource "openexrimages" do
    url "https://download.savannah.nongnu.org/releases/openexr/openexr-images-1.7.0.tar.gz"
    sha256 "99e3fabef4672f62f4a10a470eea4a161026d488cabc418fff619638deacf807"
  end

  resource "oiioimages" do
    url "https://github.com/OpenImageIO/oiio-images.git",
        :revision => "9a70c65c7a29a50114a8208d61c87ba4fedd018e"
  end

  def pyver
    Language::Python.major_minor_version "python"
  end

  def py3ver
    Language::Python.major_minor_version "python3"
  end

  def install
    # Oiio is designed to have its testsuite images extracted one directory
    # above the source.  That's not a safe place for HB.  Do the opposite,
    # and move the entire source down into a subdirectory if --with-test.
    if build.with? "test"
      (buildpath+"localpub").install Dir["*"]
      chdir "localpub"
    end

    ENV.append "MY_CMAKE_FLAGS", "-Wno-dev" # stops a warning.
    ENV.append "MY_CMAKE_FLAGS", "-DUSE_OPENCV=OFF" if build.without? "opencv"
    ENV.append "MY_CMAKE_FLAGS", "-DUSE_JPEGTURBO=OFF" if build.without? "jpeg-turbo"
    ENV.append "MY_CMAKE_FLAGS", "-DCMAKE_FIND_FRAMEWORK=LAST"
    ENV.append "MY_CMAKE_FLAGS", "-DCMAKE_VERBOSE_MAKEFILE=ON"
    ENV.append "MY_CMAKE_FLAGS", "-DUSE_NUKE=OFF"

    ENV.append "MY_CMAKE_FLAGS", "-DUSE_FFMPEG=OFF" if build.without? "ffmpeg"
    ENV.append "MY_CMAKE_FLAGS", "-DUSE_LIBRAW=OFF" if build.without? "libraw"
    ENV.append "MY_CMAKE_FLAGS", "-DUSE_PTEX=OFF" if build.without? "ptex"

    # CMake picks up the system's python dylib, even if we have a brewed one.
    # Code taken from the Insighttoolkit formula
    if build.with? "python3"
      ENV["PYTHONPATH"] = lib/"python#{py3ver}/site-packages"
      ENV.append "MY_CMAKE_FLAGS", "-DPYTHON_EXECUTABLE='#{`python3-config --prefix`.chomp}/bin/python3'"
      ENV.append "MY_CMAKE_FLAGS", "-DPYTHON_LIBRARY='#{`python3-config --prefix`.chomp}/lib/libpython#{py3ver}.dylib'"
      ENV.append "MY_CMAKE_FLAGS", "-DPYTHON_INCLUDE_DIR='#{`python3-config --prefix`.chomp}/include/python#{py3ver}m'"
    end

    args = ["EMBEDPLUGINS=1"]

    # Download standardized test images if the user throws --with-test.
    # 90% of the images are in tarballs, so they are cached normally.
    # The webp and fits images are loose.  Curl them each install.
    if build.with? "test"
      d = buildpath

      mkdir d+"webp-images" do
        curl "http://www.gstatic.com/webp/gallery/[1-5].webp", "-O"
      end
      mkdir d+"fits-images"
      mkdir d+"fits-images/pg93" do
        curl "http://www.cv.nrao.edu/fits/data/tests/pg93/tst000[1-3].fits", "-O"
        curl "http://www.cv.nrao.edu/fits/data/tests/pg93/tst000[5-9].fits", "-O"
        curl "http://www.cv.nrao.edu/fits/data/tests/pg93/tst0013.fits", "-O"
      end
      mkdir d+"fits-images/ftt4b" do
        curl "http://www.cv.nrao.edu/fits/data/tests/ftt4b/file00[1-3].fits", "-O"
        curl "http://www.cv.nrao.edu/fits/data/tests/ftt4b/file0{09,12}.fits", "-O"
      end

      resource("j2kp4files").stage { (d+"j2kp4files_v1_5").install Dir["J2KP4files/*"] }
      resource("tiffpic").stage { (d+"libtiffpic").install Dir["*"] }
      resource("bmpsuite").stage { (d+"bmpsuite").install Dir["*"] }
      resource("tgautils").stage { (d+"TGAUTILS").install Dir["*"] }
      resource("openexrimages").stage { (d+"openexr-images").install Dir["*"] }
      resource("oiioimages").stage { (d+"oiio-images").install Dir["*"] }
    end

    args << "USE_OPENGL=OFF"
    args << "USE_QT=OFF"
    args << "USE_PYTHON3=ON" if build.with? "python3"

    system "make", *args
    system "make", "test" if build.with? "test"
    cd "dist/macosx" do
      (lib/"python#{pyver}/site-packages").install Dir["python/*"]
      (lib/"python#{py3ver}/site-packages").install Dir["python3/*"] if build.with? "python3"
      prefix.install %w[bin include]
      lib.install Dir["lib/lib*"]
      doc.install "doc/openimageio.pdf"
      prefix.install Dir["doc/*"]
    end
  end

  test do
    system bin/"oiiotool", "--info", test_fixtures("test.jpg")
    system bin/"oiiotool", "--info", test_fixtures("test.png")
  end
end
