import QtQuick

QtObject {
    property string currency: "usd"
    property int refreshCount: 0

    // Flat [x0, y0, x1, y1, ...] format
    property var pricesDay: [1000, 100, 2000, 120]
    property var pricesWeek: [1000, 80, 2000, 90]
    property var pricesMonth: [1000, 70, 2000, 95]
    property var pricesYear: [1000, 60, 2000, 110]
    property var pricesFiveYears: [1000, 50, 2000, 130]

    function refresh() {
        refreshCount += 1
    }
}
