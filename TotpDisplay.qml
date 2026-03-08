import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 300
    height: 140

    property string secretKey: ""
    property alias codeText: codeLabel.text
    property color accentColor: "#00f2ff"
    property color bgColor: "#0d0d14"

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.bgColor
        border.color: "#1e293b"
        border.width: 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Item {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60

            Canvas {
                id: timerCanvas
                anchors.fill: parent
                property real progress: 1.0

                onProgressChanged: requestPaint()

                Connections {
                    target: TotpHelper
                    function onTimeLeftChanged() {
                        timerCanvas.progress = TotpHelper.timeLeft / 30.0
                    }
                }

                onPaint: {
                    var ctx    = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 4
                    ctx.lineCap   = "round"

                    var center = width / 2
                    var radius = width / 2 - 4

                    ctx.strokeStyle = "rgba(255, 255, 255, 0.08)"
                    ctx.beginPath()
                    ctx.arc(center, center, radius, 0, Math.PI * 2)
                    ctx.stroke()

                    ctx.strokeStyle = root.accentColor
                    ctx.shadowColor = root.accentColor
                    ctx.shadowBlur  = 10
                    ctx.beginPath()
                    ctx.arc(center, center, radius,
                            -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * progress)
                    ctx.stroke()
                    ctx.shadowBlur = 0
                }
            }

            Text {
                anchors.centerIn: parent
                text: TotpHelper.timeLeft
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "TOTP CODE"
                color: "rgba(255, 255, 255, 0.4)"
                font.pixelSize: 10
                font.letterSpacing: 2
            }

            Text {
                id: codeLabel
                text: "--- ---"
                color: "white"
                font.pixelSize: 30
                font.bold: true
                font.family: "Courier New"
                horizontalAlignment: Text.AlignLeft

                NumberAnimation on opacity {
                    id: flashAnim
                    from: 0.4
                    to: 1.0
                    duration: 300
                    running: false
                }

                Connections {
                    target: TotpHelper
                    function onCodeUpdated() {
                        var code = TotpHelper.currentCode
                        if (code.length === 6)
                            code = code.slice(0, 3) + " " + code.slice(3)
                        codeLabel.text = code
                        flashAnim.restart()
                    }
                }
            }
        }
    }

    Rectangle {
        id: copyBtn
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        width: 28
        height: 28
        radius: 14
        color: copyArea.containsMouse ? root.accentColor : "transparent"
        border.color: root.accentColor
        border.width: 1
        property bool copied: false

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: copyBtn.copied ? "✓" : "📋"
            font.pixelSize: 12
            color: copyBtn.copied ? "#0a0a0f" : "white"
        }

        Timer {
            id: copyResetTimer
            interval: 1500
            onTriggered: copyBtn.copied = false
        }

        MouseArea {
            id: copyArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                ClipboardHelper.copy(TotpHelper.currentCode.replace(" ", ""))
                copyBtn.copied = true
                copyResetTimer.restart()
            }
        }
    }
}
