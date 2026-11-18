pragma Singleton
import QtQuick

import qs.modules

QtObject {
    property string bgcolor: ThemeState.themes[ThemeState.themeIndex].bgcolor
    property string rectcolor:  ThemeState.themes[ThemeState.themeIndex].rectcolor
    property string recthovercolor:  ThemeState.themes[ThemeState.themeIndex].recthovercolor
    property string occupiedcolor:  ThemeState.themes[ThemeState.themeIndex].occupiedcolor
    property string bordercolor:  ThemeState.themes[ThemeState.themeIndex].bordercolor
    property string text1:  ThemeState.themes[ThemeState.themeIndex].text1
    property string textmuted:  ThemeState.themes[ThemeState.themeIndex].textmuted
    property string textactive:  ThemeState.themes[ThemeState.themeIndex].textactive
    property string alertcolor:  ThemeState.themes[ThemeState.themeIndex].alertcolor
    property string miconcolor:  ThemeState.themes[ThemeState.themeIndex].miconcolor

    property string fontfamily: "MesloLGL Nerd Font Propo"

    //every size is multiplied by the user's font scale. kept as ints because
    //font.pixelSize is an int, so sub-pixel sizes are rounded away here.
    property int fontxs: Math.round(10 * States.fontScale)
    property int fontsm: Math.round(11 * States.fontScale)
    property int fontmd: Math.round(12 * States.fontScale)
    property int fontbase: Math.round(13 * States.fontScale)
    property int fontlg: Math.round(14 * States.fontScale)
    property int fontxl: Math.round(16 * States.fontScale)
    property int fontxxl: Math.round(20 * States.fontScale)
}
