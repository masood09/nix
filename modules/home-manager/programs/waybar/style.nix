# Waybar CSS — mechabar-style powerline dividers with Stylix base16 colors.
# Each module section has its own background color; dividers () create
# smooth color transitions between adjacent sections.
# Colors are injected from config.lib.stylix.colors — no hardcoded palette.
{colors}: ''
  /* ---- Base16 colors (injected from Stylix) ---- */
  /* base00 = main bg · base01 = darker bg · base02 = lighter bg */
  /* base05 = text · base0A = yellow · base08 = red · base0B = green · base0E = accent */

  @define-color base00 #${colors.base00};
  @define-color base01 #${colors.base01};
  @define-color base02 #${colors.base02};
  @define-color base03 #${colors.base03};
  @define-color base04 #${colors.base04};
  @define-color base05 #${colors.base05};
  @define-color base08 #${colors.base08};
  @define-color base0A #${colors.base0A};
  @define-color base0B #${colors.base0B};
  @define-color base0E #${colors.base0E};

  /* ---- Semantic color roles ---- */

  @define-color accent    @base0E;
  @define-color main-bg   @base00;
  @define-color main-fg   @base05;
  @define-color main-br   @base04;
  @define-color hover-bg  @base01;
  @define-color hover-fg  alpha(@main-fg, 0.75);
  @define-color outline   shade(@main-bg, 0.5);

  /* ---- Per-module section backgrounds ---- */
  /* Staircase: base01 (darker) → base00 (bar bg) → base02 (lighter) */

  @define-color workspaces  @base01;
  @define-color temperature @base01;
  @define-color memory      @base00;
  @define-color cpu         @base02;
  @define-color clock-time  @base02;
  @define-color clock-date  @base01;
  @define-color tray-bg     @base01;
  @define-color volume      @base01;
  @define-color backlight   @base00;
  @define-color battery     @base02;

  /* ---- State colors ---- */

  @define-color warning  @base0A;
  @define-color critical @base08;
  @define-color charging @base0B;

  /* ---- Reset GTK theme ---- */

  * {
    all: initial;
    color: @main-fg;
    font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
    font-weight: bold;
    font-size: 15px;
  }

  /* Window title and mpris use normal weight */
  #window label,
  #mpris,
  tooltip label {
    font-weight: normal;
  }

  /* Active workspace and distro icon are larger */
  #workspaces button.active label,
  #workspaces button.focused label {
    font-size: 20px;
  }

  #custom-distro {
    font-size: 20px;
  }

  /* Power icon */
  #custom-power {
    font-size: 18px;
  }

  /* Dividers need a larger size so the powerline glyphs fill the bar height */
  #custom-left_div,
  #custom-left_inv,
  #custom-right_div,
  #custom-right_inv {
    font-size: 22px;
  }

  /* Slight bottom offset so glyphs align flush with bar bottom */
  .module {
    margin-bottom: -1px;
  }

  /* ---- Bar container ---- */
  /* @outline border + 4px inner margin creates a floating-bar appearance */

  #waybar {
    background-color: @outline;
  }

  #waybar > box {
    margin: 4px;
    background-color: @main-bg;
  }

  /* ---- Interactive buttons (workspaces) ---- */

  button {
    border-radius: 16px;
    min-width: 16px;
    padding: 0 10px;
  }

  button:hover {
    background-color: @hover-bg;
    color: @hover-fg;
  }

  /* ---- Tooltips ---- */

  tooltip {
    border: 2px solid @main-br;
    border-radius: 10px;
    background-color: @main-bg;
  }

  tooltip > box {
    padding: 0 6px;
  }

  /* ================================================================
     LEFT SECTION: user → workspaces → window
     ================================================================ */

  /* User icon — accent colored label on the far left */
  #custom-user {
    padding: 0 10px;
    color: @accent;
  }

  #custom-user:hover {
    color: @hover-fg;
  }

  /* Dividers that bookend the workspaces pill */
  #custom-left_div.1,
  #custom-right_div.1 {
    color: @workspaces;
  }

  /* Workspaces pill */
  #workspaces {
    padding: 0 1px;
    background-color: @workspaces;
  }

  #workspaces button.active label,
  #workspaces button.focused label {
    color: @accent;
  }

  /* Window title — no background, some margin */
  #window {
    margin: 0 12px;
  }

  /* ================================================================
     CENTER SECTION: temperature → memory → cpu → distro → clock → network/bluetooth
     ================================================================ */

  /* Entry into temperature section from bar background */
  #custom-left_div.2 {
    color: @temperature;
  }

  #temperature {
    background-color: @temperature;
  }

  /* Transition: temperature → memory */
  #custom-left_div.3 {
    background-color: @temperature;
    color: @memory;
  }

  #memory {
    background-color: @memory;
  }

  /* Transition: memory → cpu */
  #custom-left_div.4 {
    background-color: @memory;
    color: @cpu;
  }

  #cpu {
    background-color: @cpu;
  }

  /* Outline cap exiting cpu section, before the distro gap */
  #custom-left_inv.1 {
    color: @cpu;
  }

  /* Entry/exit of the distro accent island */
  #custom-left_div.5,
  #custom-right_div.2 {
    color: @accent;
  }

  /* NixOS distro icon — accent background, dark text */
  #custom-distro {
    padding: 0 10px 0 5px;
    background-color: @accent;
    color: @main-bg;
  }

  /* Outline entry into clock/idle section */
  #custom-right_inv.1 {
    color: @clock-time;
  }

  /* Idle inhibitor sits in the clock-time section */
  #idle_inhibitor {
    background-color: @clock-time;
  }

  #clock.time {
    padding-right: 6px;
    background-color: @clock-time;
  }

  /* Transition: clock-time → clock-date */
  #custom-right_div.3 {
    background-color: @clock-date;
    color: @clock-time;
  }

  #clock.date {
    padding-left: 6px;
    background-color: @clock-date;
  }

  /* Transition: clock-date → network/bluetooth tray */
  #custom-right_div.4 {
    background-color: @tray-bg;
    color: @clock-date;
  }

  #network {
    background-color: @tray-bg;
    padding: 0 6px 0 4px;
  }

  #bluetooth {
    background-color: @tray-bg;
    padding: 0 5px;
  }

  /* Exit from network/bluetooth section back to bar background */
  #custom-right_div.5 {
    color: @tray-bg;
  }

  /* ================================================================
     RIGHT SECTION: tray → mpris → pulseaudio → backlight → battery → power
     ================================================================ */

  /* System tray — no background, some padding */
  #tray {
    padding: 0 8px;
  }

  /* MPRIS media info — no background, some padding */
  #mpris {
    padding: 0 12px;
  }

  /* Entry into volume section */
  #custom-left_div.6 {
    color: @volume;
  }

  /* Both output and input pulseaudio modules share volume background */
  #pulseaudio {
    background-color: @volume;
  }

  /* Transition: volume → backlight */
  #custom-left_div.7 {
    background-color: @volume;
    color: @backlight;
  }

  #backlight {
    background-color: @backlight;
  }

  /* Transition: backlight → battery */
  #custom-left_div.8 {
    background-color: @backlight;
    color: @battery;
  }

  #battery {
    background-color: @battery;
  }

  /* Outline cap exiting battery section, before power button */
  #custom-left_inv.2 {
    color: @battery;
  }

  /* Power icon — no background, accent color, rounded */
  #custom-power {
    padding: 0 19px 0 16px;
    color: @accent;
  }

  #custom-power:hover {
    background-color: @hover-bg;
  }

  /* ================================================================
     HOVER STATES
     ================================================================ */

  #idle_inhibitor:hover,
  #clock.date:hover,
  #network:hover,
  #bluetooth:hover,
  #mpris:hover,
  #pulseaudio:hover {
    color: @hover-fg;
  }

  /* ================================================================
     INACTIVE / MUTED STATES
     ================================================================ */

  #idle_inhibitor.deactivated,
  #mpris.paused,
  #pulseaudio.output.muted,
  #pulseaudio.input.source-muted {
    color: @hover-fg;
  }

  /* ================================================================
     WARNING / CRITICAL / CHARGING STATES
     ================================================================ */

  #memory.warning,
  #cpu.warning,
  #battery.warning {
    color: @warning;
  }

  #temperature.critical,
  #memory.critical,
  #cpu.critical,
  #battery.critical {
    color: @critical;
  }

  #battery.charging {
    color: @charging;
  }
''
