# GitHub CLI — `gh` for pull requests, issues, and the GitHub API.
#
# git_protocol is set to ssh because every remote in this fleet is an SSH
# remote (git@github.com:...); leaving the upstream "https" default would make
# `gh repo clone` and `gh pr checkout` add https remotes that then fail against
# the ssh-only auth setup.
#
# gitCredentialHelper is left at the upstream default (enabled). It registers a
# helper for https://github.com in git config, which is inert while remotes stay
# on ssh but keeps https clones working if one is ever added.
{
  homelabCfg,
  lib,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.gh.enable {
    programs = {
      gh = {
        enable = true;

        settings = {
          git_protocol = "ssh";
        };
      };
    };
  };
}
