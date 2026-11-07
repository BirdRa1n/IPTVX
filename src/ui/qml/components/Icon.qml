import QtQuick
import QtQuick.Shapes

// Lightweight stroke icon drawn with Qt Quick Shapes (no image files, no
// icon font: crisp at any scale and themable through `color`).
// `path` is an SVG path string in a 24×24 viewBox.
Item {
    id: root

    property string name
    property color color: "black"
    property real strokeWidth: 2
    property bool filled: false

    implicitWidth: 18
    implicitHeight: 18

    readonly property var paths: ({
        "home": "M3 11 L12 4 L21 11 L21 20 Q21 21 20 21 L15 21 L15 15 L9 15 L9 21 L4 21 Q3 21 3 20 Z",
        "tv": "M5 6 L19 6 Q21 6 21 8 L21 17 Q21 19 19 19 L5 19 Q3 19 3 17 L3 8 Q3 6 5 6 Z M8 2 L12 6 L16 2",
        "film": "M5 4 L19 4 Q21 4 21 6 L21 18 Q21 20 19 20 L5 20 Q3 20 3 18 L3 6 Q3 4 5 4 Z M7 4 L7 20 M17 4 L17 20 M3 9 L7 9 M17 9 L21 9 M3 15 L7 15 M17 15 L21 15",
        "series": "M5 8 L19 8 Q21 8 21 10 L21 18 Q21 20 19 20 L5 20 Q3 20 3 18 L3 10 Q3 8 5 8 Z M6 5 L18 5 M9 2 L15 2",
        "guide": "M5 4 L19 4 Q21 4 21 6 L21 19 Q21 21 19 21 L5 21 Q3 21 3 19 L3 6 Q3 4 5 4 Z M3 9 L21 9 M8 2 L8 6 M16 2 L16 6",
        "star": "M12 3 L14.7 8.6 L20.8 9.5 L16.4 13.8 L17.4 19.9 L12 17 L6.6 19.9 L7.6 13.8 L3.2 9.5 L9.3 8.6 Z",
        "clock": "M12 3 A9 9 0 1 1 11.99 3 Z M12 7 L12 12 L15 14",
        "download": "M12 3 L12 15 M7 10 L12 15 L17 10 M4 20 L20 20",
        "plus": "M12 5 L12 19 M5 12 L19 12",
        "plusCircle": "M12 3 A9 9 0 1 1 11.99 3 Z M12 8 L12 16 M8 12 L16 12",
        "gear": "M12 9 A3 3 0 1 1 11.99 9 Z M12 2 L12 5 M12 19 L12 22 M2 12 L5 12 M19 12 L22 12 M4.9 4.9 L7 7 M17 17 L19.1 19.1 M4.9 19.1 L7 17 M17 7 L19.1 4.9",
        "search": "M11 4 A7 7 0 1 1 10.99 4 Z M20 20 L16.5 16.5",
        "back": "M15 5 L8 12 L15 19",
        "close": "M6 6 L18 18 M18 6 L6 18",
        "play": "M7 4 L20 12 L7 20 Z",
        "pause": "M6 4 L10 4 L10 20 L6 20 Z M14 4 L18 4 L18 20 L14 20 Z",
        "prev": "M6 5 L8 5 L8 19 L6 19 Z M20 5 L20 19 L9 12 Z",
        "next": "M16 5 L18 5 L18 19 L16 19 Z M4 5 L4 19 L15 12 Z",
        "fullscreen": "M4 9 L4 4 L9 4 M20 9 L20 4 L15 4 M4 15 L4 20 L9 20 M20 15 L20 20 L15 20",
        "volume": "M4 9 L4 15 L8 15 L13 19 L13 5 L8 9 Z M16 9 Q18 12 16 15",
        "mute": "M4 9 L4 15 L8 15 L13 19 L13 5 L8 9 Z M16 9 L21 14 M21 9 L16 14",
        "refresh": "M20 12 A8 8 0 1 1 17.7 6.3 M20 4 L20 9 L15 9",
        "trash": "M4 7 L20 7 M9 7 L9 4 L15 4 L15 7 M6 7 L7 20 L17 20 L18 7",
        "file": "M6 3 L14 3 L19 8 L19 21 L6 21 Z M14 3 L14 8 L19 8",
        "link": "M10 14 L14 10 M8.5 11.5 L6 14 A3.5 3.5 0 0 0 11 19 L13.5 16.5 M15.5 12.5 L18 10 A3.5 3.5 0 0 0 13 5 L10.5 7.5",
        "server": "M4 4 L20 4 L20 10 L4 10 Z M4 14 L20 14 L20 20 L4 20 Z M8 7 L8.01 7 M8 17 L8.01 17",
        "check": "M5 12 L10 17 L19 7",
        "grid": "M5 3 L8 3 Q10 3 10 5 L10 10 Q10 12 8 12 L5 12 Q3 12 3 10 L3 5 Q3 3 5 3 Z M16 3 L19 3 Q21 3 21 5 L21 6 Q21 8 19 8 L16 8 Q14 8 14 6 L14 5 Q14 3 16 3 Z M16 12 L19 12 Q21 12 21 14 L21 19 Q21 21 19 21 L16 21 Q14 21 14 19 L14 14 Q14 12 16 12 Z M5 16 L8 16 Q10 16 10 18 L10 19 Q10 21 8 21 L5 21 Q3 21 3 19 L3 18 Q3 16 5 16 Z",
        "chevronDown": "M6 9 L12 15 L18 9",
        "chevronRight": "M9 6 L15 12 L9 18",
        "sun": "M12 8 A4 4 0 1 1 11.99 8 Z M12 2 L12 4 M12 20 L12 22 M2 12 L4 12 M20 12 L22 12 M4.9 4.9 L6.3 6.3 M17.7 17.7 L19.1 19.1 M4.9 19.1 L6.3 17.7 M17.7 6.3 L19.1 4.9",
        "list": "M8 6 L21 6 M8 12 L21 12 M8 18 L21 18 M3.5 6 L3.51 6 M3.5 12 L3.51 12 M3.5 18 L3.51 18"
    })

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: Math.min(root.width, root.height) / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: root.filled ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.paths[root.name] ?? "" }
        }
    }
}
