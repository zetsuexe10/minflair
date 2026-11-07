import QtQuick
import qs.Core

Canvas {
    id: root

    property var values: []
    property color lineColor: Theme.accent
    property real floorMax: 1
    readonly property real maxValue: {
        let m = root.floorMax;
        for (let i = 0; i < values.length; i++)
            m = Math.max(m, values[i]);
        return m;
    }

    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const v = values;
        if (!v || v.length < 2)
            return;
        const n = v.length;
        const step = width / 59;
        const x0 = width - (n - 1) * step;
        const pad = 3;
        const h = height - pad * 2;
        ctx.beginPath();
        for (let i = 0; i < n; i++) {
            const x = x0 + i * step;
            const y = pad + h - (v[i] / maxValue) * h;
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.strokeStyle = lineColor;
        ctx.stroke();
        ctx.lineTo(x0 + (n - 1) * step, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.30));
        g.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0));
        ctx.fillStyle = g;
        ctx.fill();
    }
}
