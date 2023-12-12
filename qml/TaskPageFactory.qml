import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

QtObject {
    required property TaskGroupMonitor monitor
    required property StackView target
    readonly property Task task: {
        if (!self.monitor) return null
        const groups = self.monitor.groups
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i]
            const tasks = group.tasks
            for (let j = 0; j < tasks.length; j++) {
                const task = tasks[j]
                if (task.status !== Task.Active) continue
                return task
            }
        }
        return null
    }
    readonly property Resolver resolver: {
        const task = self.task
        if (task instanceof AuthHandlerTask) {
            return task.resolver
        } else {
            return null
        }
    }

    id: self
    onResolverChanged: {
        const resolver = self.resolver
        if (resolver instanceof SignMessageResolver && resolver.device instanceof JadeDevice) {
            self.target.push(jade_sign_message_view, { resolver })
        }
    }

    property Component jade_sign_message_view: JadeSignMessageView {}

    property Component jade_connect_view: ConnectJadePage {
        required property DeviceResolver resolver
        onDeviceSelected: (device) => stack_view.push(jade_page, { device })
        padding: 0
        rightItem: Item {}
        footer: Item {}
    }
}
