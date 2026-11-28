# Agent skills — Matt Pocock's engineering and productivity skills, linked
# into Pi's user skill directory (~/.pi/agent/skills) straight out of the
# Nix store. The input is a plain source tree (`flake = false`), so nothing is
# built and nothing is fetched at agent startup: no `npx skills add`, and no
# npm, which is the only route upstream documents for agents with no plugin
# marketplace of their own. Pi itself is installed the same way in _pi.nix.
#
# Pi reads each skill's SKILL.md, advertises its name and description at
# startup, and loads the body only when a task matches (Pi implements the
# Agent Skills spec). `/skill:<name>` forces one, and `/reload` picks up
# changes without restarting the session.
#
# Two deliberate shapes:
#
# - FLAT. Upstream groups skills as skills/<category>/<name>/; each target
#   directory gets <name>/SKILL.md instead. Pi discovers nested SKILL.md files,
#   so flattening is not required for Pi alone, but it is the layout every
#   Agent Skills harness documents (Claude Code: ~/.claude/skills/<name>) and
#   keeps `/skill:<name>` identical to the upstream name. Supporting files a
#   skill reads by relative path (tdd/tests.md, wizard/template.sh,
#   triage/AGENT-BRIEF.md, the tracker templates under setup-matt-pocock-skills/)
#   live inside the skill directory, so linking the directory covers them.
#
# - ONE target directory. Pi also scans the Agent Skills compatibility location
#   ~/.agents/skills; a copy in both collides on name, and Pi keeps the first
#   match and warns. One source of truth per skill.
#
# Only `engineering` and `productivity` are installed. `misc` is frozen and
# unmaintained upstream (.out-of-scope/frozen-misc-skills.md) and holds
# Claude-Code-only hooks; `in-progress` and `deprecated` need an explicit
# decision per bucket.
#
# The agents/openai.yaml beside every SKILL.md is Codex UI metadata (display
# name, short description, implicit-invocation policy). Pi ignores it; upstream's
# user-vs-model routing works through `disable-model-invocation` in the
# frontmatter, which Pi honours.
#
# These links point at read-only store paths. Upstream invites edits but takes
# no pull requests, so a change belongs here: copy the skill to
# modules/home-manager/programs/agent-skills/<name>/ and list it under
# homelab.programs.agent-skills.overrides, which shadows the upstream copy by
# name. Keep overrides short — upstream rewrites skills under you on every
# `nix flake update mattpocock-skills`.
{
  homelabCfg,
  inputs,
  lib,
  ...
}: let
  cfg = homelabCfg.programs.agent-skills;
  src = inputs.mattpocock-skills;

  # Pi's user skills directory (its configuration docs: <agent-dir>/skills/).
  target = ".pi/agent/skills";

  # A skill is a directory containing SKILL.md. Each category also ships a
  # README.md, which a bare readDir would install as a skill.
  skillNames = cat:
    lib.attrNames (lib.filterAttrs (
      name: type:
        type == "directory" && builtins.pathExists "${src}/skills/${cat}/${name}/SKILL.md"
    ) (builtins.readDir "${src}/skills/${cat}"));

  skills = lib.concatLists (map (
      cat:
        map (name: {
          inherit cat name;
        }) (skillNames cat)
    )
    cfg.categories);

  upstreamLinks = lib.listToAttrs (map (skill:
    lib.nameValuePair "${target}/${skill.name}" {
      source = "${src}/skills/${skill.cat}/${skill.name}";
    })
  skills);

  # Flattening puts every skill under one directory, so a name appearing in two
  # categories would silently lose a link (listToAttrs keeps the last). The
  # buckets are disjoint upstream today; assert rather than find out later.
  nameCounts =
    lib.foldl'
    (acc: name: acc // {${name} = (acc.${name} or 0) + 1;})
    {}
    (map (skill: skill.name) skills);
  duplicateNames = lib.attrNames (lib.filterAttrs (_: count: count > 1) nameCounts);

  # Local forks of single skills, applied after the upstream links so the same
  # path resolves to the copy in this repo.
  overrideLinks = lib.listToAttrs (lib.mapAttrsToList (
      name: path:
        lib.nameValuePair "${target}/${name}" {source = path;}
    )
    cfg.overrides);
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # The only target is Pi's directory, so without Pi the skills are
        # installed where nothing reads them.
        assertion = homelabCfg.programs.pi.enable;
        message = ''
          homelab.programs.agent-skills is enabled but homelab.programs.pi is
          not: these skills install into ~/.pi/agent/skills. Enable Pi, or turn
          the skills off on this machine.
        '';
      }
      {
        # A typo in categories would otherwise install nothing and still look
        # like a working setup.
        assertion = skills != [];
        message = ''
          homelab.programs.agent-skills: categories ${
            lib.concatStringsSep ", " cfg.categories
          } contain no SKILL.md directories under ${src}/skills.
        '';
      }
      {
        assertion = duplicateNames == [];
        message = ''
          homelab.programs.agent-skills: ${
            lib.concatStringsSep ", " duplicateNames
          } appear in more than one of ${lib.concatStringsSep ", " cfg.categories}.
        '';
      }
    ];

    home.file = upstreamLinks // overrideLinks;
  };
}
