{ lib
, stdenv
, fetchFromGitHub
, cmake
, hidapi
}:

stdenv.mkDerivation rec {
  pname = "HeadsetControl";
  version = "2.6";

  src = fetchFromGitHub {
    owner = "Sapd";
    repo = pname;
    rev = version;
    sha256 = "sha256-CKmCnLNf56SamaBNKMC5qAsWbAsUfGPrNYGEE3+N/yg=";
  };

  nativeBuildInputs = [
    cmake
    hidapi
  ];

  meta = with lib; {
    description = "Sidetone and Battery status for Logitech G930, G533, G633, G933 SteelSeries Arctis 7/PRO 2019 and Corsair VOID (Pro) in Linux and MacOSX";
    homepage = "https://github.com/Sapd/HeadsetControl";
    license = with licenses; gpl3;
    maintainers = with maintainers; [ kittywitch ];
    platforms = with platforms; unix;
  };
}
