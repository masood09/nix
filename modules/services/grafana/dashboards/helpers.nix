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
    description ? null, # shown as a hoverable info icon next to the title
    decimals ? null,
    step ? null, # pin the query step (seconds), which feeds $__rate_interval
    thresholds ? {
      mode = "absolute";
      steps = [
        {
          value = null;
          color = "text";
        }
      ];
    },
  }:
    {
      type = "stat";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = [(stgt expr // lib.optionalAttrs (step != null) {inherit step;})];
    }
    // lib.optionalAttrs (description != null) {inherit description;}
    // {
      fieldConfig = {
        defaults =
          {
            inherit unit thresholds mappings;
            color = {mode = "thresholds";};
          }
          // lib.optionalAttrs (decimals != null) {inherit decimals;};
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
    description ? null,
    links ? [], # per-field data links (e.g. click-through to another dashboard)
  }:
    {
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
    }
    // lib.optionalAttrs (description != null) {inherit description;}
    // {
      fieldConfig = {
        defaults = {
          inherit unit thresholds mappings links;
          color = {mode = "thresholds";};
        };
        overrides = [];
      };
      options = {
        colorMode = "background_solid";
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
    description ? null,
  }:
    {
      type = "timeseries";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = [(tgt expr legend)];
    }
    // lib.optionalAttrs (timeFrom != null) {inherit timeFrom;}
    // lib.optionalAttrs (description != null) {inherit description;}
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
    description ? null,
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
  in
    {
      type = "table";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = [(ttgt expr)];
    }
    // lib.optionalAttrs (description != null) {inherit description;}
    // {
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

  # Single-value radial gauge (0..max, colour-filled arc by threshold).
  mkGauge = {
    x,
    y,
    w ? 3,
    h ? 4,
    title,
    description ? null,
    expr,
    unit ? "percent",
    min ? 0,
    max ? 100,
    decimals ? null,
    step ? null, # pin the query step (seconds), which feeds $__rate_interval
    thresholds,
  }:
    {
      type = "gauge";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = [(stgt expr // lib.optionalAttrs (step != null) {inherit step;})];
    }
    // lib.optionalAttrs (description != null) {inherit description;}
    // {
      fieldConfig = {
        defaults =
          {
            inherit unit min max thresholds;
            color = {mode = "thresholds";};
            mappings = [
              {
                type = "special";
                options = {
                  match = "null";
                  result = {text = "N/A";};
                };
              }
            ];
          }
          // lib.optionalAttrs (decimals != null) {inherit decimals;};
        overrides = [];
      };
      options = {
        minVizHeight = 75;
        minVizWidth = 75;
        orientation = "auto";
        sizing = "auto";
        showThresholdLabels = false;
        showThresholdMarkers = true;
        reduceOptions = {
          calcs = ["lastNotNull"];
          fields = "";
          values = false;
        };
      };
    };

  # Multi-series horizontal bar gauge — several distinct queries (not a
  # multi-series legend fold like mkStatBoard), each its own coloured bar.
  mkBarGauge = {
    x,
    y,
    w,
    h,
    title,
    description ? null,
    targets, # list of { expr, legend }
    unit ? "percentunit",
    min ? 0,
    max ? 1,
    thresholdsMode ? "absolute",
    step ? null, # pin the query step (seconds), which feeds $__rate_interval
    decimals ? null,
    instant ? true, # upstream sometimes uses a range query even for a last-value bargauge
    thresholds,
  }: let
    refIds = lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    mkTarget = i: t:
      {
        refId = builtins.elemAt refIds i;
        inherit (t) expr;
        legendFormat = t.legend;
        datasource = ds;
        editorMode = "code";
        inherit instant;
        range = !instant;
        format = "time_series";
      }
      // lib.optionalAttrs (step != null) {inherit step;};
  in
    {
      type = "bargauge";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = lib.imap0 mkTarget targets;
    }
    // lib.optionalAttrs (description != null) {inherit description;}
    // {
      fieldConfig = {
        defaults =
          {
            inherit unit min max;
            color = {mode = "thresholds";};
            thresholds = {
              mode = thresholdsMode;
              steps = thresholds;
            };
            mappings = [];
          }
          // lib.optionalAttrs (decimals != null) {inherit decimals;};
        overrides = [];
      };
      options = {
        displayMode = "basic";
        orientation = "horizontal";
        showUnfilled = true;
        valueMode = "color";
        legend = {
          calcs = [];
          displayMode = "list";
          placement = "bottom";
          showLegend = false;
        };
        reduceOptions = {
          calcs = ["lastNotNull"];
          fields = "";
          values = false;
        };
      };
    };

  # Multi-series timeseries with stacking and per-series field overrides
  # (fixed colors, transforms, etc.) — richer than mkTimeseries, which only
  # supports one target and no overrides. `overrides` is a raw passthrough
  # of Grafana override objects ({matcher; properties;}) rather than a
  # built abstraction, since the shapes upstream uses vary too much
  # (fixed-color, custom.fillOpacity, custom.stacking, custom.transform)
  # to usefully generalize.
  mkStackedTimeseries = {
    x,
    y,
    w ? 12,
    h ? 7,
    title,
    description ? null,
    targets, # list of { expr, legend, step ? null }
    unit ? "short",
    min ? null,
    max ? null,
    fillOpacity ? 40,
    lineInterpolation ? "linear",
    stacking ? {
      group = "A";
      mode = "none";
    },
    legendWidth ? null,
    legendCalcs ? [],
    legendDisplayMode ? "list",
    tooltipSort ? "none",
    lineWidth ? 1,
    overrides ? [],
  }: let
    refIds = lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    mkTarget = i: t:
      {
        refId = builtins.elemAt refIds i;
        inherit (t) expr;
        legendFormat = t.legend;
        datasource = ds;
        editorMode = "code";
        instant = false;
        range = true;
        format = "time_series";
      }
      // lib.optionalAttrs (t ? step) {inherit (t) step;};
  in
    {
      type = "timeseries";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = lib.imap0 mkTarget targets;
    }
    // lib.optionalAttrs (description != null) {inherit description;}
    // {
      fieldConfig = {
        defaults =
          {
            inherit unit;
            color = {mode = "palette-classic";};
            custom = {
              axisBorderShow = false;
              axisCenteredZero = false;
              axisColorMode = "text";
              axisLabel = "";
              axisPlacement = "auto";
              barAlignment = 0;
              barWidthFactor = 0.6;
              drawStyle = "line";
              inherit fillOpacity;
              gradientMode = "none";
              hideFrom = {
                legend = false;
                tooltip = false;
                viz = false;
              };
              insertNulls = false;
              inherit lineInterpolation lineWidth;
              pointSize = 5;
              scaleDistribution = {type = "linear";};
              showPoints = "never";
              spanNulls = false;
              inherit stacking;
              thresholdsStyle = {mode = "off";};
            };
            links = [];
            mappings = [];
            thresholds = {
              mode = "absolute";
              steps = [{color = "green";}];
            };
          }
          // lib.optionalAttrs (min != null) {inherit min;}
          // lib.optionalAttrs (max != null) {inherit max;};
        inherit overrides;
      };
      options = {
        legend =
          {
            calcs = legendCalcs;
            displayMode = legendDisplayMode;
            placement = "bottom";
            showLegend = true;
          }
          // lib.optionalAttrs (legendWidth != null) {width = legendWidth;};
        tooltip = {
          hideZeros = false;
          mode = "multi";
          sort = tooltipSort;
        };
      };
    };

  # A Prometheus label_values() query-driven template variable — e.g. a
  # $node dropdown sourced live from a metric's label, rather than a fixed
  # list like mkCustomVar.
  mkQueryVar = {
    name,
    label,
    query, # e.g. "label_values(node_uname_info, instance)"
  }: {
    inherit name label query;
    type = "query";
    datasource = ds;
    definition = query;
    refresh = 1;
    regex = "";
    sort = 1;
    includeAll = false;
    multi = false;
    current = {};
    options = [];
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
    graphTooltip ? 0, # 0 = independent tooltips, 1 = shared crosshair
  }: {
    inherit uid title tags refresh graphTooltip;
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
        color = "transparent"; # 0 = healthy: no fill, just red draws the eye
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
        color = "transparent"; # full count = healthy: no fill, just red draws the eye
      }
    ];
  };
}
