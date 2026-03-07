import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CryptoKey

Window {
    width: 400
    height: 600
    visible: true
    title: "CryptoKey Manager"
    color: "#1e1e1e"

    DatabaseManager {
        id: dbManager
    }

    property bool isLoggedIn: false

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8
        visible: !isLoggedIn

        Label {
            text: "CRYPTO KEY"
            font.pixelSize: 28
            font.bold: true
            color: "#00ff88"
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: masterKeyField
            placeholderText: "Enter master key"
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        Button {
            text: "ENTER THE SAFE"
            Layout.fillWidth: true
            onClicked: {
                if (masterKeyField.text !== "") {
                    dbManager.setMasterKey(masterKeyField.text)
                    isLoggedIn = true
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        visible: isLoggedIn

        ColumnLayout {
            width: parent.width
            spacing: 15

            Label {
                text: "Add a new password"
                color: "#ccc"
                font.pixelSize: 16
            }

            TextField { id: serviceInput; placeholderText: "Resource"; Layout.fillWidth: true }
            TextField { id: loginInput; placeholderText: "Login"; Layout.fillWidth: true }
            TextField {
                id: passInput
                placeholderText: "Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }

            Button {
                text: "ENCRYPTE AND SAVE"
                Layout.fillWidth: true
                onClicked: {
                    dbManager.addData(serviceInput.text, loginInput.text, passInput.text)
                    serviceInput.text = ""
                    loginInput.text = ""
                    passInput.text = ""
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#444" }

            TextField {
                id: idForDecrypt
                placeholderText: "ID for decryption"
                Layout.fillWidth: true
            }

            Label {
                id: resultLabel
                text: "The result will appear here"
                color: "#00ff88"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                text: "ENCRYPT"
                Layout.fillWidth: true
                onClicked: {
                    resultLabel.text = "Пароль: " + dbManager.getDecryptedPassword(parseInt(idForDecrypt.text))
                }
            }

            Button {
                text: "EXIT"
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    isLoggedIn = false
                    masterKeyField.text = ""
                }
            }
        }
    }
}
