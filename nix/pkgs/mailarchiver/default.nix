{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
}:
buildDotnetModule {
  pname = "mail-archiver";

  # renovate: datasource=github-releases depName=s1t5/mail-archiver versioning=semver
  version = "2602.2";

  src = fetchFromGitHub {
    owner = "s1t5";
    repo = "mail-archiver";

    # renovate: datasource=github-releases depName=s1t5/mail-archiver versioning=semver
    rev = "2602.2";
    sha256 = "1x4n0cwl1x5x02v7l64ys5d56i7wz15a45sgzjm2ny2vc3n95rff";
  };

  # Prefer csproj over sln for reliability
  projectFile = "MailArchiver.csproj";

  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  meta = with lib; {
    description = "Mail-Archiver: automated email archiving, search, export";
    homepage = "https://github.com/s1t5/mail-archiver";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
