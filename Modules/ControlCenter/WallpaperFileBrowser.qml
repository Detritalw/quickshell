import Qt.labs.folderlistmodel
import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Widgets.common

Popup {
    id: root

    property string startPath: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
    property string currentPath: startPath
    readonly property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string picturesDir: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
    readonly property string downloadsDir: StandardPaths.writableLocation(StandardPaths.DownloadLocation)

    signal fileSelected(string path)
    signal folderSelected(string path)

    function openAt(path) {
        currentPath = path && path !== "" ? path : picturesDir;
        open();
    }

    function encodeFileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split("/").map(s => encodeURIComponent(s)).join("/");
    }

    function navigateTo(path) {
        if (!path || path === "")
            return;
        currentPath = path;
    }

    function navigateUp() {
        if (currentPath === homeDir || currentPath === "/")
            return;
        const index = currentPath.lastIndexOf("/");
        currentPath = index <= 0 ? "/" : currentPath.substring(0, index);
    }

    width: 800
    height: 600
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerLow
        border.width: 1
        border.color: Appearance.m3colors.m3outlineVariant
    }

    FolderListModel {
        id: folderModel

        folder: root.encodeFileUrl(root.currentPath)
        showDirs: true
        showFiles: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: true
        caseSensitive: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif"]
        sortField: FolderListModel.Name
        sortReversed: false
    }

    contentItem: FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: event => {
            root.close();
            event.accepted = true;
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "选择文件夹"
                        color: Appearance.colors.colOnSurface
                        font.family: Sizes.fontFamily
                        font.pixelSize: 19
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "选择图片，或使用当前文件夹作为壁纸目录"
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
                Layout.fillHeight: true
                spacing: 14

                ColumnLayout {
                    Layout.preferredWidth: 170
                    Layout.fillHeight: true
                    spacing: 6

                    SidebarButton {
                        label: "Home"
                        iconName: "home"
                        active: root.currentPath === root.homeDir
                        onClicked: root.navigateTo(root.homeDir)
                    }
                    SidebarButton {
                        label: "Pictures"
                        iconName: "image"
                        active: root.currentPath === root.picturesDir
                        onClicked: root.navigateTo(root.picturesDir)
                    }
                    SidebarButton {
                        label: "Downloads"
                        iconName: "download"
                        active: root.currentPath === root.downloadsDir
                        onClicked: root.navigateTo(root.downloadsDir)
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        IconButton {
                            iconName: "arrow_back"
                            enabled: root.currentPath !== root.homeDir && root.currentPath !== "/"
                            onClicked: root.navigateUp()
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                text: root.currentPath
                                color: Appearance.colors.colOnSurface
                                font.family: Sizes.fontFamilyMono
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                            }
                        }

                        Button {
                            text: "使用当前文件夹"
                            Material.background: Appearance.colors.colPrimary
                            Material.foreground: Appearance.colors.colOnPrimary
                            onClicked: {
                                root.folderSelected(root.currentPath);
                                root.close();
                            }
                        }
                    }

                    StyledGridView {
                        id: fileGrid

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        cellWidth: 128
                        cellHeight: 146
                        model: folderModel

                        delegate: Item {
                            id: fileItem

                            required property string fileName
                            required property string filePath
                            required property bool fileIsDir

                            width: fileGrid.cellWidth - 10
                            height: fileGrid.cellHeight - 10

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.normal
                                color: itemMouse.containsMouse ? Appearance.colors.colLayer3 : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                height: 86

                                Image {
                                    id: previewImage
                                    anchors.fill: parent
                                    source: !fileItem.fileIsDir ? root.encodeFileUrl(fileItem.filePath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    visible: false
                                }

                                MultiEffect {
                                    anchors.fill: parent
                                    source: previewImage
                                    maskEnabled: true
                                    maskSource: previewMask
                                    visible: !fileItem.fileIsDir && previewImage.status === Image.Ready
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1
                                }

                                Rectangle {
                                    id: previewMask
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: "black"
                                    visible: false
                                    layer.enabled: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer2
                                    visible: fileItem.fileIsDir || previewImage.status !== Image.Ready

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: fileItem.fileIsDir ? "folder" : "image"
                                        iconSize: 34
                                        color: fileItem.fileIsDir ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                        fill: fileItem.fileIsDir ? 1 : 0
                                    }
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.bottomMargin: 10
                                text: fileItem.fileName
                                color: Appearance.colors.colOnSurface
                                font.family: Sizes.fontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (fileItem.fileIsDir)
                                        root.navigateTo(fileItem.filePath);
                                    else {
                                        root.fileSelected(fileItem.filePath);
                                        root.close();
                                    }
                                }
                            }
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
        opacity: enabled ? 1 : 0.35

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
            enabled: iconButton.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconButton.clicked()
        }
    }

    component SidebarButton: Item {
        id: sidebarButton

        property string label: ""
        property string iconName: ""
        property bool active: false
        signal clicked

        Layout.fillWidth: true
        Layout.preferredHeight: 40

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: sidebarButton.active ? Appearance.colors.colSecondaryContainer : (sideMouse.containsMouse ? Appearance.colors.colLayer3 : "transparent")
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            MaterialSymbol {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                text: sidebarButton.iconName
                iconSize: 20
                fill: sidebarButton.active ? 1 : 0
                color: sidebarButton.active ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
            }

            Text {
                Layout.fillWidth: true
                text: sidebarButton.label
                color: sidebarButton.active ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                font.family: Sizes.fontFamily
                font.pixelSize: 13
                font.weight: sidebarButton.active ? Font.Medium : Font.Normal
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: sideMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sidebarButton.clicked()
        }
    }
}
