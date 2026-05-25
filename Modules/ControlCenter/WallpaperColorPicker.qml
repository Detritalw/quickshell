import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Components
import qs.Widgets.common

Item {
    id: root

    property color currentColor: Appearance.colors.colPrimary
    property real hue: currentColor.hsvHue
    property real saturation: currentColor.hsvSaturation
    property real value: currentColor.hsvValue
    property real gradientX: saturation
    property real gradientY: 1 - value
    property var recentColors: []
    readonly property var standardColors: ["#f44336", "#e91e63", "#9c27b0", "#673ab7", "#3f51b5", "#2196f3", "#03a9f4", "#00bcd4", "#009688", "#4caf50", "#8bc34a", "#cddc39", "#ffeb3b", "#ffc107", "#ff9800", "#ff5722", "#d32f2f", "#c2185b", "#7b1fa2", "#512da8", "#303f9f", "#1976d2", "#0288d1", "#0097a7", "#00796b", "#388e3c", "#689f38", "#afb42b", "#fbc02d", "#ffa000", "#f57c00", "#e64a19", "#ffffff", "#9e9e9e", "#212121"]

    signal colorSelected(string color)

    function showWithColor(colorValue) {
        const next = colorValue && String(colorValue).startsWith("#") ? Qt.color(colorValue) : Appearance.colors.colPrimary;
        currentColor = next;
        updateFromColor(next);
        open();
    }

    function updateFromColor(colorValue) {
        hue = Math.max(0, colorValue.hsvHue);
        saturation = colorValue.hsvSaturation;
        value = colorValue.hsvValue;
        gradientX = saturation;
        gradientY = 1 - value;
    }

    function updateColor() {
        currentColor = Qt.hsva(hue, saturation, value, 1);
    }

    function updateColorFromGradient(x, y) {
        saturation = Math.max(0, Math.min(1, x));
        value = Math.max(0, Math.min(1, 1 - y));
        updateColor();
    }

    function colorToHex(colorValue) {
        const r = Math.round(colorValue.r * 255).toString(16).padStart(2, "0");
        const g = Math.round(colorValue.g * 255).toString(16).padStart(2, "0");
        const b = Math.round(colorValue.b * 255).toString(16).padStart(2, "0");
        return "#" + r + g + b;
    }

    function remember(colorValue) {
        const hex = colorToHex(colorValue);
        const next = [hex];
        for (let i = 0; i < recentColors.length && next.length < 5; i += 1) {
            if (recentColors[i] !== hex)
                next.push(recentColors[i]);
        }
        recentColors = next;
    }

    property bool shouldBeVisible: false
    readonly property real dialogWidth: Math.max(560, Math.min(680, modalWindow.width - 64))
    readonly property real dialogHeight: Math.min(680, Math.max(420, modalWindow.height - 64))

    function open() {
        shouldBeVisible = true;
        Qt.callLater(() => modalContent.forceActiveFocus());
    }

    function close() {
        shouldBeVisible = false;
    }

    PanelWindow {
        id: modalWindow

        visible: root.shouldBeVisible
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "clavis-wallpaper-color-picker"
        WlrLayershell.keyboardFocus: modalWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => modalContent.forceActiveFocus());
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.shouldBeVisible
            onClicked: root.close()
        }

    FocusScope {
        id: modalContent

        anchors.centerIn: parent
        width: root.dialogWidth
        height: root.dialogHeight
        focus: root.shouldBeVisible

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerLow
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            z: -1
            onPressed: mouse => mouse.accepted = true
            onClicked: mouse => mouse.accepted = true
        }

        Keys.onEscapePressed: event => {
            root.close();
            event.accepted = true;
        }

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: 16
            contentWidth: width
            contentHeight: mainColumn.implicitHeight

            ColumnLayout {
                id: mainColumn

                width: parent.width
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "选择壁纸颜色"
                            color: Appearance.colors.colOnSurface
                            font.family: Sizes.fontFamily
                            font.pixelSize: 19
                            font.weight: Font.Medium
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "从调色板中选择颜色，或使用自定义颜色"
                            color: Appearance.colors.colSubtext
                            font.family: Sizes.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    IconButton {
                        iconName: "close"
                        onClicked: root.close()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        id: gradientPicker
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        radius: Appearance.rounding.normal
                        border.color: Appearance.colors.colOutline
                        border.width: 1
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.hsva(root.hue, 1, 1, 1)

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#ffffff" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#000000" }
                                }
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            border.color: "white"
                            border.width: 2
                            color: "transparent"
                            x: root.gradientX * parent.width - width / 2
                            y: root.gradientY * parent.height - height / 2

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 4
                                height: parent.height - 4
                                radius: width / 2
                                border.color: "black"
                                border.width: 1
                                color: "transparent"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.CrossCursor
                            onPressed: mouse => {
                                const x = Math.max(0, Math.min(1, mouse.x / width));
                                const y = Math.max(0, Math.min(1, mouse.y / height));
                                root.gradientX = x;
                                root.gradientY = y;
                                root.updateColorFromGradient(x, y);
                            }
                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return;
                                const x = Math.max(0, Math.min(1, mouse.x / width));
                                const y = Math.max(0, Math.min(1, mouse.y / height));
                                root.gradientX = x;
                                root.gradientY = y;
                                root.updateColorFromGradient(x, y);
                            }
                        }
                    }

                    Rectangle {
                        id: hueSlider
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 280
                        radius: Appearance.rounding.normal
                        border.color: Appearance.colors.colOutline
                        border.width: 1

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.00; color: "#ff0000" }
                            GradientStop { position: 0.17; color: "#ffff00" }
                            GradientStop { position: 0.33; color: "#00ff00" }
                            GradientStop { position: 0.50; color: "#00ffff" }
                            GradientStop { position: 0.67; color: "#0000ff" }
                            GradientStop { position: 0.83; color: "#ff00ff" }
                            GradientStop { position: 1.00; color: "#ff0000" }
                        }

                        Rectangle {
                            width: parent.width
                            height: 4
                            color: "white"
                            border.color: "black"
                            border.width: 1
                            y: root.hue * parent.height - height / 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.SizeVerCursor
                            onPressed: mouse => {
                                root.hue = Math.max(0, Math.min(1, mouse.y / height));
                                root.updateColor();
                            }
                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return;
                                root.hue = Math.max(0, Math.min(1, mouse.y / height));
                                root.updateColor();
                            }
                        }
                    }
                }

                Text {
                    text: "Material Colors"
                    color: Appearance.colors.colOnSurface
                    font.family: Sizes.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }

                StyledGridView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 114
                    cellWidth: 38
                    cellHeight: 38
                    clip: true
                    interactive: false
                    animateAppearance: false
                    animateMovement: false
                    showVerticalScrollBar: false
                    smoothWheelEnabled: false
                    model: root.standardColors

                    delegate: Rectangle {
                        required property string modelData

                        width: 36
                        height: 36
                        radius: 4
                        color: modelData
                        border.color: Appearance.colors.colOutline
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentColor = Qt.color(modelData);
                                root.updateFromColor(root.currentColor);
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    ColumnLayout {
                        Layout.preferredWidth: 210
                        spacing: 8

                        Text {
                            text: "Recent Colors"
                            color: Appearance.colors.colOnSurface
                            font.family: Sizes.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }

                        RowLayout {
                            spacing: 6

                            Repeater {
                                model: 5

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 4
                                    color: index < root.recentColors.length ? root.recentColors[index] : Appearance.colors.colLayer3
                                    opacity: index < root.recentColors.length ? 1 : 0.35
                                    border.color: Appearance.colors.colOutline
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: index < root.recentColors.length
                                        hoverEnabled: enabled
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            root.currentColor = Qt.color(root.recentColors[index]);
                                            root.updateFromColor(root.currentColor);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74
                        Layout.alignment: Qt.AlignBottom
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 74
                                Layout.fillHeight: true
                                radius: Appearance.rounding.small
                                color: root.currentColor
                                border.color: Appearance.colors.colOutline
                                border.width: 1
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Hex"
                                    color: Appearance.colors.colSubtext
                                    font.family: Sizes.fontFamily
                                    font.pixelSize: 12
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    text: root.colorToHex(root.currentColor)
                                    selectByMouse: true
                                    onEditingFinished: {
                                        const pattern = /^#?[0-9A-Fa-f]{6}$/;
                                        if (!pattern.test(text))
                                            return;
                                        const normalized = text.startsWith("#") ? text : "#" + text;
                                        root.currentColor = Qt.color(normalized);
                                        root.updateFromColor(root.currentColor);
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    Layout.alignment: Qt.AlignRight
                    text: "Save"
                    Material.background: Appearance.colors.colPrimary
                    Material.foreground: Appearance.colors.colOnPrimary
                    onClicked: {
                        root.remember(root.currentColor);
                        root.colorSelected(root.colorToHex(root.currentColor));
                        root.close();
                    }
                }
            }
        }
    }
    }

    component IconButton: Item {
        id: iconButton

        property string iconName: ""
        signal clicked

        implicitWidth: 36
        implicitHeight: 36

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: iconMouse.containsMouse ? Appearance.colors.colLayer4 : Appearance.colors.colLayer2
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: iconButton.iconName
            iconSize: 20
            color: Appearance.colors.colOnSurface
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconButton.clicked()
        }
    }
}
