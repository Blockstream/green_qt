import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    required property string type
    required property string subject
    id: self
    contentItem: GStackView {
        initialItem: RequestSupportPage {
            id: page
            type: self.type
            subject: self.subject
            context: self.context
            rightItem: CloseButton {
                onClicked: self.close()
            }
            onSubmitted: (request) => {
                page.StackView.view.replace(page, support_submitted_page, { request, type: page.type }, StackView.PushTransition)
            }
        }
    }

    Component {
        id: support_submitted_page
        SupportSubmittedPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
            footerItem: PrimaryButton {
                text: qsTrId('id_close')
                onClicked: self.close()
            }
        }
    }
}
