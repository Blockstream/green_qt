#include "devicediscoveryagent_macos.h"

#ifdef Q_OS_MAC

#include "device.h"
#include "devicemanager.h"

#include <QDebug>

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDManager.h>

static void DeviceMatchingCallback(void* context, IOReturn /* result */, void* /* sender */, IOHIDDeviceRef handle);
static void DeviceRemovalCallback(void* context, IOReturn /* result */, void* /* sender */, IOHIDDeviceRef handle);

static CFMutableDictionaryRef createMatchingDictionary(int32_t vendor_id, int32_t product_id, uint32_t usage_page)
{
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable( kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFNumberRef vendor_id_ref = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &vendor_id);
    CFNumberRef product_id_ref = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &product_id);
    CFNumberRef usage_page_ref = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &usage_page);
    CFDictionarySetValue(dict, CFSTR(kIOHIDVendorIDKey), vendor_id_ref);
    CFDictionarySetValue(dict, CFSTR(kIOHIDProductIDKey), product_id_ref);
    CFDictionarySetValue(dict, CFSTR(kIOHIDDeviceUsagePageKey), usage_page_ref);
    CFRelease(vendor_id_ref);
    CFRelease(product_id_ref);
    CFRelease(usage_page_ref);
    return dict;
}

static int32_t DeviceGetPropertyInt32(IOHIDDeviceRef handle, CFStringRef key)
{
    CFTypeRef ref = IOHIDDeviceGetProperty(handle, key);
    Q_ASSERT(CFGetTypeID(ref) == CFNumberGetTypeID());
    int32_t value{0};
    CFNumberGetValue(CFNumberRef(ref), kCFNumberSInt32Type, &value);
    return value;
}

static QString DeviceGetPropertyString(IOHIDDeviceRef handle, CFStringRef key)
{
    CFTypeRef ref = IOHIDDeviceGetProperty(handle, key);
    Q_ASSERT(CFGetTypeID(ref) == CFStringGetTypeID());
    return QString::fromCFString(CFStringRef(ref));
}

static void DeviceMatchingCallback(void* context, IOReturn /* result */, void* /* sender */, IOHIDDeviceRef handle)
{
    auto vendor_id = DeviceGetPropertyInt32(handle, CFSTR(kIOHIDVendorIDKey));
    auto product_id = DeviceGetPropertyInt32(handle, CFSTR(kIOHIDProductIDKey));
    //auto usage_page = DeviceGetPropertyInt32(handle, CFSTR(kIOHIDDeviceUsagePageKey));

    qDebug() << vendor_id << product_id;

    //CFSTR(kIOHIDVendorIDKey), CFSTR(kIOHIDVendorIDSourceKey), CFSTR(kIOHIDProductIDKey)
    //IOHIDDeviceGetProperty(handle, CFSTR(kIOHIDVendorIDKey));
    //((QString::fromCFString()

    //CFNumberGetValue(static_cast<CFNumberRef>(ref), kCFNumberSInt32Type, &value);
/*
    for (auto key : { CFSTR(kIOHIDTransportKey), CFSTR(kIOHIDVendorIDKey), CFSTR(kIOHIDVendorIDSourceKey), CFSTR(kIOHIDProductIDKey), CFSTR(kIOHIDVersionNumberKey), CFSTR(kIOHIDManufacturerKey), CFSTR(kIOHIDProductKey), CFSTR(kIOHIDSerialNumberKey), CFSTR(kIOHIDCountryCodeKey), CFSTR(kIOHIDStandardTypeKey), CFSTR(kIOHIDLocationIDKey), CFSTR(kIOHIDDeviceUsageKey), CFSTR(kIOHIDDeviceUsagePageKey), CFSTR(kIOHIDDeviceUsagePairsKey), CFSTR(kIOHIDPrimaryUsageKey), CFSTR(kIOHIDPrimaryUsagePageKey), CFSTR(kIOHIDMaxInputReportSizeKey), CFSTR(kIOHIDMaxOutputReportSizeKey), CFSTR(kIOHIDMaxFeatureReportSizeKey), CFSTR(kIOHIDReportIntervalKey), CFSTR(kIOHIDSampleIntervalKey), CFSTR(kIOHIDBatchIntervalKey), CFSTR(kIOHIDRequestTimeoutKey), CFSTR(kIOHIDReportDescriptorKey), CFSTR(kIOHIDResetKey), CFSTR(kIOHIDKeyboardLanguageKey), CFSTR(kIOHIDAltHandlerIdKey), CFSTR(kIOHIDBuiltInKey), CFSTR(kIOHIDDisplayIntegratedKey), CFSTR(kIOHIDProductIDMaskKey), CFSTR(kIOHIDProductIDArrayKey), CFSTR(kIOHIDPowerOnDelayNSKey), CFSTR(kIOHIDCategoryKey), CFSTR(kIOHIDMaxResponseLatencyKey), CFSTR(kIOHIDUniqueIDKey), CFSTR(kIOHIDPhysicalDeviceUniqueIDKey), CFSTR(kIOHIDModelNumberKey) }) {
        CFTypeRef ref = IOHIDDeviceGetProperty(handle, key);
        if (!ref) {
            qDebug() << key << ": null";
        } else if (CFGetTypeID(ref) == CFNumberGetTypeID()) {
            int32_t value{0};
            CFNumberGetValue(static_cast<CFNumberRef>(ref), kCFNumberSInt32Type, &value);
            qDebug() << key << ":" << value << "(number)";
        } else if (CFGetTypeID(ref) == CFStringGetTypeID()) {
            qDebug() << key << ":" << QString::fromCFString(static_cast<CFStringRef>(ref));
        } else if (CFGetTypeID(ref) == CFDataGetTypeID()) {
            qDebug() << key << ":" << QByteArray::fromCFData(static_cast<CFDataRef>(ref)).toHex();
        } else {
            qDebug() << key << ":";
            CFShow(ref);
        }
    }
    */

    auto device = new DevicePrivateImpl;
    device->handle = handle;
    device->type = Device::LedgerNanoX;
    auto d = new Device(device);

    auto agent = static_cast<DeviceDiscoveryAgentPrivate*>(context);
    agent->m_devices.insert(handle, device);

    d->setVendor("Ledger");
    d->setProduct("Nano X");
    d->setInterface("USB");

    QTimer::singleShot(200, d, [=] {
        //manager->exchange(handle, new GetFirmwareCommand);
        auto cmd = new GetAppNameCommand;
        device->exchange(cmd);
        QObject::connect(cmd, &Command::finished, [agent, handle, d] {
            if (d->appName().startsWith("OLOS")) {
                agent->m_devices.remove(handle);
                d->deleteLater();
            } else {
                DeviceManager::instance()->addDevice(d);
            }
        });
    });
}


static void DeviceRemovalCallback(void* context, IOReturn /* result */, void* /* sender */, IOHIDDeviceRef handle)
{
    auto agent = static_cast<DeviceDiscoveryAgentPrivate*>(context);
    auto device = agent->m_devices.take(handle);
    if (!device) return;
    DeviceManager::instance()->removeDevice(device->q);
    device->q->deleteLater();
}

static void hid_report_callback(void *context, IOReturn result, void *sender, IOHIDReportType report_type, uint32_t report_id, uint8_t *report, CFIndex report_length)
{
    Q_ASSERT(result == kIOReturnSuccess);
    Q_ASSERT(report_type == kIOHIDReportTypeInput);
    if (report_id == 0) {
        auto agent = static_cast<DeviceDiscoveryAgentPrivate*>(context);
        auto handle = static_cast<IOHIDDeviceRef>(sender);
        Q_ASSERT(agent->m_devices.contains(handle));
        auto device = agent->m_devices[handle];
        device->inputReport(QByteArray(reinterpret_cast<const char*>(report), report_length));
    } else {
        qDebug() << __PRETTY_FUNCTION__ << "report_id:" << report_id;
    }
}

DeviceDiscoveryAgentPrivate::DeviceDiscoveryAgentPrivate() {
    CFMutableArrayRef multiple = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    CFMutableDictionaryRef dict;
    dict = createMatchingDictionary(LEDGER_VENDOR_ID, LEDGER_NANOS_ID, 0xFFA0);
    CFArrayAppendValue(multiple, dict);
    CFRelease(dict);
    dict = createMatchingDictionary(LEDGER_VENDOR_ID, LEDGER_NANOX_ID, 0xFFA0);
    CFArrayAppendValue(multiple, dict);
    CFRelease(dict);
    dict = createMatchingDictionary(LEDGER_VENDOR_ID, LEDGER_NANOS_ID, 0xFFA0);
    CFArrayAppendValue(multiple, dict);
    CFRelease(dict);

    m_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone);
    IOHIDManagerSetDeviceMatching(m_manager, NULL);
    IOHIDManagerScheduleWithRunLoop(m_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDManagerSetDeviceMatchingMultiple(m_manager, multiple);
    IOHIDManagerRegisterDeviceMatchingCallback(m_manager, DeviceMatchingCallback, this);
    IOHIDManagerRegisterDeviceRemovalCallback(m_manager, DeviceRemovalCallback, this);
    IOHIDManagerRegisterInputReportCallback(m_manager, hid_report_callback, this);
    IOHIDManagerOpen(m_manager, kIOHIDOptionsTypeSeizeDevice);
}

DeviceDiscoveryAgentPrivate::~DeviceDiscoveryAgentPrivate()
{
    IOHIDManagerClose(m_manager, kIOHIDManagerOptionNone);
}


QList<QByteArray> transport(const QByteArray& data) {
    QList<QByteArray> packets;
    int offset = 0;
    //qDebug() << "wrapping" << data.toHex();
    while (offset < data.size()) {
        QByteArray result;
        auto d = data.mid(offset, 64 - (packets.empty() ? 7 : 5));
        offset += d.size();
        QDataStream stream(&result, QIODevice::WriteOnly);
        stream << uint16_t(0x0101) << uint8_t(0x05) << uint16_t(packets.size());
        if (packets.empty()) stream << uint16_t(data.length());
        result.append(d);
        //qDebug() << "  packet " << result.toHex() << result.size();
        Q_ASSERT(result.length() <= 64);
        result = result.leftJustified(64, 0x0);
        packets.append(result);
    }
    return packets;
}

void DevicePrivateImpl::exchange(Command* command)
{
    const bool send = queue.empty();
    if (send) {
        const auto payload = command->payload();
        //qDebug() << "send " << payload.toHex();
        for (const auto& packet : transport(payload)) {
            //qDebug() << "send packet " << packet.toHex();
            auto res = IOHIDDeviceSetReport(handle, kIOHIDReportTypeOutput, 0, (const uint8_t*) packet.constData(), packet.size());
            if (res != kIOReturnSuccess) {
                qDebug() << "FAILED";
                delete command;
                return;
            }
        }
        //qDebug() << "send done";
    }
    queue.enqueue(command);
    if (send) q->busyChanged();
}

void DevicePrivateImpl::inputReport(const QByteArray& data)
{
    //qDebug() << "read hid" << data.toHex();
    Q_ASSERT(!queue.empty());
    QDataStream stream(data);
    auto command = queue.head();
    int r = command->readHIDReport(q, stream);
    if (r == 2) return;
    if (r == 1) qWarning("command failed");
    queue.dequeue();
    if (!queue.empty()) {
        //qDebug() << "sending next command";
        command = queue.head();
        const auto payload = command->payload();
        //qDebug() << "send " << payload.toHex();
        for (const auto& packet : transport(payload)) {
            //qDebug() << "send packet " << packet.toHex();
            auto res = IOHIDDeviceSetReport(handle, kIOHIDReportTypeOutput, 0, (const uint8_t*) packet.constData(), packet.size());
            if (res != kIOReturnSuccess) {
                qDebug() << "FAILED";
                delete command;
                return;
            }
        }
        //qDebug() << "send done";
    } else {
        q->busyChanged();
    }
}

#endif // Q_OS_MAC
