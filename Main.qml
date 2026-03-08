import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
    property string loginErrorMsg: "Please enter your master password"
    property var entriesList: []
    property bool masterKeySet: false

    Component.onCompleted: {
        masterKeySet = dbManager.isMasterKeySet()
    }

    Connections {
        target: dbManager
        function onDataChanged() {
            entriesList = dbManager.getEntriesList()
        }
    }

    TextEdit {
        id: clipHelper
        visible: false
        function copyText(text) {
            clipHelper.text = text
            clipHelper.selectAll()
            clipHelper.copy()
            clipHelper.text = ""
        }
    }

    function updateStrength(password) {
        var length = password.length
        var score = 0
        if (length >= 8)  score++
        if (length >= 12) score++
        if (/[a-z]/.test(password))        score++
        if (/[A-Z]/.test(password))        score++
        if (/[0-9]/.test(password))        score++
        if (/[^a-zA-Z0-9]/.test(password)) score++

        if (length === 0) {
            strengthBar.width  = 0
            strengthText.text  = "—"
            strengthText.color = "#55556a"
            return
        }
        var pct   = Math.min(100, score * 16.67)
        var col   = score >= 5 ? "#00ff88" : score >= 3 ? "#ffaa00" : "#ff4466"
        var label = score >= 5 ? "Strong"  : score >= 3 ? "Medium"  : "Weak"
        strengthBar.width  = strengthBarBg.width * (pct / 100)
        strengthBar.color  = col
        strengthText.text  = label
        strengthText.color = col
    }

    function generatePassword(length) {
        var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
        var pwd = ""
        for (var i = 0; i < length; i++)
            pwd += chars.charAt(Math.floor(Math.random() * chars.length))
        passInput.fieldText = pwd
        updateStrength(pwd)
    }

    function doLogin() {
        if (masterKeyField.text === "") {
            loginErrorMsg = "Please enter your master password"
            loginError = true
            return
        }
        if (!masterKeySet) {
            // Первый запуск — создаём мастер-пароль
            if (dbManager.setMasterKey(masterKeyField.text)) {
                masterKeySet = true
                entriesList  = dbManager.getEntriesList()
                isLoggedIn   = true
                loginError   = false
            }
        } else {
            var result = dbManager.verifyMasterKey(masterKeyField.text)
            if (result === "ok") {
                entriesList = dbManager.getEntriesList()
                isLoggedIn  = true
                loginError  = false
            } else {
                loginErrorMsg = "Wrong master password"
                loginError    = true
            }
        }
    }

    Rectangle {
        id: root
        anchors.fill: parent
        color: "#0a0a0f"
        clip: true

        Rectangle {
            width: 300; height: 300; x: -60; y: -60; radius: 150; color: "transparent"
            Rectangle { anchors.fill: parent; radius: parent.radius; color: "#1a0a3d"; opacity: 0.6 }
        }
        Rectangle {
            width: 250; height: 250; x: parent.width - 160; y: parent.height - 180; radius: 125; color: "transparent"
            Rectangle { anchors.fill: parent; radius: parent.radius; color: "#0d2a1a"; opacity: 0.7 }
        }
        Canvas {
            anchors.fill: parent; opacity: 0.04
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#ffffff"; ctx.lineWidth = 0.5
                var step = 28
                for (var x = 0; x < width; x += step) { ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,height); ctx.stroke() }
                for (var y = 0; y < height; y += step) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(width,y); ctx.stroke() }
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
                    width: 72; height: 72; Layout.bottomMargin: 28
                    Rectangle { anchors.fill: parent; radius: 18; color: "transparent"; border.color: "#00ff88"; border.width: 1.5; opacity: 0.4; rotation: 45 }
                    Rectangle { anchors.centerIn: parent; width: 44; height: 44; radius: 10; color: "#00ff88"; opacity: 0.12; rotation: 45 }
                    Text { anchors.centerIn: parent; text: "⬡"; font.pixelSize: 32; color: "#00ff88" }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "CRYPTOKEY"
                    font.pixelSize: 26; font.letterSpacing: 8; font.weight: Font.Bold
                    color: "#ffffff"; Layout.bottomMargin: 4
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: masterKeySet ? "Enter your master password" : "Create a master password"
                    font.pixelSize: 12; font.letterSpacing: 2; color: "#4a4a5a"; Layout.bottomMargin: 40
                }

                Item {
                    Layout.fillWidth: true; height: 52; Layout.bottomMargin: 12
                    Rectangle {
                        anchors.fill: parent; radius: 12; color: "#16161f"
                        border.color: masterKeyField.activeFocus ? "#00ff88" : (loginError ? "#ff4466" : "#2a2a3a")
                        border.width: 1.5
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }
                    Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: "🔑"; font.pixelSize: 16; opacity: 0.5 }
                    TextField {
                        id: masterKeyField
                        anchors.fill: parent; anchors.leftMargin: 44; anchors.rightMargin: 8
                        placeholderText: "Master password"
                        echoMode: TextInput.Password
                        color: "#e8e8f0"; font.pixelSize: 14; font.letterSpacing: 1
                        placeholderTextColor: "#55556a"; verticalAlignment: TextInput.AlignVCenter
                        Keys.onReturnPressed: doLogin()
                        onTextChanged: loginError = false
                        background: Rectangle { color: "transparent"; border.width: 0 }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter; text: loginErrorMsg
                    font.pixelSize: 11; color: "#ff4466"
                    opacity: loginError ? 1 : 0; Layout.bottomMargin: loginError ? 8 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    id: loginBtn
                    Layout.fillWidth: true; height: 52; radius: 12
                    color: loginBtnMouse.containsMouse ? "#00ff88" : "#00dd77"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: masterKeySet ? "UNLOCK VAULT" : "CREATE VAULT"
                        font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 3; color: "#0a0a0f"
                    }
                    MouseArea {
                        id: loginBtnMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: doLogin()
                    }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius; color: "#000000"
                        opacity: loginBtnMouse.pressed ? 0.15 : 0
                        Behavior on opacity { NumberAnimation { duration: 80 } }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter; text: "AES-256 · End-to-end encrypted"
                    font.pixelSize: 10; font.letterSpacing: 1; color: "#2a2a3a"; Layout.topMargin: 24
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !masterKeySet
                    height: 36; width: 220; radius: 10; Layout.topMargin: 12
                    color: genKeyMouse.containsMouse ? "#ffffff15" : "transparent"
                    border.color: "#ffffff20"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "🎲"; font.pixelSize: 13 }
                        Text {
                            text: "Generate master key"
                            font.pixelSize: 11; font.letterSpacing: 1; color: "#6a6a8a"
                        }
                    }
                    MouseArea {
                        id: genKeyMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
                            var pwd = ""
                            for (var i = 0; i < 20; i++)
                                pwd += chars.charAt(Math.floor(Math.random() * chars.length))
                            generatedKeyText.text = pwd
                            masterKeyField.text   = pwd
                            saveKeyModal.visible  = true
                        }
                    }
                }
            }
        }

        Rectangle {
            id: saveKeyModal
            anchors.fill: parent
            visible: false
            color: "#000000cc"
            z: 100

            MouseArea { anchors.fill: parent }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.85; radius: 20
                color: "#13131e"
                border.color: "#ffaa00"; border.width: 1.5
                height: modalContent.implicitHeight + 48

                ColumnLayout {
                    id: modalContent
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 16

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "⚠️"; font.pixelSize: 36
                        Layout.topMargin: 8
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "SAVE YOUR MASTER KEY"
                        font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 3
                        color: "#ffaa00"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "This key cannot be recovered if lost.\nWrite it down and store it safely."
                        font.pixelSize: 12; color: "#6a6a8a"
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 56; radius: 12
                        color: "#0a0a0f"; border.color: "#ffaa0040"; border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8

                            Text {
                                id: generatedKeyText
                                text: ""
                                Layout.fillWidth: true
                                font.pixelSize: 13; font.letterSpacing: 1
                                color: "#ffe080"; wrapMode: Text.WrapAnywhere
                                font.family: "Courier New"
                            }

                            Rectangle {
                                width: 32; height: 32; radius: 8
                                color: copyKeyMouse.containsMouse ? "#ffaa0030" : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: "📋"; font.pixelSize: 14 }
                                MouseArea {
                                    id: copyKeyMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: clipHelper.copyText(generatedKeyText.text)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10

                        Rectangle {
                            id: confirmCheck
                            width: 20; height: 20; radius: 5
                            color: confirmed ? "#ffaa00" : "transparent"
                            border.color: confirmed ? "#ffaa00" : "#4a4a5a"; border.width: 1.5
                            property bool confirmed: false
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent; text: "✓"
                                font.pixelSize: 12; font.weight: Font.Bold; color: "#0a0a0f"
                                opacity: confirmCheck.confirmed ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: confirmCheck.confirmed = !confirmCheck.confirmed
                            }
                        }

                        Text {
                            text: "I have saved my master key"
                            font.pixelSize: 12; color: "#6a6a8a"; Layout.fillWidth: true
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: confirmCheck.confirmed = !confirmCheck.confirmed
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 46; radius: 12
                        color: confirmCheck.confirmed
                               ? (continueMouse.containsMouse ? "#ffaa00" : "#ffaa0090")
                               : "#2a2a2a"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "CONTINUE"
                            font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 3
                            color: confirmCheck.confirmed ? "#0a0a0f" : "#3a3a3a"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: continueMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!confirmCheck.confirmed) return
                                saveKeyModal.visible  = false
                                confirmCheck.confirmed = false
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Generate another"
                        font.pixelSize: 11; font.letterSpacing: 1; color: "#3a3a5a"
                        Layout.bottomMargin: 8
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
                                var pwd = ""
                                for (var i = 0; i < 20; i++)
                                    pwd += chars.charAt(Math.floor(Math.random() * chars.length))
                                generatedKeyText.text = pwd
                                masterKeyField.text   = pwd
                                confirmCheck.confirmed = false
                            }
                        }
                    }
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
                anchors.fill: parent; contentWidth: availableWidth
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: vaultScreen.width; spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; height: 72; color: "#ffffff04"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 20
                            ColumnLayout {
                                spacing: 2
                                Text { text: "CRYPTOKEY"; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 4; color: "#ffffff" }
                                Text { text: "Password Vault"; font.pixelSize: 10; font.letterSpacing: 1; color: "#4a4a5a" }
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 36; height: 36; radius: 10
                                color: exitMouse.containsMouse ? "#ffffff10" : "#ffffff06"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent; text: "⏻"; font.pixelSize: 14
                                    color: exitMouse.containsMouse ? "#ff4466" : "#4a4a5a"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    id: exitMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { isLoggedIn = false; masterKeyField.text = "" }
                                }
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#ffffff0a" }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; Layout.margins: 24; spacing: 24

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 12
                            RowLayout {
                                Text { text: "NEW ENTRY"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 3; color: "#00ff88" }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff8820" }
                            }
                            ModernField { id: serviceInput; Layout.fillWidth: true; placeholder: "Resource / Website"; icon: "🌐" }
                            ModernField { id: loginInput;   Layout.fillWidth: true; placeholder: "Login / Email";      icon: "👤" }
                            ModernField {
                                id: passInput
                                Layout.fillWidth: true; placeholder: "Password"; icon: "🔒"; isPassword: true
                                onFieldTextChanged: updateStrength(fieldText)
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 68; radius: 12
                                color: "#16161f"; border.color: "#2a2a3a"; border.width: 1
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 6
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            id: strengthBarBg
                                            Layout.fillWidth: true; height: 6; radius: 3; color: "#0a0a0f"
                                            Rectangle {
                                                id: strengthBar
                                                width: 0; height: parent.height; radius: parent.radius; color: "#ff4466"
                                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                                                Behavior on color { ColorAnimation { duration: 300 } }
                                            }
                                        }
                                        Text {
                                            id: strengthText; text: "—"
                                            font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1
                                            color: "#55556a"; Layout.minimumWidth: 50; horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            height: 28; width: 110; radius: 8
                                            color: generateMouse.containsMouse ? "#7c88ff" : "#7c88ff20"
                                            border.color: "#7c88ff"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text {
                                                anchors.centerIn: parent; text: "🎲 Generate"
                                                font.pixelSize: 11; font.letterSpacing: 1
                                                color: generateMouse.containsMouse ? "#0a0a0f" : "#7c88ff"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            MouseArea {
                                                id: generateMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: generatePassword(16)
                                            }
                                        }
                                        Rectangle {
                                            height: 28; width: 90; radius: 8
                                            visible: passInput.fieldText.length > 0
                                            color: copyPassMouse.containsMouse ? "#00ff88" : "#00ff8820"
                                            border.color: "#00ff88"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text {
                                                anchors.centerIn: parent; text: "📋 Copy"
                                                font.pixelSize: 11; font.letterSpacing: 1
                                                color: copyPassMouse.containsMouse ? "#0a0a0f" : "#00ff88"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            MouseArea {
                                                id: copyPassMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: clipHelper.copyText(passInput.fieldText)
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 48; radius: 12
                                color: saveMouse.containsMouse ? "#00ff88" : "#00ff8820"
                                border.color: "#00ff88"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { text: "+"; font.pixelSize: 18; font.weight: Font.Light; color: saveMouse.containsMouse ? "#0a0a0f" : "#00ff88"; Behavior on color { ColorAnimation { duration: 150 } } }
                                    Text { text: "ENCRYPT & SAVE"; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 2; color: saveMouse.containsMouse ? "#0a0a0f" : "#00ff88"; Behavior on color { ColorAnimation { duration: 150 } } }
                                }
                                MouseArea {
                                    id: saveMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (serviceInput.fieldText === "" || loginInput.fieldText === "" || passInput.fieldText === "") return
                                        dbManager.addData(serviceInput.fieldText, loginInput.fieldText, passInput.fieldText)
                                        serviceInput.clear(); loginInput.clear(); passInput.clear()
                                        updateStrength("")
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff08" }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10
                            visible: entriesList.length > 0
                            RowLayout {
                                Text { text: "SAVED ENTRIES"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 3; color: "#00ff88" }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff8820" }
                                Text { text: entriesList.length + " items"; font.pixelSize: 10; font.letterSpacing: 1; color: "#2a3a2a" }
                            }
                            Repeater {
                                model: entriesList
                                delegate: Rectangle {
                                    Layout.fillWidth: true; height: 62; radius: 12
                                    color: "#16161f"; border.color: "#00ff8825"; border.width: 1
                                    Rectangle {
                                        width: 3; height: parent.height - 16
                                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                        radius: 2; color: "#00ff88"; opacity: 0.7
                                    }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 10
                                        Rectangle {
                                            width: 28; height: 28; radius: 8; color: "#00ff8815"; border.color: "#00ff8840"; border.width: 1
                                            Text { anchors.centerIn: parent; text: modelData.id; font.pixelSize: 11; font.weight: Font.Bold; color: "#00ff88" }
                                        }
                                        ColumnLayout {
                                            spacing: 3; Layout.fillWidth: true
                                            Text { text: modelData.service; font.pixelSize: 13; font.weight: Font.Medium; color: "#e8e8f0"; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: modelData.login;   font.pixelSize: 11; color: "#55556a"; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        Rectangle {
                                            width: 28; height: 28; radius: 8
                                            color: copyEntryMouse.containsMouse ? "#00ff8820" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text { anchors.centerIn: parent; text: "📋"; font.pixelSize: 11; opacity: copyEntryMouse.containsMouse ? 1.0 : 0.35; Behavior on opacity { NumberAnimation { duration: 150 } } }
                                            MouseArea {
                                                id: copyEntryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var pwd = dbManager.getDecryptedPassword(modelData.id)
                                                    if (pwd !== "") clipHelper.copyText(pwd)
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: 28; height: 28; radius: 8
                                            color: delMouse.containsMouse ? "#ff446620" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: delMouse.containsMouse ? "#ff4466" : "#2a2a3a"; Behavior on color { ColorAnimation { duration: 150 } } }
                                            MouseArea {
                                                id: delMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: dbManager.removeData(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff08" }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 12
                            RowLayout {
                                Text { text: "DECRYPT"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 3; color: "#7c88ff" }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#7c88ff20" }
                            }
                            ModernField { id: idField; Layout.fillWidth: true; placeholder: "Entry ID"; icon: "#" }
                            Rectangle {
                                Layout.fillWidth: true; height: 56; radius: 12; color: "#16161f"
                                border.color: resultLabel.text !== "—" ? "#7c88ff40" : "#2a2a3a"; border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 300 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 12
                                    Text { text: "🔓"; font.pixelSize: 16; opacity: 0.5 }
                                    Text {
                                        id: resultLabel; text: "—"
                                        color: resultLabel.text !== "—" ? "#c8ccff" : "#2a2a3a"
                                        font.pixelSize: 13; font.letterSpacing: 0.5; Layout.fillWidth: true; elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                    Text {
                                        text: "copy"; font.pixelSize: 10; font.letterSpacing: 1; color: "#7c88ff"
                                        opacity: resultLabel.text !== "—" ? 0.7 : 0
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: if (resultLabel.text !== "—") clipHelper.copyText(resultLabel.text)
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 48; radius: 12
                                color: decryptMouse.containsMouse ? "#7c88ff" : "#7c88ff20"
                                border.color: "#7c88ff"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { text: "🔓"; font.pixelSize: 14 }
                                    Text { text: "DECRYPT"; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 2; color: decryptMouse.containsMouse ? "#0a0a0f" : "#7c88ff"; Behavior on color { ColorAnimation { duration: 150 } } }
                                }
                                MouseArea {
                                    id: decryptMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var pwd = dbManager.getDecryptedPassword(parseInt(idField.fieldText))
                                        resultLabel.text = pwd !== "" ? pwd : "Not found"
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter; text: "AES-256 · Zero-knowledge"
                            font.pixelSize: 10; font.letterSpacing: 1; color: "#1e1e2e"; Layout.bottomMargin: 8
                        }
                    }
                }
            }
        }
    }

    component ModernField: Item {
        height: 48
        property alias placeholder:  tf.placeholderText
        property string icon:        ""
        property bool   isPassword:  false
        property alias  fieldText:   tf.text
        function clear() { tf.text = "" }

        Rectangle {
            anchors.fill: parent; radius: 10; color: "#16161f"
            border.color: tf.activeFocus ? (isPassword ? "#7c88ff" : "#00ff88") : "#2a2a3a"
            border.width: 1.5
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
        Text {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: icon; font.pixelSize: 14; opacity: 0.5; color: "#aaaacc"
        }
        TextField {
            id: tf
            anchors.fill: parent; anchors.leftMargin: icon !== "" ? 40 : 14; anchors.rightMargin: 8
            echoMode: isPassword ? TextInput.Password : TextInput.Normal
            color: "#e8e8f0"; font.pixelSize: 13; placeholderTextColor: "#55556a"
            verticalAlignment: TextInput.AlignVCenter
            background: Rectangle { color: "transparent"; border.width: 0 }
        }
    }
}
