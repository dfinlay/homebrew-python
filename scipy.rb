require 'formula'

class Scipy < Formula
  homepage 'http://www.scipy.org'
  url 'https://downloads.sourceforge.net/project/scipy/scipy/0.13.3/scipy-0.13.3.tar.gz'
  sha1 '2c7d53fc1d7bfe0a3ab5818ef6d84cb5d8cfcca4'
  head 'https://github.com/scipy/scipy.git'

  depends_on :python => :recommended
  depends_on 'numpy'
  depends_on 'swig' => :build
  depends_on :fortran

  option 'with-openblas', "Use openBLAS (slower for LAPACK functions) instead of Apple's Accelerate Framework"
  depends_on 'homebrew/science/openblas' => :optional

  def install
    config = <<-EOS.undent
      [DEFAULT]
      library_dirs = #{HOMEBREW_PREFIX}/lib
      include_dirs = #{HOMEBREW_PREFIX}/include

      [amd]
      amd_libs = amd, cholmod, colamd, ccolamd, camd, suitesparseconfig
      [umfpack]
      umfpack_libs = umfpack

    EOS
    if build.with? 'openblas'
      # For maintainers:
      # Check which BLAS/LAPACK numpy actually uses via:
      # xcrun otool -L $(brew --prefix)/Cellar/scipy/<version>/lib/python2.7/site-packages/scipy/linalg/_flinalg.so
      # or the other .so files.
      openblas_dir = Formula["openblas"].opt_prefix
      # Setting ATLAS to None is important to prevent numpy from always
      # linking against Accelerate.framework.
      ENV['ATLAS'] = "None"
      ENV['BLAS'] = ENV['LAPACK'] = "#{openblas_dir}/lib/libopenblas.dylib"

      config << <<-EOS.undent
        [openblas]
        libraries = openblas
        library_dirs = #{openblas_dir}/lib
        include_dirs = #{openblas_dir}/include
      EOS
    end

    # The Accelerate.framework uses a g77 ABI
    ENV.append 'FFLAGS', '-ff2c' unless build.with? 'openblas'

    rm_f 'site.cfg' if build.devel?
    Pathname('site.cfg').write config

    # gfortran is gnu95
    system "python", "setup.py", "build", "--fcompiler=gnu95", "install", "--prefix=#{prefix}"
  end

  test do
    system "python", "-c", "import scipy; scipy.test()"
  end
end
