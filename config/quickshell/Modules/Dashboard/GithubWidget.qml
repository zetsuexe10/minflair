import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Dashboard.Components

Card {
    id: root

    clip: true
    contentPadding: Constants.sizeLg
    implicitWidth: 300
    property bool sortStars: false
    readonly property var sortedRepos: {
        const r = (GithubService.repos || []).slice();
        if (sortStars)
            r.sort((a, b) => (b.stars || 0) - (a.stars || 0));
        return r.slice(0, 5);
    }
    implicitHeight: (GithubService.username !== "" ? profileLayout.implicitHeight : errorLayout.implicitHeight) + root.contentPadding * 2

    ColumnLayout {
        id: profileLayout

        anchors.fill: parent
        spacing: Constants.sizeSm
        visible: GithubService.username !== ""

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            TapHandler {
                onTapped: Qt.openUrlExternally("https://github.com/" + GithubService.username)
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            Item {
                id: avatarWrapper

                width: 54
                height: 54
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: gradientRing

                    anchors.fill: parent
                    radius: width / 2
                    scale: avatarHover.hovered ? 1.06 : 1

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }

                        GradientStop {
                            position: 1
                            color: Theme.accentComplementary
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
                        }

                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: Constants.animUltraSlow * 2
                        loops: Animation.Infinite
                        running: GithubService.isFetching && Constants.durationFactor > 0
                        onRunningChanged: {
                            if (!running)
                                gradientRing.rotation = 0;

                        }
                    }

                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    radius: width / 2
                    color: Theme.bg
                }

                Item {
                    id: avatarContainer

                    anchors.centerIn: parent
                    width: 44
                    height: 44

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "github"
                        iconSize: Constants.sizeLg
                        color: Theme.muted
                        visible: userImage.status !== Image.Ready
                    }

                    Image {
                        id: userImage

                        anchors.fill: parent
                        source: GithubService.avatarUrl
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(88, 88)
                        mipmap: true
                        visible: false
                        antialiasing: true
                        cache: false
                    }

                    Rectangle {
                        id: mask

                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        antialiasing: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: userImage
                        maskEnabled: true
                        // Keep a real 0..1 alpha ramp so the antialiased circle
                        // edge is not promoted to fully opaque by MultiEffect.
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                        visible: userImage.status === Image.Ready

                        maskSource: ShaderEffectSource {
                            visible: false
                            hideSource: true
                            smooth: true
                            sourceItem: mask
                        }

                    }

                }

                HoverHandler {
                    id: avatarHover
                }

            }

            ColumnLayout {
                spacing: Constants.size3Xs
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                ThemedText {
                    text: GithubService.fullName || GithubService.username
                    customSize: Constants.sizeMd
                    font.bold: true
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                ThemedText {
                    text: "@" + GithubService.username
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        ThemedText {
            visible: GithubService.bio !== ""
            text: GithubService.bio
            color: Theme.fg
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            maximumLineCount: 2
            elide: Text.ElideRight

            font {
                italic: true
            }

        }

        Divider {
        }

        ColumnLayout {
            id: statsLayout

            Layout.fillWidth: true
            spacing: Constants.size2Xs

            InfoRow {
                visible: GithubService.hasToken
                icon: "commit"
                label: "Total Commits"
                value: String(GithubService.totalCommits)
            }

            InfoRow {
                icon: "star"
                label: "Total Stars"
                value: String(GithubService.totalStars)
            }

            InfoRow {
                icon: "code"
                label: "Repositories"
                value: String(GithubService.publicRepos + (GithubService.hasToken ? GithubService.privateRepos : 0))
            }

            InfoRow {
                icon: "fork"
                label: "Total Forks"
                value: String(GithubService.totalForks)
            }

        }

        InfoRow {
            visible: GithubService.hasToken
            icon: "code"
            label: "Open PRs / Issues"
            value: GithubService.openPRs + " / " + GithubService.openIssues
        }

        // problems fetching: token rejected, rate limit, offline
        Rectangle {
            Layout.fillWidth: true
            visible: GithubService.errorMessage !== "" || GithubService.tokenStatus === "invalid" || GithubService.tokenStatus === "other_user"
            implicitHeight: warn.implicitHeight + Constants.sizeSm * 2
            radius: Constants.sizeSm
            color: Theme.bgSecondary

            ThemedText {
                id: warn

                anchors.fill: parent
                anchors.margins: Constants.sizeSm
                text: GithubService.errorMessage !== "" ? GithubService.errorMessage : GithubService.tokenMessage
                color: "#e06b74"
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: GithubService.repos.length > 0

            ThemedText {
                Layout.fillWidth: true
                text: "Repositories"
                font.bold: true
            }

            Repeater {
                model: ["Recent", "Stars"]

                ThemedText {
                    required property string modelData
                    required property int index

                    text: modelData
                    color: (root.sortStars ? 1 : 0) === index ? Theme.accent : Theme.muted

                    TapHandler {
                        onTapped: root.sortStars = parent.index === 1
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        Repeater {
            model: root.sortedRepos

            Card {
                id: repoCard

                required property var modelData

                Layout.fillWidth: true
                backgroundColor: Theme.bgSecondary
                contentPadding: Constants.sizeSm
                implicitHeight: repoCol.implicitHeight + contentPadding * 2
                radius: Constants.sizeSm
                useBorder: false
                scale: rh.hovered ? 1.02 : 1

                Behavior on scale { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutQuad } }

                TapHandler {
                    onTapped: Qt.openUrlExternally(repoCard.modelData.url)
                }

                HoverHandler {
                    id: rh

                    cursorShape: Qt.PointingHandCursor
                }

                ColumnLayout {
                    id: repoCol

                    anchors.fill: parent
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Constants.sizeXs

                        ThemedText {
                            Layout.fillWidth: true
                            text: repoCard.modelData.name
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        ThemedText {
                            visible: repoCard.modelData.private
                            text: "private"
                            customSize: Constants.sizeXs + 1
                            color: Theme.accent
                        }

                        ThemedText {
                            visible: repoCard.modelData.stars > 0
                            text: "★ " + repoCard.modelData.stars
                            customSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }
                    }

                    ThemedText {
                        visible: repoCard.modelData.description !== ""
                        Layout.fillWidth: true
                        text: repoCard.modelData.description
                        customSize: Constants.sizeXs + 2
                        color: Theme.muted
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    ThemedText {
                        visible: repoCard.modelData.language !== ""
                        text: repoCard.modelData.language
                        customSize: Constants.sizeXs + 2
                        color: Theme.muted
                    }
                }
            }
        }

    }

    ColumnLayout {
        id: errorLayout

        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        visible: GithubService.username === ""
        spacing: Constants.sizeSm

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: width / 2
            color: Theme.bgSecondary

            SvgIcon {
                anchors.centerIn: parent
                icon: "github"
                iconSize: Constants.size4Xl
                flat: true
                iconColor: Theme.accent
            }

        }

        Item {
            Layout.preferredHeight: Constants.sizeXs
        }

        ThemedText {
            text: "Username Required"
            color: Theme.fg
            customSize: Constants.sizeMd
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ThemedText {
            text: "Configure your GitHub username in settings to view your statistics."
            color: Theme.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.preferredHeight: Constants.sizeXs
        }

        ThemedButton {
            text: "Configure"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                AppState.pendingSettingsTab = 4;
                AppState.openWidget("minflair_settings");
            }
        }

        Item {
            Layout.fillHeight: true
        }

    }

}
