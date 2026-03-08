import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import CryptoKey

Window {
    width: 420
    height: 680
    visible: true
    title: "CryptoKey"
    color: "#0a0a0f"

    DatabaseManager { id: dbManager }
    property bool isLoggedIn: false
    property bool loginError: false
    property var entriesList: []

    Connections {
        target: dbManager
        function onDataChanged() {
            entriesList = dbManager.getEntriesList()
        }
    }

    Rectangle {
        id: root
        anchors.fill: parent
        radius: 0
        color: "#0a0a0f"
        clip: true

        Rectangle {
            width: 300; height: 300
            x: -60; y: -60
            radius: 150
            color: "transparent"
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "#1a0a3d"
                opacity: 0.6
            }
        }
        Rectangle {
            width: 250; height: 250
            x: parent.width - 160; y: parent.height - 180
            radius: 125
            color: "transparent"
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "#0d2a1a"
                opacity: 0.7
            }
        }

        Canvas {
            anchors.fill: parent
            opacity: 0.04
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 0.5
                var step = 28
                for (var x = 0; x < width; x += step) {
                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                }
                for (var y = 0; y < height; y += step) {
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                }
            }
        }

        Item {
            id: loginScreen
            anchors.fill: parent
            visible: !isLoggedIn
            opacity: isLoggedIn ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.78
                spacing: 0

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 72; height: 72
                    Layout.bottomMargin: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "transparent"
                        border.color: "#00ff88"
                        border.width: 1.5
                        opacity: 0.4
                        rotation: 45
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 44; height: 44
                        radius: 10
                        color: "#00ff88"
                        opacity: 0.12
                        rotation: 45
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "⬡"
                        font.pixelSize: 32
                        color: "#00ff88"
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "CRYPTOKEY"
                    font.pixelSize: 26
                    font.letterSpacing: 8
                    font.weight: Font.Bold
                    color: "#ffffff"
                    Layout.bottomMargin: 4
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Secure Password Vault"
                    font.pixelSize: 12
                    font.letterSpacing: 2
                    color: "#4a4a5a"
                    Layout.bottomMargin: 40
                }

                Item {
                    Layout.fillWidth: true
                    height: 52
                    Layout.bottomMargin: 12

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "#16161f"
                        border.color: masterKeyField.activeFocus ? "#00ff88" : (loginError ? "#ff4466" : "#2a2a3a")
                        border.width: 1.5
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🔑"
                        font.pixelSize: 16
                        opacity: 0.5
                    }

                    TextField {
                        id: masterKeyField
                        anchors.fill: parent
                        anchors.leftMargin: 44
                        anchors.rightMargin: 8
                        placeholderText: "Master password"
                        echoMode: TextInput.Password
                        color: "#e8e8f0"
                        font.pixelSize: 14
                        font.letterSpacing: 1
                        placeholderTextColor: "#55556a"
                        verticalAlignment: TextInput.AlignVCenter
                        Keys.onReturnPressed: loginBtn.clicked()
                        onTextChanged: loginError = false
                        background: Rectangle {
                            color: "transparent"
                            border.width: 0
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Please enter your master password"
                    font.pixelSize: 11
                    color: "#ff4466"
                    opacity: loginError ? 1 : 0
                    Layout.bottomMargin: loginError ? 8 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    id: loginBtn
                    Layout.fillWidth: true
                    height: 52
                    radius: 12
                    color: loginBtnMouse.containsMouse ? "#00ff88" : "#00dd77"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    signal clicked()
                    onClicked: {
                        if (masterKeyField.text !== "") {
                            dbManager.setMasterKey(masterKeyField.text)
                            entriesList = dbManager.getEntriesList()
                            isLoggedIn = true
                            loginError = false
                        } else {
                            loginError = true
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "UNLOCK VAULT"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.letterSpacing: 3
                        color: "#0a0a0f"
                    }

                    MouseArea {
                        id: loginBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: loginBtn.clicked()
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#000000"
                        opacity: loginBtnMouse.pressed ? 0.15 : 0
                        Behavior on opacity { NumberAnimation { duration: 80 } }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "AES-256 · End-to-end encrypted"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    color: "#2a2a3a"
                    Layout.topMargin: 24
                }
            }
        }

        Item {
            id: vaultScreen
            anchors.fill: parent
            visible: isLoggedIn
            opacity: isLoggedIn ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: vaultScreen.width
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 72
                        color: "#ffffff04"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 20

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "CRYPTOKEY"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    font.letterSpacing: 4
                                    color: "#ffffff"
                                }
                                Text {
                                    text: "Password Vault"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                    color: "#4a4a5a"
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 36; height: 36
                                radius: 10
                                color: exitMouse.containsMouse ? "#ffffff10" : "#ffffff06"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏻"
                                    font.pixelSize: 14
                                    color: exitMouse.containsMouse ? "#ff4466" : "#4a4a5a"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: exitMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        isLoggedIn = false
                                        masterKeyField.text = ""
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1
                            color: "#ffffff0a"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 24
                        spacing: 24

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            RowLayout {
                                Text {
                                    text: "NEW ENTRY"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 3
                                    color: "#00ff88"
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff8820" }
                            }

                            ModernField {
                                id: serviceInput
                                Layout.fillWidth: true
                                placeholder: "Resource / Website"
                                icon: "🌐"
                            }

                            ModernField {
                                id: loginInput
                                Layout.fillWidth: true
                                placeholder: "Login / Email"
                                icon: "👤"
                            }

                            ModernField {
                                id: passInput
                                Layout.fillWidth: true
                                placeholder: "Password"
                                icon: "🔒"
                                isPassword: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 48
                                radius: 12
                                color: saveMouse.containsMouse ? "#00ff88" : "#00ff8820"
                                border.color: "#00ff88"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: "+"
                                        font.pixelSize: 18
                                        font.weight: Font.Light
                                        color: saveMouse.containsMouse ? "#0a0a0f" : "#00ff88"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        text: "ENCRYPT & SAVE"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        font.letterSpacing: 2
                                        color: saveMouse.containsMouse ? "#0a0a0f" : "#00ff88"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: saveMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        dbManager.addData(
                                            serviceInput.fieldText,
                                            loginInput.fieldText,
                                            passInput.fieldText
                                        )
                                        serviceInput.clear()
                                        loginInput.clear()
                                        passInput.clear()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#ffffff08"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: entriesList.length > 0

                            RowLayout {
                                Text {
                                    text: "SAVED ENTRIES"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 3
                                    color: "#00ff88"
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff8820" }
                                Text {
                                    text: entriesList.length + " items"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                    color: "#2a3a2a"
                                }
                            }

                            Repeater {
                                model: entriesList
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 62
                                    radius: 12
                                    color: "#16161f"
                                    border.color: "#00ff8825"
                                    border.width: 1

                                    Rectangle {
                                        width: 3
                                        height: parent.height - 16
                                        anchors.left: parent.left
                                        anchors.leftMargin: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 2
                                        color: "#00ff88"
                                        opacity: 0.7
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        Rectangle {
                                            width: 28; height: 28
                                            radius: 8
                                            color: "#00ff8815"
                                            border.color: "#00ff8840"
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.id
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: "#00ff88"
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 3
                                            Layout.fillWidth: true

                                            Text {
                                                text: modelData.service
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: "#e8e8f0"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: modelData.login
                                                font.pixelSize: 11
                                                color: "#55556a"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Rectangle {
                                            width: 28; height: 28
                                            radius: 8
                                            color: delMouse.containsMouse ? "#ff446620" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                font.pixelSize: 11
                                                color: delMouse.containsMouse ? "#ff4466" : "#2a2a3a"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            MouseArea {
                                                id: delMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    dbManager.removeData(modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            RowLayout {
                                Text {
                                    text: "DECRYPT"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 3
                                    color: "#7c88ff"
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#7c88ff20" }
                            }

                            ModernField {
                                id: idField
                                Layout.fillWidth: true
                                placeholder: "Entry ID"
                                icon: "#"
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 56
                                radius: 12
                                color: "#16161f"
                                border.color: resultLabel.text !== "—" ? "#7c88ff40" : "#ffffff08"
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 300 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12

                                    Text {
                                        text: "🔓"
                                        font.pixelSize: 16
                                        opacity: 0.5
                                    }
                                    Text {
                                        id: resultLabel
                                        text: "—"
                                        color: resultLabel.text !== "—" ? "#c8ccff" : "#2a2a3a"
                                        font.pixelSize: 13
                                        font.letterSpacing: 0.5
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }

                                    Text {
                                        text: "copy"
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                        color: "#7c88ff"
                                        opacity: resultLabel.text !== "—" ? 0.7 : 0
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 48
                                radius: 12
                                color: decryptMouse.containsMouse ? "#7c88ff" : "#7c88ff20"
                                border.color: "#7c88ff"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: "🔓"
                                        font.pixelSize: 14
                                    }
                                    Text {
                                        text: "DECRYPT"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        font.letterSpacing: 2
                                        color: decryptMouse.containsMouse ? "#0a0a0f" : "#7c88ff"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: decryptMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var pwd = dbManager.getDecryptedPassword(parseInt(idField.fieldText))
                                        resultLabel.text = pwd !== "" ? pwd : "Not found"
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "AES-256 · Zero-knowledge"
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            color: "#1e1e2e"
                            Layout.bottomMargin: 8
                        }
                    }
                }
            }
        }
    }

    component ModernField: Item {
        height: 48
        property alias placeholder: tf.placeholderText
        property string icon: ""
        property bool isPassword: false
        property alias fieldText: tf.text
        function clear() { tf.text = "" }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#16161f"
            border.color: tf.activeFocus ? (isPassword ? "#7c88ff" : "#00ff88") : "#2a2a3a"
            border.width: 1.5
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: icon
            font.pixelSize: 14
            opacity: 0.5
            color: "#aaaacc"
        }

        TextField {
            id: tf
            anchors.fill: parent
            anchors.leftMargin: icon !== "" ? 40 : 14
            anchors.rightMargin: 8
            echoMode: isPassword ? TextInput.Password : TextInput.Normal
            color: "#e8e8f0"
            font.pixelSize: 13
            placeholderTextColor: "#55556a"
            verticalAlignment: TextInput.AlignVCenter
            background: Rectangle {
                color: "transparent"
                border.width: 0
            }
        }
    }
}
