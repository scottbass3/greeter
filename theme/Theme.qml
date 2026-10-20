pragma Singleton
import QtQuick
import "../services"

// Colors and fonts. Roles use Material 3 names in the config ("primary",
// "onPrimary"…) so a shell can export its theme as is; QML properties for the
// "on*" roles are named *Text, as `onX:` would be read as a signal handler.
QtObject {
    id: root

    // The selected user's synced colors win over the system ones.
    readonly property var _roles: Object.assign({}, Config.colors, UserTheme.colors)
    function _c(key, fallback) { return _roles[key] !== undefined ? _roles[key] : fallback }

    readonly property color primary:              _c("primary",              "#D0BCFF")
    readonly property color primaryText:          _c("onPrimary",            "#381E72")
    readonly property color secondaryContainer:   _c("secondaryContainer",   "#4A4458")
    readonly property color surface:              _c("surface",              "#1C1B1F")
    readonly property color surfaceContainer:     _c("surfaceContainer",     "#211F26")
    readonly property color surfaceContainerHigh: _c("surfaceContainerHigh", "#2B2930")
    readonly property color surfaceText:          _c("onSurface",            "#E6E1E5")
    readonly property color surfaceVariantText:   _c("onSurfaceVariant",     "#CAC4D0")
    readonly property color outlineVariant:       _c("outlineVariant",       "#49454F")
    readonly property color error:                _c("error",                "#F2B8B5")
    readonly property color errorText:            _c("onError",              "#601410")

    readonly property string fontFamily: Config.font
    readonly property int    fontSizeXs: 11
    readonly property int    fontSizeSm: 13
    readonly property int    fontSizeMd: 15
    readonly property int    fontSizeLg: 18
    readonly property int    radius:     16

    readonly property var locale: Config.locale !== "" ? Qt.locale(Config.locale)
                                : System.locale !== "" ? Qt.locale(System.locale) : Qt.locale()
}
