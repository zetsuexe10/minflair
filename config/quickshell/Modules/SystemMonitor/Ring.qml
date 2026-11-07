import QtQuick
import qs.Core

Item {
    id: root

    property real value: 0
    property color ringColor: Theme.accent
    property string label: ""
    property string text: ""
    property real thickness: 7
    property real animated: value

    implicitWidth: 84
    implicitHeight: 84

    Behavior on animated {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    onAnimatedChanged: canvas.requestPaint()
    onRingColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const r = Math.min(width, height) / 2 - root.thickness / 2 - 1;
            const cx = width / 2;
            const cy = height / 2;
            ctx.lineCap = "round";
            ctx.lineWidth = root.thickness;
            ctx.strokeStyle = Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();
            const v = Math.max(0, Math.min(100, root.animated)) / 100;
            if (v <= 0.005)
                return;
            ctx.strokeStyle = root.ringColor;
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v);
            ctx.stroke();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            font.pixelSize: 15
            font.bold: true
            color: Theme.fg
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: 10
            color: Theme.muted
        }
    }
}
