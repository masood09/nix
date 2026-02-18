{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
}:
buildDotnetModule {
  pname = "mail-archiver";
  version = "2602.1";

  src = fetchFromGitHub {
    owner = "s1t5";
    repo = "mail-archiver";

    # renovate: datasource=github-releases depName=s1t5/mail-archiver versioning=semver
    rev = "2602.1";
    hash = "sha256-GnBSQuSXaSyHQwi18yZBhUfgIYjJ4dw4cuPLhm3bNjI=";
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
