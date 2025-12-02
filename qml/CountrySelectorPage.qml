import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    id: page
    required property Context context
    required property string selectedCountryCode
    signal countrySelected(string countryCode)
    
    title: 'Select Country'
    property var countriesList: []
    property var filteredCountriesList: []
    
    Countries {
        id: countries_model
        Component.onCompleted: {
            const flagCodes = [
                'AD', 'AE', 'AG', 'AI', 'AL', 'AM', 'AO', 'AQ', 'AR', 'AS', 'AT', 'AU', 'AW', 'AX', 'AZ',
                'BA', 'BB', 'BD', 'BE', 'BF', 'BG', 'BH', 'BI', 'BJ', 'BL', 'BM', 'BN', 'BO', 'BQ', 'BR',
                'BS', 'BT', 'BV', 'BW', 'BY', 'BZ', 'CA', 'CC', 'CD', 'CF', 'CG', 'CH', 'CI', 'CK', 'CL',
                'CM', 'CN', 'CO', 'CR', 'CV', 'CW', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM', 'DO', 'DZ',
                'EC', 'EE', 'EG', 'EH', 'ER', 'ES', 'ET', 'FI', 'FJ', 'FK', 'FM', 'FO', 'FR', 'GA', 'GB',
                'GD', 'GE', 'GF', 'GG', 'GH', 'GI', 'GL', 'GM', 'GN', 'GP', 'GQ', 'GR', 'GS', 'GT', 'GU',
                'GW', 'GY', 'HK', 'HM', 'HN', 'HR', 'HT', 'HU', 'ID', 'IE', 'IL', 'IM', 'IN', 'IO', 'IS',
                'IT', 'JE', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM', 'KN', 'KR', 'KW', 'KY', 'KZ',
                'LA', 'LB', 'LC', 'LI', 'LK', 'LR', 'LS', 'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME',
                'MF', 'MG', 'MH', 'MK', 'ML', 'MM', 'MN', 'MO', 'MP', 'MQ', 'MR', 'MS', 'MT', 'MU', 'MV',
                'MW', 'MX', 'MY', 'MZ', 'NA', 'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP', 'NR', 'NU',
                'NZ', 'OM', 'PA', 'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM', 'PN', 'PR', 'PS', 'PT', 'PW',
                'PY', 'QA', 'RE', 'RO', 'RS', 'RW', 'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI', 'SJ',
                'SK', 'SL', 'SM', 'SN', 'SR', 'ST', 'SV', 'SX', 'SZ', 'TC', 'TD', 'TF', 'TG', 'TH', 'TJ',
                'TK', 'TL', 'TM', 'TN', 'TO', 'TR', 'TT', 'TV', 'TW', 'TZ', 'UA', 'UG', 'UM', 'US', 'UY',
                'UZ', 'VA', 'VC', 'VE', 'VG', 'VI', 'VN', 'VU', 'WF', 'WS', 'XK', 'YE', 'YT', 'ZA', 'ZM', 'ZW'
            ]

            const codeToName = {}
            for (let i = 0; i < countries_model.count; i++) {
                const country = countries_model.get(i)
                codeToName[country.country.toUpperCase()] = country.name
            }
            
            const country = (code) => ({
                code: code,
                icon: 'qrc:/flags/' + code + '-flag.svg',
                name: codeToName[code] || code
            })

            const countries = []
            for (const code of flagCodes) {
                if (code === page.selectedCountryCode) continue
                countries.push(country(code))
            }
            countries.sort((a, b) => a.name.localeCompare(b.name))
            page.countriesList = [country(page.selectedCountryCode), ...countries]
            page.filteredCountriesList = page.countriesList
        }
    }
    
    function filterCountries(searchText) {
        if (!searchText || searchText.trim() === '') {
            page.filteredCountriesList = page.countriesList
        } else {
            const searchLower = searchText.toLowerCase().trim()
            page.filteredCountriesList = page.countriesList.filter(country => {
                return country.name.toLowerCase().includes(searchLower) ||
                       country.code.toLowerCase().includes(searchLower)
            })
        }
    }
    
    contentItem: ColumnLayout {
        spacing: 12
        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Label.AlignHCenter
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            color: '#A0A0A0'
            text: 'Please select your billing location to complete the checkout successfully.'
            wrapMode: Label.Wrap
        }
        SearchField {
            Layout.fillWidth: true
            id: search_field
            onTextChanged: page.filterCountries(text)
        }
        TListView {
            id: list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            spacing: 5
            model: page.filteredCountriesList
            delegate: CountryDelegate {
                required property var modelData
                countryCode: modelData ? modelData.code : ''
                countryName: modelData ? modelData.name : ''
                flagIcon: modelData ? modelData.icon : ''
                onCountrySelected: (code) => page.countrySelected(code)
            }
        }
    }
    
    component CountryDelegate: ItemDelegate {
        required property string countryCode
        required property string countryName
        required property string flagIcon
        property bool isSelected: delegate.countryCode === page.selectedCountryCode
        signal countrySelected(string countryCode)
        id: delegate
        activeFocusOnTab: true
        leftPadding: 24
        rightPadding: 24
        topPadding: 16
        bottomPadding: 16
        highlighted: delegate.isSelected
        background: Item {
            Rectangle {
                anchors.fill: parent
                anchors.margins: delegate.visualFocus ? 4 : 0
                color: Qt.lighter(delegate.highlighted ? '#062F4A' : '#181818', delegate.hovered ? 1.2 : 1)
                radius: delegate.visualFocus ? 1 : 5
            }
            // Rectangle {
            //     anchors.fill: parent
            //     anchors.margins: delegate.visualFocus ? 4 : 0
            //     border.width: 2
            //     border.color: '#00BCFF'
            //     color: 'transparent'
            //     radius: 5
            //     visible: delegate.highlighted
            // }
            Rectangle {
                anchors.fill: parent
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 5
                visible: {
                    if (delegate.activeFocus) {
                        switch (delegate.focusReason) {
                        case Qt.TabFocusReason:
                        case Qt.BacktabFocusReason:
                        case Qt.ShortcutFocusReason:
                            return true
                        }
                    }
                    return false
                }
            }
        }
        width: ListView.view.width
        contentItem: RowLayout {
            spacing: 12
             Image {
                 Layout.preferredWidth: 32
                 Layout.preferredHeight: 24
                 fillMode: Image.PreserveAspectFit
                 source: delegate.flagIcon
             }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    font.weight: 600
                    text: delegate.countryName
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
                Label {
                    Layout.fillWidth: true
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: delegate.countryCode
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                fillMode: Image.PreserveAspectFit
                source: 'qrc:/svg2/arrow_right.svg'
                opacity: 0.6
            }
        }
        onClicked: {
            delegate.countrySelected(delegate.countryCode)
        }
    }
}

