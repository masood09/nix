# Loki systemd log-processing pipeline, templated so that each app-specific
# level-parsing stage only appears in the rendered config when that service
# is actually enabled on this machine. Log-processing stages must all live
# inside the single loki.process "systemd" block (unlike scrape targets,
# which can be split into independent files under environment.etc), so this
# can't be done as separate conditional environment.etc entries the way
# immich/alloy.nix does it for metrics.
{
  config,
  lib,
  ...
}: let
  opencloudEnabled = config.homelab.services.opencloud.enable;
  minecraftEnabled = config.homelab.services.minecraft.enable;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
  uptimeKumaEnabled = config.homelab.services."uptime-kuma".enable;
  immichEnabled = config.homelab.services.immich.enable;
in ''
  // -------------------------
  // Journald source
  // -------------------------
  loki.source.journal "systemd" {
  	relabel_rules = discovery.relabel.systemd.rules
  	forward_to    = [loki.process.systemd_drop.receiver]
  }

  // -------------------------
  // Relabeling rules (journald metadata -> labels)
  // -------------------------
  discovery.relabel "systemd" {
  	targets = []

  	rule {
  		// Extract systemd unit information into a label
  		source_labels = ["__journal__systemd_unit"]
  		target_label  = "unit"
  	}

  	rule {
  		// Extract systemd hostname information into a label
  		source_labels = ["__journal__hostname"]
  		target_label  = "host"
  	}

  	rule {
  		// Extract boot ID information into a label
  		source_labels = ["__journal__boot_id"]
  		target_label  = "boot_id"
  	}

  	rule {
  		// Extract transport information into a label
  		source_labels = ["__journal__transport"]
  		target_label  = "transport"
  	}

  	rule {
  		// Default severity label derived from journald priority.
  		//
  		// This ensures every log stream has a usable `level` label
  		// even when the application log line does not include its own
  		// structured severity field.
  		//
  		// Later pipeline stages may override this with the application's
  		// own `level=...` or JSON `"level"` value when present.
  		source_labels = ["__journal_priority_keyword"]
  		target_label  = "level"
  	}

  	rule {
  		// Preserve the raw journald/systemd priority keyword separately.
  		//
  		// This is useful for debugging and auditing because it represents
  		// the transport-level severity assigned by journald itself
  		// (info, warning, err, etc.), independent of any application-
  		// reported log level.
  		//
  		// If the application provides its own structured log level,
  		// the main `level` label will be overwritten, but this value
  		// remains available as `journal_level`.
  		source_labels = ["__journal_priority_keyword"]
  		target_label  = "journal_level"
  	}
  }

  // -------------------------
  // Processing pipeline
  // - Extract app "level=warn" from log line (logfmt)
  // - Set the stream label "level" from the parsed value
  // -------------------------
  loki.process "systemd" {

  	// -------------------------
  	// JSON logs: {"level":"info", ...}
  	// -------------------------
  	stage.match {
  		selector = "{unit=~\".+\"} |~ \"^{\\\"\""

  		stage.json {
  			expressions = {
  				app_level = "level",
  			}
  		}

  		stage.template {
  			source   = "app_level"
  			template = "{{- $l := lower .Value -}}{{- if eq $l \"warning\" -}}warn{{- else -}}{{$l}}{{- end -}}"
  		}

  		stage.labels {
  			values = {
  				level = "app_level",
  			}
  		}
  	}

  	// -------------------------
  	// logfmt logs: level=warn ts=... msg="..."
  	// -------------------------
  	stage.match {
  		selector = "{unit=~\".+\"} |~ \"(^|[[:space:]])level=\""

  		stage.logfmt {
  			mapping = {
  				app_level = "level",
  			}
  		}

  		stage.template {
  			source   = "app_level"
  			template = "{{- $l := lower .Value -}}{{- if eq $l \"warning\" -}}warn{{- else -}}{{$l}}{{- end -}}"
  		}

  		stage.labels {
  			values = {
  				level = "app_level",
  			}
  		}
  	}

  	${lib.optionalString opencloudEnabled ''
    // -------------------------
    // Collabora: parse "INF/WRN/ERR/TRC" token and override `level`.
    // Example:
    // wsd-... 2026-.. [ ... ] WRN  message| file:line
    // -------------------------
    stage.match {
    	selector = "{unit=\"podman-opencloud-collabora.service\"}"

    	stage.regex {
    		expression = "^[^ ]+\\s+\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}:\\d{2}:\\d{2}\\.\\d+\\s+\\+\\d+\\s+\\[.*\\]\\s+(?P<collabora_level>[A-Z]{3})\\s+"
    	}

    	stage.template {
    		source   = "collabora_level"
    		template = "{{- $l := .Value -}}{{- if eq $l \"INF\" -}}info{{- else if eq $l \"WRN\" -}}warn{{- else if eq $l \"ERR\" -}}error{{- else if eq $l \"TRC\" -}}trace{{- else if eq $l \"DBG\" -}}debug{{- else if eq $l \"FTL\" -}}fatal{{- else -}}{{ lower $l }}{{- end -}}"
    	}

    	stage.labels {
    		values = {
    			level = "collabora_level",
    		}
    	}
    }
  ''}

  	${lib.optionalString minecraftEnabled ''
    // -------------------------
    // Velocity: parse "[HH:MM:SS LEVEL]:" prefix and override `level`.
    // Example: [06:44:23 WARN]: Player info forwarding is disabled!
    // -------------------------
    stage.match {
    	selector = "{unit=\"minecraft-server-velocity.service\"}"

    	stage.regex {
    		expression = "^\\[\\d{2}:\\d{2}:\\d{2} (?P<velocity_level>[A-Z]+)\\]:"
    	}

    	stage.template {
    		source   = "velocity_level"
    		template = "{{- $l := .Value -}}{{- if eq $l \"WARN\" -}}warn{{- else if eq $l \"ERROR\" -}}error{{- else if eq $l \"FATAL\" -}}fatal{{- else if eq $l \"DEBUG\" -}}debug{{- else if eq $l \"TRACE\" -}}trace{{- else if eq $l \"INFO\" -}}info{{- else -}}{{ lower $l }}{{- end -}}"
    	}

    	stage.labels {
    		values = {
    			level = "velocity_level",
    		}
    	}
    }

    // Velocity: bare JVM stack traces have no "[HH:MM:SS LEVEL]:" prefix, so
    // the stage above leaves them on journald's stdout-default "info" — e.g.
    // the Java-25 class-file-version crash loop
    // (java.lang.UnsupportedClassVersionError / "Error: LinkageError...").
    // journald priority is transport-level only (stdout is always "info"
    // regardless of content), so a real crash silently reads as routine
    // unless caught here.
    // -------------------------
    stage.match {
    	selector = "{unit=\"minecraft-server-velocity.service\"} |~ \"^(Error:|[A-Za-z][A-Za-z.$]*(Exception|Error)\\\\b|\\\\s+at\\\\s|Caused by:)\""

    	stage.static_labels {
    		values = {
    			level = "error",
    		}
    	}
    }

    // -------------------------
    // Minecraft: parse "[HH:MM:SS] [Thread/LEVEL]:" prefix and
    // override `level`. Same class of fix as Velocity, but the log4j thread
    // tag sits before the level instead of a bare bracket.
    // Example: [02:11:05] [Server thread/WARN]: Can't keep up! ...
    // -------------------------
    stage.match {
    	selector = "{unit=\"minecraft-server-forever.service\"}"

    	stage.regex {
    		expression = "^\\[\\d{2}:\\d{2}:\\d{2}\\] \\[[^/\\]]+/(?P<mc_level>[A-Z]+)\\]:"
    	}

    	stage.template {
    		source   = "mc_level"
    		template = "{{- $l := .Value -}}{{- if eq $l \"WARN\" -}}warn{{- else if eq $l \"ERROR\" -}}error{{- else if eq $l \"FATAL\" -}}fatal{{- else if eq $l \"DEBUG\" -}}debug{{- else if eq $l \"TRACE\" -}}trace{{- else if eq $l \"INFO\" -}}info{{- else -}}{{ lower $l }}{{- end -}}"
    	}

    	stage.labels {
    		values = {
    			level = "mc_level",
    		}
    	}
    }
  ''}

  	${lib.optionalString postgresqlEnabled ''
    // -------------------------
    // PostgreSQL: parse "[pid] LEVEL:" prefix and override `level`.
    // Discovered via FATAL connection-loss lines reading as info — journald
    // priority mapping doesn't inspect content, so genuine DB-level errors
    // were indistinguishable from routine checkpoint LOG lines.
    // Example: [1641972] FATAL:  connection to client lost
    // -------------------------
    stage.match {
    	selector = "{unit=\"postgresql.service\"}"

    	stage.regex {
    		expression = "^\\[\\d+\\] (?P<pg_level>[A-Z]+):"
    	}

    	stage.template {
    		source   = "pg_level"
    		template = "{{- $l := .Value -}}{{- if eq $l \"LOG\" -}}info{{- else if eq $l \"WARNING\" -}}warn{{- else if eq $l \"ERROR\" -}}error{{- else if eq $l \"FATAL\" -}}fatal{{- else if eq $l \"PANIC\" -}}fatal{{- else if eq $l \"NOTICE\" -}}info{{- else -}}{{ lower $l }}{{- end -}}"
    	}

    	stage.labels {
    		values = {
    			level = "pg_level",
    		}
    	}
    }
  ''}

  	${lib.optionalString uptimeKumaEnabled ''
    // -------------------------
    // Uptime Kuma: parse ANSI-colored "LEVEL:" token and override `level`.
    // Monitor-down/warn events (the tool's own alerting signal) were
    // reading as info.
    // Example: [MONITOR] WARN: Monitor #1 'Authentik': Failing: ...
    // -------------------------
    stage.match {
    	selector = "{unit=\"uptime-kuma.service\"}"

    	stage.regex {
    		expression = "\\x1b\\[\\d+m(?P<kuma_level>[A-Z]+):\\x1b\\[0m"
    	}

    	stage.template {
    		source   = "kuma_level"
    		template = "{{- $l := .Value -}}{{- if eq $l \"WARN\" -}}warn{{- else if eq $l \"ERROR\" -}}error{{- else if eq $l \"INFO\" -}}info{{- else -}}{{ lower $l }}{{- end -}}"
    	}

    	stage.labels {
    		values = {
    			level = "kuma_level",
    		}
    	}
    }
  ''}

  	${lib.optionalString immichEnabled ''
    // -------------------------
    // Immich: parse ANSI-colored NestJS level token and override `level`.
    // Plugin-load ERROR lines were reading as info; NestJS's own "LOG"
    // level maps to info.
    // Example: [Nest] 1618771 ... [31m  ERROR[39m [Microservices:PluginService] ...
    // -------------------------
    stage.match {
    	selector = "{unit=\"immich-server.service\"}"

    	stage.regex {
    		expression = "\\x1b\\[3\\dm\\s*(?P<immich_level>LOG|WARN|ERROR|DEBUG|VERBOSE|FATAL)\\x1b\\[39m"
    	}

    	stage.template {
    		source   = "immich_level"
    		template = "{{- $l := .Value -}}{{- if eq $l \"LOG\" -}}info{{- else if eq $l \"WARN\" -}}warn{{- else if eq $l \"ERROR\" -}}error{{- else if eq $l \"FATAL\" -}}fatal{{- else if eq $l \"VERBOSE\" -}}trace{{- else -}}{{ lower $l }}{{- end -}}"
    	}

    	stage.labels {
    		values = {
    			level = "immich_level",
    		}
    	}
    }
  ''}

  	// -------------------------
  	// Fallback: only if level still missing/empty
  	// -------------------------
  	stage.match {
  		// Use regex-empty; more reliable than {level=""} in many setups
  		selector = "{level=~\"^$\"}"

  		stage.labels {
  			values = {
  				level = "journal_level",
  			}
  		}
  	}

  	// -------------------------
  	// Redact sensitive query-string values before shipping to Loki.
  	// Caddy access logs record the full request URI, which for Vaultwarden's
  	// /notifications/hub carries the WebSocket JWT as ?access_token=..., and for
  	// OAuth callbacks carries ?code=.... Strip the values so bearer tokens and
  	// single-use auth codes never land in the log store. The capture group is
  	// the value only, so the parameter name is preserved (e.g. access_token=REDACTED).
  	// -------------------------
  	stage.replace {
  		expression = "access_token=([^&\"]+)"
  		replace    = "REDACTED"
  	}

  	stage.replace {
  		expression = "[?&]code=([^&\"]+)"
  		replace    = "REDACTED"
  	}

  	forward_to = [loki.write.logs_service.receiver]
  }
''
