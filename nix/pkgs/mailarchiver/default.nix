# MailArchiver — .NET email archival app built with buildDotnetModule.
{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
}: let
  # renovate: datasource=github-releases depName=s1t5/mail-archiver versioning=loose
  version = "2611.2";
in
  buildDotnetModule {
    pname = "mail-archiver";
    inherit version;

    src = fetchFromGitHub {
      owner = "s1t5";
      repo = "mail-archiver";
      rev = version;
      sha256 = "0xnci0f16r552sby4gwj2gqfal1mklg80dpfbk2zhndk62fw0dc7";
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
