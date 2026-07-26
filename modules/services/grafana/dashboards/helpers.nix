# Shared dashboard-building helpers: PromQL target-shape builders and panel
# constructors used across the custom dashboards (fleet.nix, storage.nix).
{lib}: let
  ds = {
    type = "prometheus";
    uid = "prometheus";
  };

  # Three target shapes:
  #   tgt  — range query for timeseries panels (keeps a legend).
  #   stgt — instant query for stat panels (time_series format; a table format
  #          here collapses multi-series into a single cell — the "one giant UP"
  #          bug — and mislabels single values as "Value").
  #   ttgt — instant query in table format for table panels.
  tgt = expr: legend: {
    refId = "A";
    inherit expr;
    legendFormat = legend;
    datasource = ds;
    editorMode = "code";
  };
  stgt = expr:
    (tgt expr "")
    // {
      instant = true;
      range = false;
    };
  ttgt = expr:
    (stgt expr)
    // {
      format = "table";
    };
in {
  mkStat = {
    x,
    y,
    w ? 6,
    h ? 4,
    title,
    expr,
    unit ? "none",
    colorMode ? "value",
    mappings ? [],
    thresholds ? {
      mode = "absolute";
      steps = [
        {
          value = null;
          color = "text";
        }
      ];
    },
  }: {
    type = "stat";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [(stgt expr)];
    fieldConfig = {
      defaults = {
        inherit unit thresholds mappings;
        color = {mode = "thresholds";};
      };
      overrides = [];
    };
    options = {
      inherit colorMode;
      graphMode = "none";
      textMode = "value";
      justifyMode = "auto";
      reduceOptions = {
        calcs = ["lastNotNull"];
        fields = "";
        values = false;
      };
    };
  };

  # Multi-series stat rendered as a single vertical column: one colour-filled
  # block per series (name + value), tinted by threshold. Unlike mkStat this
  # keeps every series (values=false, no table format) instead of reducing to one.
  mkStatBoard = {
    x,
    y,
    w,
    h,
    title,
    expr,
    legend,
    unit ? "percent",
    thresholds,
    mappings ? [],
  }: {
    type = "stat";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [
      {
        refId = "A";
        inherit expr;
        legendFormat = legend;
        datasource = ds;
        editorMode = "code";
        instant = true;
        range = false;
      }
    ];
    fieldConfig = {
      defaults = {
        inherit unit thresholds mappings;
        color = {mode = "thresholds";};
      };
      overrides = [];
    };
    options = {
      colorMode = "background";
      graphMode = "none";
      textMode = "value_and_name";
      justifyMode = "auto";
      # horizontal = one full-width bar per service, stacked into rows
      orientation = "horizontal";
      # force legible text — otherwise many rows auto-shrink the font to nothing
      text = {
        titleSize = 13;
        valueSize = 15;
      };
      reduceOptions = {
        calcs = ["lastNotNull"];
        fields = "";
        values = false;
      };
    };
  };

  mkTimeseries = {
    x,
    y,
    w ? 8,
    h ? 8,
    title,
    expr,
    unit ? "short",
    legend ? "{{instance}}",
    min ? null,
    max ? null,
    timeFrom ? null, # per-panel relative window (e.g. "24h"), ignores the picker
  }:
    {
      type = "timeseries";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = [(tgt expr legend)];
    }
    // lib.optionalAttrs (timeFrom != null) {inherit timeFrom;}
    // {
      fieldConfig = {
        defaults =
          {
            inherit unit;
            custom = {
              fillOpacity = 10;
              showPoints = "never";
              lineWidth = 1;
            };
          }
          // lib.optionalAttrs (min != null) {inherit min;}
          // lib.optionalAttrs (max != null) {inherit max;};
        overrides = [];
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {mode = "multi";};
      };
    };

  # One metric -> a clean two-column table (label + value), dropping the Time and
  # job columns Prometheus tables carry by default. The value column is renamed,
  # unit-formatted, colour-coded by threshold, and optionally value-mapped.
  # Extra labels beyond `instance` (e.g. device) pass through as-is.
  mkMetricTable = {
    x,
    y,
    w ? 12,
    h ? 8,
    title,
    expr,
    labelName, # rename of the source label column -> header
    valueName, # rename of the `Value` column
    labelCol ? "instance", # which label column becomes `labelName`
    dropCols ? [], # extra columns to hide (e.g. the raw `instance` URL)
    labelMappings ? [], # value mappings for the label column (raw value -> display)
    valueUnit ? "short",
    valueAlign ? null, # override the value column's alignment (e.g. "right")
    thresholds ? null,
    mappings ? [],
    cellColor ? false,
    rowColor ? false, # tint the whole row by the value threshold, not just its cell
  }: let
    valueProps =
      [
        {
          id = "unit";
          value = valueUnit;
        }
      ]
      ++ lib.optional (thresholds != null) {
        id = "thresholds";
        value = thresholds;
      }
      ++ lib.optional (mappings != []) {
        id = "mappings";
        value = mappings;
      }
      ++ lib.optional (valueAlign != null) {
        id = "custom.align";
        value = valueAlign;
      }
      ++ lib.optional (cellColor || rowColor) {
        id = "custom.cellOptions";
        value =
          {type = "color-background";}
          // lib.optionalAttrs rowColor {applyToRow = true;};
      };
  in {
    type = "table";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [(ttgt expr)];
    transformations = [
      {
        id = "organize";
        options = {
          excludeByName =
            {
              Time = true;
              job = true;
            }
            // lib.genAttrs dropCols (_: true);
          renameByName = {
            "${labelCol}" = labelName;
            Value = valueName;
          };
          indexByName = {};
        };
      }
    ];
    fieldConfig = {
      defaults = {custom = {align = "auto";};};
      overrides =
        [
          {
            matcher = {
              id = "byName";
              options = valueName;
            };
            properties = valueProps;
          }
        ]
        ++ lib.optional (labelMappings != []) {
          matcher = {
            id = "byName";
            options = labelName;
          };
          properties = [
            {
              id = "mappings";
              value = labelMappings;
            }
          ];
        };
    };
    options = {
      showHeader = true;
      cellHeight = "sm";
      footer = {show = false;};
    };
  };

  # A "custom" template variable: a static dropdown of values. Used to expose a
  # window selector that drives per-panel timeFrom (e.g. the trend graphs).
  mkCustomVar = {
    name,
    label,
    values,
    default,
  }: {
    inherit name label;
    type = "custom";
    query = lib.concatStringsSep "," values;
    current = {
      selected = true;
      text = default;
      value = default;
    };
    options =
      map (v: {
        text = v;
        value = v;
        selected = v == default;
      })
      values;
    includeAll = false;
    multi = false;
    hide = 0;
    skipUrlSync = false;
  };

  mkDashboard = {
    uid,
    title,
    tags ? ["homelab"],
    panels,
    variables ? [],
    refresh ? "1m",
    from ? "now-6h",
    hideTimePicker ? false,
  }: {
    inherit uid title tags refresh;
    schemaVersion = 39;
    editable = false;
    timezone = "browser";
    time = {
      inherit from;
      to = "now";
    };
    timepicker = {hidden = hideTimePicker;};
    templating = {list = variables;};
    annotations = {list = [];};
    panels = lib.imap1 (i: p: p // {id = i;}) panels;
  };

  greenAtOne = {
    mode = "absolute";
    steps = [
      {
        value = null;
        color = "green";
      }
      {
        value = 1;
        color = "red";
      }
    ];
  };

  # A stat cell can't render two live numbers, so the denominator is appended as
  # a custom suffix unit and colour keys off the count: green at full, red if any
  # are missing.
  upTotalSuffix = full: "suffix: / ${toString full}";
  upTotalThresholds = full: {
    mode = "absolute";
    steps = [
      {
        value = null;
        color = "red";
      }
      {
        value = full;
        color = "green";
      }
    ];
  };
}
