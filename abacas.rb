class Abacas < Formula
  desc "Automatic contiguation of assembled sequences"
  homepage "https://abacas.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/abacas/abacas.1.3.1.pl"
  sha256 "7a07d3f7cca5c0b38ca811984ef8da536da32932d68c1a6cce33ec2462b930bf"
  # doi "10.1093/bioinformatics/btp347"
  # tag "bioinformatics"

  bottle :unneeded

  depends_on "mummer"

  def install
    inreplace "abacas.1.3.1.pl", "/usr/local/bin/perl", "/usr/bin/env perl"
    bin.install "abacas.1.3.1.pl" => "abacas"
  end

  test do
    assert_match "tblastx", shell_output("#{bin}/abacas -h 2>&1", 255)
  end
end
