import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CryptoKey
import App.TOTP 1.0

Window {
    id: window
    width: 960
    height: 620
    minimumWidth: 760
    minimumHeight: 500
    visible: true
    title: "CryptoKey"
    color: "#111118"

    DatabaseManager { id: dbManager }

    property bool   isLoggedIn:          false
    property bool   loginError:          false
    property string loginErrorMsg:       "Please enter your master password"
    property var    entriesList:         []
    property bool   masterKeySet:        false
    property int    selectedIndex:       -1
    property var    selectedEntry:       null
    property bool   detailPassVisible:   false
    property string detailPassReal:      ""

    onSelectedEntryChanged: {
        detailPassVisible = false
        detailPassReal    = ""
        if (selectedEntry && selectedEntry.hasTotp) {
            var secret = dbManager.getTotpSecret(selectedEntry.id)
            if (secret !== "") TotpHelper.generateCode(secret)
        }
    }

    Component.onCompleted: {
        masterKeySet = dbManager.isMasterKeySet()
    }

    Connections {
        target: dbManager
        function onDataChanged() {
            var prev = selectedEntry
            entriesList = dbManager.getEntriesList()
            selectedIndex = -1
            selectedEntry = null
            if (prev !== null) {
                for (var i = 0; i < entriesList.length; i++) {
                    if (entriesList[i].id === prev.id) {
                        selectedIndex = i
                        selectedEntry = entriesList[i]
                        break
                    }
                }
            }
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
            copyToast.show()
        }
    }

    Item {
        id: copyToast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        width: toastRow.implicitWidth + 28
        height: 40
        z: 999
        opacity: 0
        visible: opacity > 0
        function show() { toastAnim.restart() }

        SequentialAnimation {
            id: toastAnim
            NumberAnimation { target: copyToast; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutQuad }
            PauseAnimation  { duration: 1600 }
            NumberAnimation { target: copyToast; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InQuad }
        }
        Rectangle {
            anchors.fill: parent; radius: 10
            color: "#1e1e2e"; border.color: "#4ade8060"; border.width: 1
        }
        RowLayout {
            id: toastRow; anchors.centerIn: parent; spacing: 8
            Rectangle {
                width: 20; height: 20; radius: 10; color: "#4ade80"
                Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 11; font.weight: Font.Bold; color: "#0a0a0f" }
            }
            Text { text: "Copied to clipboard"; font.pixelSize: 12; color: "#e2e8f0" }
        }
    }

    function strengthInfo(password) {
        if (password.length === 0) return { score: 0, label: "", color: "#334155" }
        var score = 0
        if (password.length >= 8)  score++
        if (password.length >= 12) score++
        if (/[a-z]/.test(password)) score++
        if (/[A-Z]/.test(password)) score++
        if (/[0-9]/.test(password)) score++
        if (/[^a-zA-Z0-9]/.test(password)) score++
        if (score >= 5) return { score: score, label: "Fantastic", color: "#4ade80" }
        if (score >= 4) return { score: score, label: "Good",      color: "#a3e635" }
        if (score >= 3) return { score: score, label: "Fair",      color: "#fb923c" }
        return             { score: score, label: "Weak",      color: "#f87171" }
    }

    function generatePassword(length) {
        var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
        var pwd = ""
        for (var i = 0; i < length; i++)
            pwd += chars.charAt(Math.floor(Math.random() * chars.length))
        return pwd
    }

    function doLogin() {
        if (masterKeyField.text === "") {
            loginErrorMsg = "Please enter your master password"
            loginError = true
            return
        }
        if (!masterKeySet) {
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
        id: loginScreen
        anchors.fill: parent
        color: "#0f0f17"
        visible: !isLoggedIn
        opacity: isLoggedIn ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 350 } }

        Rectangle {
            width: 400; height: 400; x: -120; y: -120; radius: 200; color: "#1e1b4b"; opacity: 0.5
        }
        Rectangle {
            width: 300; height: 300; x: parent.width - 180; y: parent.height - 180; radius: 150; color: "#052e16"; opacity: 0.6
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 80

            ColumnLayout {
                spacing: 16

                Rectangle {
                    width: 64; height: 64; radius: 16; color: "#1e3a5f"
                    border.color: "#3b82f6"; border.width: 1.5
                    Layout.alignment: Qt.AlignHCenter

                    Text { anchors.centerIn: parent; text: "🔐"; font.pixelSize: 28 }
                }

                Text {
                    text: "CryptoKey"
                    font.pixelSize: 32; font.weight: Font.Bold
                    color: "#f1f5f9"; Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Your personal password vault"
                    font.pixelSize: 13; color: "#475569"
                    Layout.alignment: Qt.AlignHCenter
                }

                ColumnLayout {
                    spacing: 10; Layout.topMargin: 16

                    Repeater {
                        model: ["AES-256 encryption", "Zero-knowledge architecture", "Local storage — no cloud"]
                        delegate: RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 20; height: 20; radius: 10; color: "#14532d"
                                border.color: "#4ade80"; border.width: 1
                                Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; font.weight: Font.Bold; color: "#4ade80" }
                            }
                            Text { text: modelData; font.pixelSize: 12; color: "#64748b" }
                        }
                    }
                }
            }

            Rectangle {
                width: 340; height: loginCardContent.implicitHeight + 56
                radius: 20; color: "#16161f"
                border.color: "#1e293b"; border.width: 1

                ColumnLayout {
                    id: loginCardContent
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 16

                    Text {
                        text: masterKeySet ? "Welcome back" : "Create your vault"
                        font.pixelSize: 20; font.weight: Font.Bold; color: "#f1f5f9"
                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4
                    }
                    Text {
                        text: masterKeySet ? "Enter your master password to unlock" : "Set a strong master password to get started"
                        font.pixelSize: 11; color: "#475569"
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 48; radius: 10
                        color: "#0f0f17"
                        border.color: masterKeyField.activeFocus ? "#3b82f6" : (loginError ? "#ef4444" : "#1e293b")
                        border.width: 1.5
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8
                            Text { text: "🔑"; font.pixelSize: 15; opacity: 0.5 }
                            TextField {
                                id: masterKeyField
                                Layout.fillWidth: true
                                placeholderText: "Master password"
                                echoMode: showMasterPass.checked ? TextInput.Normal : TextInput.Password
                                color: "#e2e8f0"; font.pixelSize: 13
                                placeholderTextColor: "#334155"
                                verticalAlignment: TextInput.AlignVCenter
                                Keys.onReturnPressed: doLogin()
                                onTextChanged: loginError = false
                                background: Rectangle { color: "transparent"; border.width: 0 }
                            }
                            Text {
                                text: showMasterPass.checked ? "🙈" : "👁"
                                font.pixelSize: 14; opacity: 0.4
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: showMasterPass.checked = !showMasterPass.checked
                                }
                                CheckBox { id: showMasterPass; visible: false }
                            }
                        }
                    }

                    Text {
                        text: loginErrorMsg; font.pixelSize: 11; color: "#ef4444"
                        opacity: loginError ? 1 : 0; Layout.alignment: Qt.AlignHCenter
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 46; radius: 10
                        color: loginHover.containsMouse ? "#2563eb" : "#3b82f6"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: masterKeySet ? "Unlock Vault" : "Create Vault"
                            font.pixelSize: 13; font.weight: Font.Bold; color: "#ffffff"
                        }
                        MouseArea {
                            id: loginHover; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: doLogin()
                        }
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; color: "#000"
                            opacity: loginHover.pressed ? 0.12 : 0
                            Behavior on opacity { NumberAnimation { duration: 80 } }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 40; radius: 10
                        visible: !masterKeySet
                        color: genHover.containsMouse ? "#1e293b" : "transparent"
                        border.color: "#1e293b"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text { text: "🎲"; font.pixelSize: 14 }
                            Text { text: "Generate strong master key"; font.pixelSize: 12; color: "#64748b" }
                        }
                        MouseArea {
                            id: genHover; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var pwd = generatePassword(20)
                                generatedKeyText.text = pwd
                                masterKeyField.text   = pwd
                                saveKeyModal.visible  = true
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "AES-256 · Zero-knowledge · Local only"
                        font.pixelSize: 10; color: "#1e293b"; Layout.bottomMargin: 4
                    }
                }
            }
        }

        Rectangle {
            id: saveKeyModal
            anchors.fill: parent; visible: false; color: "#000000bb"; z: 100
            MouseArea { anchors.fill: parent }

            Rectangle {
                anchors.centerIn: parent
                width: 380; radius: 20; color: "#16161f"
                border.color: "#fb923c"; border.width: 1.5
                height: saveModalCol.implicitHeight + 48

                ColumnLayout {
                    id: saveModalCol
                    anchors.centerIn: parent; width: parent.width - 48; spacing: 16

                    Text { Layout.alignment: Qt.AlignHCenter; text: "⚠️"; font.pixelSize: 32; Layout.topMargin: 8 }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Save Your Master Key"
                        font.pixelSize: 18; font.weight: Font.Bold; color: "#fb923c"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "This key is never stored anywhere.\nIf you lose it, your data cannot be recovered."
                        font.pixelSize: 12; color: "#64748b"
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 60; radius: 12
                        color: "#0f0f17"; border.color: "#fb923c40"; border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 10

                            Text {
                                id: generatedKeyText
                                Layout.fillWidth: true
                                font.pixelSize: 13; font.family: "Courier New"
                                color: "#fde68a"; wrapMode: Text.WrapAnywhere
                                font.weight: Font.Medium
                            }

                            Rectangle {
                                id: modalCopyBtn
                                width: 34; height: 34; radius: 8
                                property bool copied: false
                                color: modalCopyHover.containsMouse ? "#fb923c20" : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modalCopyBtn.copied ? "✓" : "📋"
                                    font.pixelSize: 15
                                    color: modalCopyBtn.copied ? "#fb923c" : "#ffffff"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Timer {
                                    id: modalCopyTimer; interval: 1500
                                    onTriggered: modalCopyBtn.copied = false
                                }
                                MouseArea {
                                    id: modalCopyHover; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        clipHelper.copyText(generatedKeyText.text)
                                        modalCopyBtn.copied = true
                                        modalCopyTimer.restart()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Rectangle {
                            id: modalConfirm
                            width: 20; height: 20; radius: 5
                            property bool checked: false
                            color: checked ? "#fb923c" : "transparent"
                            border.color: checked ? "#fb923c" : "#334155"; border.width: 1.5
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent; text: "✓"
                                font.pixelSize: 11; font.weight: Font.Bold; color: "#0f0f17"
                                opacity: modalConfirm.checked ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: modalConfirm.checked = !modalConfirm.checked
                            }
                        }
                        Text {
                            text: "I have saved my master key in a safe place"
                            font.pixelSize: 12; color: "#64748b"; Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: modalConfirm.checked = !modalConfirm.checked
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 10
                        color: modalConfirm.checked
                               ? (continueHover.containsMouse ? "#ea580c" : "#fb923c")
                               : "#1e293b"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent; text: "Continue"
                            font.pixelSize: 13; font.weight: Font.Bold
                            color: modalConfirm.checked ? "#ffffff" : "#334155"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: continueHover; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!modalConfirm.checked) return
                                saveKeyModal.visible  = false
                                modalConfirm.checked  = false
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Generate another key"
                        font.pixelSize: 11; color: "#334155"; Layout.bottomMargin: 4
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var pwd = generatePassword(20)
                                generatedKeyText.text = pwd
                                masterKeyField.text   = pwd
                                modalConfirm.checked  = false
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#111118"
        visible: isLoggedIn
        opacity: isLoggedIn ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 350 } }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: 220
                Layout.fillHeight: true
                color: "#0d0d14"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; height: 60; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 10
                            Rectangle {
                                width: 30; height: 30; radius: 8; color: "#1e3a5f"
                                Text { anchors.centerIn: parent; text: "🔐"; font.pixelSize: 14 }
                            }
                            Text {
                                text: "CryptoKey"
                                font.pixelSize: 14; font.weight: Font.Bold; color: "#f1f5f9"
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 28; height: 28; radius: 7
                                color: lockHover.containsMouse ? "#1e293b" : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent; text: "⏻"; font.pixelSize: 13
                                    color: lockHover.containsMouse ? "#ef4444" : "#334155"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    id: lockHover; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        isLoggedIn    = false
                                        selectedIndex = -1
                                        selectedEntry = null
                                        masterKeyField.text = ""
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; color: "transparent"
                        Layout.margins: 10; Layout.topMargin: 8

                        Rectangle {
                            anchors.fill: parent; radius: 8; color: "#16161f"
                            border.color: searchField.activeFocus ? "#3b82f6" : "#1e293b"; border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 10; spacing: 6
                                Text { text: "🔍"; font.pixelSize: 13; opacity: 0.4 }
                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    placeholderText: "Search"
                                    color: "#e2e8f0"; font.pixelSize: 12
                                    placeholderTextColor: "#334155"
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: Rectangle { color: "transparent"; border.width: 0 }
                                }
                            }
                        }
                    }

                    Text {
                        text: "ALL ITEMS"
                        font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 2
                        color: "#334155"; Layout.leftMargin: 16; Layout.topMargin: 12; Layout.bottomMargin: 4
                    }

                    ListView {
                        id: entriesListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 8; Layout.rightMargin: 8
                        clip: true
                        spacing: 2

                        model: {
                            var q = searchField.text.toLowerCase()
                            if (q === "") return entriesList
                            return entriesList.filter(function(e) {
                                return e.service.toLowerCase().indexOf(q) !== -1 ||
                                       e.login.toLowerCase().indexOf(q) !== -1
                            })
                        }

                        delegate: Rectangle {
                            width: entriesListView.width
                            height: 56; radius: 10
                            color: selectedIndex === index
                                   ? "#1e3a5f"
                                   : (itemHover.containsMouse ? "#16161f" : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 10; spacing: 10

                                Rectangle {
                                    width: 36; height: 36; radius: 10
                                    color: Qt.hsla((modelData.id * 47) % 360 / 360, 0.5, 0.25, 1)
                                    border.color: Qt.hsla((modelData.id * 47) % 360 / 360, 0.6, 0.45, 1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.service.charAt(0).toUpperCase()
                                        font.pixelSize: 15; font.weight: Font.Bold
                                        color: Qt.hsla((modelData.id * 47) % 360 / 360, 0.8, 0.75, 1)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text {
                                        text: modelData.service
                                        font.pixelSize: 13; font.weight: Font.Medium
                                        color: selectedIndex === index ? "#f1f5f9" : "#cbd5e1"
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.login
                                        font.pixelSize: 11; color: "#475569"
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: itemHover; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    selectedIndex = index
                                    selectedEntry = modelData
                                    detailPassVisible = false
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: searchField.text !== "" ? "No results" : "No passwords saved yet"
                            font.pixelSize: 12; color: "#1e293b"
                            visible: entriesListView.count === 0
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                    Rectangle {
                        Layout.fillWidth: true; height: 48; color: "transparent"
                        Layout.margins: 10

                        Rectangle {
                            anchors.fill: parent; radius: 10
                            color: addHover.containsMouse ? "#1e3a5f" : "#16161f"
                            border.color: addHover.containsMouse ? "#3b82f6" : "#1e293b"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "+"; font.pixelSize: 18; font.weight: Font.Light; color: "#3b82f6" }
                                Text { text: "New Item"; font.pixelSize: 13; font.weight: Font.Medium; color: "#3b82f6" }
                            }

                            MouseArea {
                                id: addHover; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    selectedIndex = -2
                                    selectedEntry = null
                                    newServiceField.text = ""
                                    newLoginField.text   = ""
                                    newPassField.text    = ""
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: 1; Layout.fillHeight: true; color: "#1e293b" }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111118"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: selectedIndex === -1

                    Text { Layout.alignment: Qt.AlignHCenter; text: "🔐"; font.pixelSize: 48; opacity: 0.15 }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: entriesList.length === 0 ? "Your vault is empty" : "Select an item"
                        font.pixelSize: 18; font.weight: Font.Medium; color: "#1e293b"
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: entriesList.length === 0
                              ? "Click \"New Item\" to add your first password"
                              : "Choose a password from the sidebar to view details"
                        font.pixelSize: 12; color: "#1e293b"
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                        Layout.maximumWidth: 280
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    visible: selectedIndex === -2
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true; height: 64; color: "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 28; spacing: 14
                                Rectangle {
                                    width: 42; height: 42; radius: 12; color: "#1e3a5f"
                                    Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 22; color: "#3b82f6"; font.weight: Font.Light }
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text { text: "New Password"; font.pixelSize: 18; font.weight: Font.Bold; color: "#f1f5f9" }
                                    Text { text: "Add a new entry to your vault"; font.pixelSize: 11; color: "#475569" }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.margins: 28; spacing: 20

                            ColumnLayout { spacing: 6; Layout.fillWidth: true
                                Text { text: "Website / Service"; font.pixelSize: 11; font.weight: Font.Medium; color: "#475569"; font.letterSpacing: 0.5 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 44; radius: 10; color: "#16161f"
                                    border.color: newServiceField.activeFocus ? "#3b82f6" : "#1e293b"; border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                                        Text { text: "🌐"; font.pixelSize: 14; opacity: 0.5 }
                                        TextField {
                                            id: newServiceField; Layout.fillWidth: true
                                            placeholderText: "e.g. Google, GitHub..."
                                            color: "#e2e8f0"; font.pixelSize: 13
                                            placeholderTextColor: "#334155"; verticalAlignment: TextInput.AlignVCenter
                                            background: Rectangle { color: "transparent"; border.width: 0 }
                                        }
                                    }
                                }
                            }

                            ColumnLayout { spacing: 6; Layout.fillWidth: true
                                Text { text: "Username / Email"; font.pixelSize: 11; font.weight: Font.Medium; color: "#475569"; font.letterSpacing: 0.5 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 44; radius: 10; color: "#16161f"
                                    border.color: newLoginField.activeFocus ? "#3b82f6" : "#1e293b"; border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                                        Text { text: "👤"; font.pixelSize: 14; opacity: 0.5 }
                                        TextField {
                                            id: newLoginField; Layout.fillWidth: true
                                            placeholderText: "email@example.com"
                                            color: "#e2e8f0"; font.pixelSize: 13
                                            placeholderTextColor: "#334155"; verticalAlignment: TextInput.AlignVCenter
                                            background: Rectangle { color: "transparent"; border.width: 0 }
                                        }
                                    }
                                }
                            }

                            ColumnLayout { spacing: 6; Layout.fillWidth: true
                                Text { text: "Password"; font.pixelSize: 11; font.weight: Font.Medium; color: "#475569"; font.letterSpacing: 0.5 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 44; radius: 10; color: "#16161f"
                                    border.color: newPassField.activeFocus ? "#3b82f6" : "#1e293b"; border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                                        Text { text: "🔒"; font.pixelSize: 14; opacity: 0.5 }
                                        TextField {
                                            id: newPassField; Layout.fillWidth: true
                                            placeholderText: "Enter or generate a password"
                                            echoMode: showNewPass.checked ? TextInput.Normal : TextInput.Password
                                            color: "#e2e8f0"; font.pixelSize: 13
                                            placeholderTextColor: "#334155"; verticalAlignment: TextInput.AlignVCenter
                                            background: Rectangle { color: "transparent"; border.width: 0 }
                                        }
                                        Text {
                                            text: showNewPass.checked ? "🙈" : "👁"; font.pixelSize: 14; opacity: 0.4
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: showNewPass.checked = !showNewPass.checked }
                                            CheckBox { id: showNewPass; visible: false }
                                        }
                                    }
                                }


                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    visible: newPassField.text.length > 0

                                    Rectangle {
                                        Layout.fillWidth: true; height: 4; radius: 2; color: "#1e293b"
                                        Rectangle {
                                            width: {
                                                var s = strengthInfo(newPassField.text)
                                                return parent.width * Math.min(1, s.score / 6)
                                            }
                                            height: parent.height; radius: parent.radius
                                            color: strengthInfo(newPassField.text).color
                                            Behavior on width { NumberAnimation { duration: 300 } }
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                    }
                                    Text {
                                        text: strengthInfo(newPassField.text).label
                                        font.pixelSize: 11; font.weight: Font.Medium
                                        color: strengthInfo(newPassField.text).color
                                        Layout.minimumWidth: 60
                                    }
                                }

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        height: 32; width: 140; radius: 8
                                        color: genPassHover.containsMouse ? "#312e81" : "#1e1b4b"
                                        border.color: "#4f46e5"; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        RowLayout { anchors.centerIn: parent; spacing: 6
                                            Text { text: "🎲"; font.pixelSize: 12 }
                                            Text { text: "Generate"; font.pixelSize: 12; color: "#818cf8" }
                                        }
                                        MouseArea {
                                            id: genPassHover; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: newPassField.text = generatePassword(16)
                                        }
                                    }

                                    Rectangle {
                                        id: newCopyPassBtn
                                        height: 32; width: 100; radius: 8
                                        property bool copied: false
                                        visible: newPassField.text.length > 0
                                        color: newCopyPassHover.containsMouse ? "#14532d" : "#052e16"
                                        border.color: "#16a34a"; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        RowLayout { anchors.centerIn: parent; spacing: 6
                                            Text { text: newCopyPassBtn.copied ? "✓" : "📋"; font.pixelSize: 12; color: newCopyPassBtn.copied ? "#4ade80" : "#ffffff" }
                                            Text { text: newCopyPassBtn.copied ? "Copied" : "Copy"; font.pixelSize: 12; color: newCopyPassBtn.copied ? "#4ade80" : "#4ade80" }
                                        }
                                        Timer { id: newCopyPassTimer; interval: 1500; onTriggered: newCopyPassBtn.copied = false }
                                        MouseArea {
                                            id: newCopyPassHover; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { clipHelper.copyText(newPassField.text); newCopyPassBtn.copied = true; newCopyPassTimer.restart() }
                                        }
                                    }
                                }
                            }

                            ColumnLayout { spacing: 6; Layout.fillWidth: true
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Two-Factor Secret (TOTP)"; font.pixelSize: 11; font.weight: Font.Medium; color: "#475569"; font.letterSpacing: 0.5 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Optional"
                                        font.pixelSize: 10; color: "#1e293b"
                                        font.letterSpacing: 0.5
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 44; radius: 10; color: "#16161f"
                                    border.color: newTotpField.activeFocus ? "#a855f7" : "#1e293b"; border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                                        Text { text: "🔐"; font.pixelSize: 14; opacity: 0.5 }
                                        TextField {
                                            id: newTotpField; Layout.fillWidth: true
                                            placeholderText: "BASE32 key from authenticator app"
                                            color: "#e2e8f0"; font.pixelSize: 12
                                            font.family: "Courier New"
                                            placeholderTextColor: "#334155"
                                            verticalAlignment: TextInput.AlignVCenter
                                            onTextChanged: {
                                                var clean = text.toUpperCase().replace(/\s/g, "")
                                                if (clean !== text) { text = clean }
                                            }
                                            background: Rectangle { color: "transparent"; border.width: 0 }
                                        }
                                    }
                                }
                                Text {
                                    text: "Find this key in your service's 2FA settings — look for \"Enter manually\" or \"Can't scan QR code\""
                                    font.pixelSize: 10; color: "#334155"
                                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 46; radius: 10
                                color: saveNewHover.containsMouse ? "#2563eb" : "#3b82f6"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: "Save to Vault"; font.pixelSize: 13; font.weight: Font.Bold; color: "#ffffff" }
                                MouseArea {
                                    id: saveNewHover; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (newServiceField.text === "" || newLoginField.text === "" || newPassField.text === "") return
                                        dbManager.addData(newServiceField.text, newLoginField.text, newPassField.text, newTotpField.text)
                                        newServiceField.text = ""
                                        newLoginField.text   = ""
                                        newPassField.text    = ""
                                        newTotpField.text    = ""
                                        selectedIndex = -1
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius; color: "#000"
                                    opacity: saveNewHover.pressed ? 0.12 : 0
                                    Behavior on opacity { NumberAnimation { duration: 80 } }
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    visible: selectedIndex >= 0 && selectedEntry !== null
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true; height: 80; color: "transparent"

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 28; spacing: 16

                                Rectangle {
                                    width: 52; height: 52; radius: 14
                                    color: selectedEntry
                                           ? Qt.hsla((selectedEntry.id * 47) % 360 / 360, 0.35, 0.18, 1)
                                           : "#1e293b"
                                    border.color: selectedEntry
                                                  ? Qt.hsla((selectedEntry.id * 47) % 360 / 360, 0.5, 0.4, 1)
                                                  : "#334155"
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: selectedEntry ? selectedEntry.service.charAt(0).toUpperCase() : ""
                                        font.pixelSize: 22; font.weight: Font.Bold
                                        color: selectedEntry
                                               ? Qt.hsla((selectedEntry.id * 47) % 360 / 360, 0.8, 0.75, 1)
                                               : "#334155"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Text {
                                        text: selectedEntry ? selectedEntry.service : ""
                                        font.pixelSize: 22; font.weight: Font.Bold; color: "#f1f5f9"
                                    }
                                    Text {
                                        text: selectedEntry ? selectedEntry.login : ""
                                        font.pixelSize: 13; color: "#475569"
                                    }
                                }

                                Rectangle {
                                    width: 36; height: 36; radius: 9
                                    color: deleteHover.containsMouse ? "#7f1d1d" : "#16161f"
                                    border.color: deleteHover.containsMouse ? "#ef4444" : "#1e293b"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent; text: "🗑"
                                        font.pixelSize: 14
                                        opacity: deleteHover.containsMouse ? 1.0 : 0.4
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                    MouseArea {
                                        id: deleteHover; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (selectedEntry) {
                                                dbManager.removeData(selectedEntry.id)
                                                selectedIndex = -1
                                                selectedEntry = null
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.margins: 28; spacing: 6

                            RowLayout {
                                Layout.fillWidth: true; Layout.topMargin: 4
                                Text { text: "ENTRY"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 2; color: "#334155" }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    height: 22; width: idBadgeText.implicitWidth + 16; radius: 6
                                    color: "#1e293b"
                                    Text {
                                        id: idBadgeText
                                        anchors.centerIn: parent
                                        text: selectedEntry ? "ID: " + selectedEntry.id : ""
                                        font.pixelSize: 10; color: "#475569"
                                    }
                                }
                            }

                            Text { text: "USERNAME"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 2; color: "#334155"; Layout.topMargin: 16 }
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: 12; color: "#16161f"
                                border.color: "#1e293b"; border.width: 1

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                                    Text { text: "👤"; font.pixelSize: 16; opacity: 0.5 }
                                    Text {
                                        text: selectedEntry ? selectedEntry.login : ""
                                        font.pixelSize: 14; color: "#e2e8f0"; Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        id: copyLoginBtn
                                        width: 32; height: 32; radius: 8; property bool copied: false
                                        color: copyLoginHover.containsMouse ? "#1e293b" : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: copyLoginBtn.copied ? "✓" : "📋"
                                            font.pixelSize: 13
                                            color: copyLoginBtn.copied ? "#4ade80" : "#475569"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        Timer { id: copyLoginTimer; interval: 1500; onTriggered: copyLoginBtn.copied = false }
                                        MouseArea {
                                            id: copyLoginHover; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (selectedEntry) {
                                                    clipHelper.copyText(selectedEntry.login)
                                                    copyLoginBtn.copied = true
                                                    copyLoginTimer.restart()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text { text: "PASSWORD"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 2; color: "#334155"; Layout.topMargin: 10 }
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: 12; color: "#16161f"
                                border.color: "#1e293b"; border.width: 1

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                                    Text { text: "🔑"; font.pixelSize: 16; opacity: 0.5 }

                                    Text {
                                        id: detailPassText
                                        Layout.fillWidth: true
                                        text: {
                                            if (detailPassVisible) return detailPassReal !== "" ? detailPassReal : "Click 👁 to reveal"
                                            return detailPassReal !== "" ? "••••••••••••" : "Click 👁 to reveal"
                                        }
                                        font.pixelSize: detailPassVisible ? 13 : 18
                                        font.letterSpacing: detailPassVisible ? 0.5 : 3
                                        color: detailPassReal !== "" ? "#e2e8f0" : "#334155"
                                        elide: Text.ElideRight
                                        Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                                    }

                                    Text {
                                        text: detailPassVisible ? "🙈" : "👁"
                                        font.pixelSize: 15; opacity: showPassHover.containsMouse ? 0.8 : 0.4
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        MouseArea {
                                            id: showPassHover; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (selectedEntry) {
                                                    if (detailPassReal === "")
                                                        detailPassReal = dbManager.getDecryptedPassword(selectedEntry.id)
                                                    detailPassVisible = !detailPassVisible
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: copyPassDetailBtn
                                        width: 32; height: 32; radius: 8; property bool copied: false
                                        color: copyPassDetailHover.containsMouse ? "#1e293b" : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: copyPassDetailBtn.copied ? "✓" : "📋"
                                            font.pixelSize: 13
                                            color: copyPassDetailBtn.copied ? "#4ade80" : "#475569"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        Timer { id: copyPassDetailTimer; interval: 1500; onTriggered: copyPassDetailBtn.copied = false }
                                        MouseArea {
                                            id: copyPassDetailHover; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (selectedEntry) {
                                                    var pwd = dbManager.getDecryptedPassword(selectedEntry.id)
                                                    if (pwd !== "") {
                                                        clipHelper.copyText(pwd)
                                                        copyPassDetailBtn.copied = true
                                                        copyPassDetailTimer.restart()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true; spacing: 8; Layout.topMargin: 4
                                visible: detailPassReal !== ""

                                Text { text: "Strength:"; font.pixelSize: 11; color: "#334155" }
                                Rectangle {
                                    width: 80; height: 4; radius: 2; color: "#1e293b"
                                    Rectangle {
                                        width: {
                                            var s = strengthInfo(detailPassReal)
                                            return parent.width * Math.min(1, s.score / 6)
                                        }
                                        height: parent.height; radius: parent.radius
                                        color: strengthInfo(detailPassReal).color
                                    }
                                }
                                Text {
                                    text: strengthInfo(detailPassReal).label
                                    font.pixelSize: 11; font.weight: Font.Medium
                                    color: strengthInfo(detailPassReal).color
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.topMargin: 10
                                height: totpDetailCol.implicitHeight + 24
                                radius: 12; color: "#0f0c1a"
                                border.color: selectedEntry && selectedEntry.hasTotp ? "#7c3aed" : "#1e293b"
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 300 } }

                                property bool showAddTotp: false

                                ColumnLayout {
                                    id: totpDetailCol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                                    spacing: 10

                                    RowLayout {
                                        Layout.fillWidth: true
                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                width: 24; height: 24; radius: 6
                                                color: selectedEntry && selectedEntry.hasTotp ? "#4c1d95" : "#1e293b"
                                                Behavior on color { ColorAnimation { duration: 300 } }
                                                Text { anchors.centerIn: parent; text: "🔐"; font.pixelSize: 12 }
                                            }
                                            Text {
                                                text: "Two-Factor Auth (TOTP)"
                                                font.pixelSize: 12; font.weight: Font.Medium
                                                color: selectedEntry && selectedEntry.hasTotp ? "#c4b5fd" : "#475569"
                                                Behavior on color { ColorAnimation { duration: 300 } }
                                            }
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            height: 24; width: editTotpLabel.implicitWidth + 16; radius: 6
                                            color: editTotpHover.containsMouse ? "#4c1d95" : "transparent"
                                            border.color: "#4c1d95"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text {
                                                id: editTotpLabel
                                                anchors.centerIn: parent
                                                text: selectedEntry && selectedEntry.hasTotp ? "Change" : "+ Add"
                                                font.pixelSize: 10; color: "#a78bfa"
                                            }
                                            MouseArea {
                                                id: editTotpHover; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: parent.parent.parent.parent.showAddTotp = !parent.parent.parent.parent.showAddTotp
                                            }
                                        }
                                    }

                                    Loader {
                                        Layout.fillWidth: true
                                        visible: selectedEntry && selectedEntry.hasTotp
                                        height: visible ? 140 : 0
                                        active: visible

                                        sourceComponent: Component {
                                            Item {
                                                width: parent ? parent.width : 0
                                                height: 140

                                                Component.onCompleted: {
                                                    if (selectedEntry) {
                                                        var secret = dbManager.getTotpSecret(selectedEntry.id)
                                                        TotpHelper.generateCode(secret)
                                                    }
                                                }

                                                Canvas {
                                                    id: totpTimer
                                                    width: 56; height: 56
                                                    anchors.left: parent.left; anchors.verticalCenter: codeDisplay.verticalCenter
                                                    property real progress: TotpHelper.timeLeft / 30.0

                                                    onProgressChanged: requestPaint()
                                                    onPaint: {
                                                        var ctx = getContext("2d")
                                                        ctx.reset()
                                                        ctx.lineWidth = 4; ctx.lineCap = "round"
                                                        var c = width / 2, r = width / 2 - 4
                                                        ctx.strokeStyle = "#1e293b"
                                                        ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.stroke()
                                                        var t = TotpHelper.timeLeft / 30.0
                                                        ctx.strokeStyle = t > 0.5 ? "#4ade80" : (t > 0.25 ? "#fb923c" : "#f87171")
                                                        ctx.shadowColor = ctx.strokeStyle; ctx.shadowBlur = 8
                                                        ctx.beginPath()
                                                        ctx.arc(c, c, r, -Math.PI/2, -Math.PI/2 + Math.PI * 2 * progress)
                                                        ctx.stroke(); ctx.shadowBlur = 0
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: TotpHelper.timeLeft
                                                        font.pixelSize: 13; font.weight: Font.Bold
                                                        color: TotpHelper.timeLeft > 10 ? "#e2e8f0" : "#f87171"
                                                        Behavior on color { ColorAnimation { duration: 300 } }
                                                    }
                                                    Connections {
                                                        target: TotpHelper
                                                        function onTimeLeftChanged() { totpTimer.requestPaint() }
                                                    }
                                                }

                                                ColumnLayout {
                                                    id: codeDisplay
                                                    anchors { left: totpTimer.right; leftMargin: 16; right: copyTotpBtn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                                    spacing: 4
                                                    Text {
                                                        text: "ONE-TIME CODE"
                                                        font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Bold
                                                        color: "#334155"
                                                    }
                                                    Text {
                                                        id: totpCodeText
                                                        text: {
                                                            var c = TotpHelper.currentCode
                                                            return c.length === 6 ? c.slice(0,3) + " " + c.slice(3) : c
                                                        }
                                                        font.pixelSize: 28; font.weight: Font.Bold
                                                        font.family: "Courier New"; color: "#e2e8f0"
                                                        NumberAnimation on opacity {
                                                            id: totpFlash; from: 0.3; to: 1.0; duration: 400; running: false
                                                        }
                                                        Connections {
                                                            target: TotpHelper
                                                            function onCodeUpdated() { totpFlash.restart() }
                                                        }
                                                    }
                                                    Text {
                                                        text: "Refreshes in " + TotpHelper.timeLeft + "s"
                                                        font.pixelSize: 10; color: "#334155"
                                                    }
                                                }

                                                Rectangle {
                                                    id: copyTotpBtn
                                                    width: 36; height: 36; radius: 9
                                                    anchors.right: parent.right; anchors.verticalCenter: codeDisplay.verticalCenter
                                                    property bool copied: false
                                                    color: copyTotpHover.containsMouse ? "#4c1d95" : "#1e293b"
                                                    border.color: "#7c3aed"; border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: copyTotpBtn.copied ? "✓" : "📋"
                                                        font.pixelSize: 14
                                                        color: copyTotpBtn.copied ? "#a78bfa" : "#e2e8f0"
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                    }
                                                    Timer { id: copyTotpTimer; interval: 1500; onTriggered: copyTotpBtn.copied = false }
                                                    MouseArea {
                                                        id: copyTotpHover; anchors.fill: parent
                                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            clipHelper.copyText(TotpHelper.currentCode)
                                                            copyTotpBtn.copied = true
                                                            copyTotpTimer.restart()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        visible: parent.parent.showAddTotp

                                        Rectangle {
                                            Layout.fillWidth: true; height: 1; color: "#1e293b"
                                        }

                                        Text {
                                            text: "Paste the BASE32 key from your service's 2FA settings"
                                            font.pixelSize: 10; color: "#475569"; wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true; height: 44; radius: 10; color: "#16161f"
                                            border.color: editTotpInput.activeFocus ? "#7c3aed" : "#1e293b"; border.width: 1
                                            Behavior on border.color { ColorAnimation { duration: 200 } }
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 12; spacing: 8
                                                Text { text: "🔑"; font.pixelSize: 13; opacity: 0.5 }
                                                TextField {
                                                    id: editTotpInput; Layout.fillWidth: true
                                                    placeholderText: "e.g. JBSWY3DPEHPK3PXP"
                                                    color: "#e2e8f0"; font.pixelSize: 12
                                                    font.family: "Courier New"
                                                    placeholderTextColor: "#334155"; verticalAlignment: TextInput.AlignVCenter
                                                    onTextChanged: {
                                                        var clean = text.toUpperCase().replace(/\s/g, "")
                                                        if (clean !== text) text = clean
                                                    }
                                                    background: Rectangle { color: "transparent"; border.width: 0 }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                height: 34; width: 120; radius: 8
                                                color: saveTotpHover.containsMouse ? "#5b21b6" : "#4c1d95"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Text { anchors.centerIn: parent; text: "Save TOTP"; font.pixelSize: 12; font.weight: Font.Medium; color: "#e9d5ff" }
                                                MouseArea {
                                                    id: saveTotpHover; anchors.fill: parent
                                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (selectedEntry && editTotpInput.text !== "") {
                                                            dbManager.updateTotpSecret(selectedEntry.id, editTotpInput.text)
                                                            TotpHelper.generateCode(editTotpInput.text)
                                                            editTotpInput.text = ""
                                                            parent.parent.parent.parent.showAddTotp = false
                                                        }
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                height: 34; width: 80; radius: 8; color: "transparent"
                                                border.color: "#1e293b"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 12; color: "#475569" }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        editTotpInput.text = ""
                                                        parent.parent.parent.parent.showAddTotp = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text { text: "DETAILS"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 2; color: "#1e293b"; Layout.topMargin: 20 }
                            Rectangle {
                                Layout.fillWidth: true; height: 44; radius: 12; color: "#16161f"
                                border.color: "#1e293b"; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                                    Text { text: "🏷"; font.pixelSize: 14; opacity: 0.4 }
                                    Text { text: "Added to vault"; font.pixelSize: 12; color: "#334155"; Layout.fillWidth: true }
                                    Text {
                                        text: selectedEntry ? "#" + selectedEntry.id : ""
                                        font.pixelSize: 11; color: "#1e293b"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
