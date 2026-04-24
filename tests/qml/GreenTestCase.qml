import QtQuick
import QtTest

// Base for component tests: any warning other than known offscreen-runner
// noise (unbundled qrc resources, font fallback) fails the test, so binding
// errors such as TypeError or failed property assignments can't go unnoticed.
TestCase {
    // TestCase is hidden by default, which would make every child report
    // visible == false regardless of its own binding.
    visible: true

    function init() {
        failOnWarning(/^(?!.*(Cannot open: qrc:|Populating font family aliases)).*/)
    }

    // Depth-first search through visual children, in declaration order.
    function findItems(root, predicate) {
        const result = []
        for (const child of root?.children ?? []) {
            if (predicate(child)) result.push(child)
            result.push(...findItems(child, predicate))
        }
        return result
    }
}
