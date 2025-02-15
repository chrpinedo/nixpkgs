{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, autoreconfHook
, writeShellScript
, pkg-config
, texinfo
, pcre2
, swig
, libxml2
, ncurses
, enablePython ? false
, python ? null
}:
let
  isPython3 = enablePython && python.pythonAtLeast "3";
in
stdenv.mkDerivation rec {
  pname = "libredwg";
  version = "0.12.5.6248";

  src = fetchFromGitHub {
    owner = "LibreDWG";
    repo = pname;
    rev = version;
    hash = "sha256-EHfqj+FeZZpQzF9/LFWg+onTMz2/9tvXNcdpZrdjry0=";
    fetchSubmodules = true;
  };

  patches = [
    (fetchpatch {
      name = "dwg2svg-strcasestr-musl-fix.patch";
      # https://github.com/LibreDWG/libredwg/pull/822
      url = "https://github.com/LibreDWG/libredwg/commit/eec0b7aac6d2f695b7b258f47c3bde3f71f963ee.patch";
      hash = "sha256-TjpJuhRl9t0b9NOJ1FEOO0/y586WwaJcNzTM0cTwmYI=";
    })
  ];

  postPatch = let
    printVersion = writeShellScript "print-version" ''
      echo -n ${lib.escapeShellArg version}
    '';
  in ''
    # avoid git dependency
    cp ${printVersion} build-aux/git-version-gen
  '';

  preConfigure = lib.optionalString (stdenv.isDarwin && enablePython) ''
    # prevent configure picking up stack_size from distutils.sysconfig
    export PYTHON_EXTRA_LDFLAGS=" "
  '';

  nativeBuildInputs = [ autoreconfHook pkg-config texinfo ]
    ++ lib.optional enablePython swig;

  buildInputs = [ pcre2 ]
    ++ lib.optionals enablePython [ python ]
    # configurePhase fails with python 3 when ncurses is missing
    ++ lib.optional isPython3 ncurses
  ;

  # prevent python tests from running when not building with python
  configureFlags = lib.optional (!enablePython) "--disable-python";

  doCheck = true;

  # the "xmlsuite" test requires the libxml2 c library as well as the python module
  nativeCheckInputs = lib.optionals enablePython [ libxml2 libxml2.dev ];

  meta = with lib; {
    description = "Free implementation of the DWG file format";
    homepage = "https://savannah.gnu.org/projects/libredwg/";
    maintainers = with maintainers; [ tweber ];
    license = licenses.gpl3Plus;
    platforms = platforms.all;
  };
}
