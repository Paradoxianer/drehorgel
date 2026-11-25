{{flutter_js}}
{{flutter_build_config}}

// Fallback-Schriften nie von fonts.gstatic.com (Google) nachladen
// (Datenschutz, siehe docs/HEILSARMEE-WEB.md). Roboto liegt im Build selbst.
_flutter.loader.load({
  config: { fontFallbackBaseUrl: "assets/fonts/fallback/" },
});
