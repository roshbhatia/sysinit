import QtQuick
import QtQuick.Layouts
import qs.Theme

Text {
    Layout.fillHeight: true
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: Theme.iconSize
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
