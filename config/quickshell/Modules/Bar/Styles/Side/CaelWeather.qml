import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Weather tab: current conditions and the seven day forecast.
Item {
    id: root

    implicitWidth: 730
    implicitHeight: 330

    function dayName(iso) {
        const p = iso.split("-");
        return Qt.locale().dayName(new Date(+p[0], +p[1] - 1, +p[2]).getDay(), Locale.ShortFormat);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        CaelCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            corner: 30

            SideText {
                anchors.centerIn: parent
                visible: !WeatherService.loaded
                text: WeatherService.errorText !== "" ? WeatherService.errorText : "Loading weather..."
                color: SideState.muted
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 28
                visible: WeatherService.loaded

                Text {
                    text: WeatherService.glyph
                    font.pixelSize: 72
                    color: SideState.primary
                }

                ColumnLayout {
                    spacing: 0

                    SideText {
                        text: WeatherService.temp + WeatherService.unit
                        customSize: 36
                        font.bold: true
                    }

                    SideText {
                        text: WeatherService.description + " · " + WeatherService.city
                        color: SideState.muted
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                GridLayout {
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 6

                    Repeater {
                        model: [
                            { "k": "Feels like", "v": WeatherService.feels + WeatherService.unit },
                            { "k": "Humidity", "v": WeatherService.humidity + "%" },
                            { "k": "Wind", "v": WeatherService.wind + " " + WeatherService.windUnit },
                            { "k": "Sun", "v": WeatherService.sunrise + " - " + WeatherService.sunset }
                        ]

                        ColumnLayout {
                            required property var modelData

                            spacing: 0

                            SideText {
                                text: parent.modelData.k
                                color: SideState.muted
                                customSize: 10
                            }

                            SideText {
                                text: parent.modelData.v
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Repeater {
                model: WeatherService.days

                CaelCard {
                    id: dayCard

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    corner: 22
                    color: index === 0 ? SideState.cardHi : SideState.card

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dayCard.index === 0 ? "Today" : root.dayName(dayCard.modelData.date)
                            customSize: 11
                            color: dayCard.index === 0 ? SideState.primary : SideState.muted
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WeatherService.glyphFor(dayCard.modelData.code, true)
                            font.pixelSize: 26
                            color: SideState.fg
                        }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dayCard.modelData.max + "°"
                            font.bold: true
                        }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dayCard.modelData.min + "°"
                            color: SideState.muted
                        }
                    }
                }
            }
        }
    }
}
