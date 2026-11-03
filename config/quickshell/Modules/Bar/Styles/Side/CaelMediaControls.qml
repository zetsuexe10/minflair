import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Services

// Caelestia's button row. Compact (dashboard): previous, play/pause (fills the row), next.
// Full (media tab): shuffle, previous, play/pause, next, repeat.
RowLayout {
    id: root

    property bool compact: false
    readonly property var player: MprisService.activePlayer

    spacing: 6

    CaelIconButton {
        visible: !root.compact
        icon: "player-shuffle"
        checked: root.player ? root.player.shuffle === true : false
        disabled: !root.player
        iconSize: 18
        onClicked: MprisService.toggleShuffle()
    }

    CaelIconButton {
        icon: "player-previous"
        disabled: !root.player || !root.player.canGoPrevious
        onClicked: root.player.previous()
    }

    CaelIconButton {
        tonal: false
        fill: true
        icon: MprisService.isPlaying ? "player-pause" : "player-play"
        checked: MprisService.isPlaying
        disabled: !root.player || !root.player.canTogglePlaying
        iconSize: 24
        onClicked: root.player.togglePlaying()
    }

    CaelIconButton {
        icon: "player-next"
        disabled: !root.player || !root.player.canGoNext
        onClicked: root.player.next()
    }

    CaelIconButton {
        visible: !root.compact
        icon: (root.player && root.player.loopState === 1) ? "player-loop-once" : "player-loop"
        checked: root.player ? root.player.loopState !== 0 : false
        disabled: !root.player
        iconSize: 18
        onClicked: MprisService.cycleLoop()
    }
}
