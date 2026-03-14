import QtQuick
import QtQuick.Layouts
import qs.Theme

Text {
    Layout.fillHeight: true
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
