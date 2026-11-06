import QtQuick
import qs.Core.Windows

OverlayWindow {
    id: root

    widgetId: "github"
    enableShadow: true
    preferredWidth: card.implicitWidth + (contentPadding * 2)
    preferredHeight: card.implicitHeight + (contentPadding * 2)

    GithubWidget {
        id: card

        width: implicitWidth
        height: implicitHeight
    }

}
