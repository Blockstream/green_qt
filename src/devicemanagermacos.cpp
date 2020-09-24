#include "devicemanagermacos.h"

#include <QDebug>
#include <QTimer>
#include <QThread>
#include <QDataStream>
#include <QStringList>


static int32_t DeviceGetPropertyInt32(IOHIDDeviceRef device, CFStringRef key)
{
    int32_t value{0};
    CFNumberRef number = static_cast<CFNumberRef>(IOHIDDeviceGetProperty(device, key));
    if (number) CFNumberGetValue(number, kCFNumberSInt32Type, &value);
    return value;
}

static QString DeviceGetId(IOHIDDeviceRef handle)
{
    io_string_t path;
    io_service_t service = IOHIDDeviceGetService(handle);
    kern_return_t ret = IORegistryEntryGetPath(service, kIOServicePlane, path);
    if (ret != KERN_SUCCESS) return QString{};
    auto parts = QString::fromLocal8Bit(path).split("/");

    return parts.mid(1, parts.size() - 3).join("/");
}

static bool DeviceMatchesVendorAndProduct(IOHIDDeviceRef handle, int32_t vendor_id, int32_t product_id)
{
    return DeviceGetPropertyInt32(handle, CFSTR(kIOHIDVendorIDKey)) == vendor_id &&
           DeviceGetPropertyInt32(handle, CFSTR(kIOHIDProductIDKey)) == product_id;
}

static void DeviceDumpProperties(IOHIDDeviceRef device)
{
    for (auto key : { CFSTR(kIOHIDTransportKey), CFSTR(kIOHIDVendorIDKey), CFSTR(kIOHIDVendorIDSourceKey), CFSTR(kIOHIDProductIDKey), CFSTR(kIOHIDVersionNumberKey), CFSTR(kIOHIDManufacturerKey), CFSTR(kIOHIDProductKey), CFSTR(kIOHIDSerialNumberKey), CFSTR(kIOHIDCountryCodeKey), CFSTR(kIOHIDStandardTypeKey), CFSTR(kIOHIDLocationIDKey), CFSTR(kIOHIDDeviceUsageKey), CFSTR(kIOHIDDeviceUsagePageKey), CFSTR(kIOHIDDeviceUsagePairsKey), CFSTR(kIOHIDPrimaryUsageKey), CFSTR(kIOHIDPrimaryUsagePageKey), CFSTR(kIOHIDMaxInputReportSizeKey), CFSTR(kIOHIDMaxOutputReportSizeKey), CFSTR(kIOHIDMaxFeatureReportSizeKey), CFSTR(kIOHIDReportIntervalKey), CFSTR(kIOHIDSampleIntervalKey), CFSTR(kIOHIDBatchIntervalKey), CFSTR(kIOHIDRequestTimeoutKey), CFSTR(kIOHIDReportDescriptorKey), CFSTR(kIOHIDResetKey), CFSTR(kIOHIDKeyboardLanguageKey), CFSTR(kIOHIDAltHandlerIdKey), CFSTR(kIOHIDBuiltInKey), CFSTR(kIOHIDDisplayIntegratedKey), CFSTR(kIOHIDProductIDMaskKey), CFSTR(kIOHIDProductIDArrayKey), CFSTR(kIOHIDPowerOnDelayNSKey), CFSTR(kIOHIDCategoryKey), CFSTR(kIOHIDMaxResponseLatencyKey), CFSTR(kIOHIDUniqueIDKey), CFSTR(kIOHIDPhysicalDeviceUniqueIDKey), CFSTR(kIOHIDModelNumberKey) }) {
        CFTypeRef ref = IOHIDDeviceGetProperty(device, key);
        if (!ref) {
            qDebug() << key << ": null";
        } else if (CFGetTypeID(ref) == CFNumberGetTypeID()) {
            int32_t value{0};
            CFNumberGetValue(static_cast<CFNumberRef>(ref), kCFNumberSInt32Type, &value);
            qDebug() << key << ":" << value;
        } else if (CFGetTypeID(ref) == CFStringGetTypeID()) {
            qDebug() << key << ":" << QString::fromCFString(static_cast<CFStringRef>(ref));
        } else if (CFGetTypeID(ref) == CFDataGetTypeID()) {
            qDebug() << key << ":" << QByteArray::fromCFData(static_cast<CFDataRef>(ref)).toHex();
        } else {
            qDebug() << key << ":";
            CFShow(ref);
        }
    }
}


static void hid_report_callback(void *context, IOReturn result, void *sender,
                         IOHIDReportType report_type, uint32_t report_id,
                         uint8_t *report, CFIndex report_length);


static void DeviceMatchingCallback(void* context, IOReturn /* result */, void* /* sender */, IOHIDDeviceRef handle)
{
    auto manager = static_cast<DeviceManagerMacos*>(context);

    // Ledger Nano X
    if (DeviceMatchesVendorAndProduct(handle, 0x2C97, 0x0004)) {
        int32_t usage_page = DeviceGetPropertyInt32(handle, CFSTR(kIOHIDPrimaryUsagePageKey));
        if (usage_page == 0xF1D0) return;

        auto id = DeviceGetId(handle);
        qDebug() << "LEDGER NANO X connected" << id;

        //IOHIDDeviceOpen(handle, kIOHIDOptionsTypeNone);// TypeSeizeDevice);
        //DeviceDumpProperties(handle);

        //auto t = new QTimer(manager);
        //QObject::connect(t, &QTimer::timeout, [manager, handle] {
        QTimer::singleShot(200, manager, [manager, handle] {
            //manager->exchange(handle, new GetFirmwareCommand);
            manager->exchange(handle, new GetAppNameCommand);
            //manager->exchange(handle, new GetWalletPublicKeyCommand({0}));
        });

#if 0
        DeviceMacOs* device = static_cast<DeviceMacOs*>(manager->findDevice(id));
        if (!device) {
            device = new DeviceMacOs;
            device->setObjectName("FOO");
            device->id = id;
            manager->addDevice(device);
            device->m_properties.insert("app", false);
#if 1
            QTimer* timer = new QTimer(device);
            QObject::connect(timer, &QTimer::timeout, [device] {
                if (device->m_handles.contains(0xFFA0) && device->m_handles.contains(0xF1D0))
                    AskApplicationId(device->m_handles[0xFFA0]);
            });
            timer->start(500);
#endif
        }
        device->m_handles.insert(usage_page, handle);
        device->m_properties.insert("connected", true);

        if (usage_page == 0xFFA0) {
        } else {
            device->m_properties.insert("app", true);
        }
#if 1
        if (device->m_handles.contains(0xF1D0) && device->m_handles.contains(0xFFA0)) {
#if 0
            io_service_t service = IOHIDDeviceGetService(handle);
            qDebug() << service;
            IOCFPlugInInterface**   plugInInterface = NULL;
            SInt32					score = 0;
            IOReturn ret = IOCreatePlugInInterfaceForService(service, kIOHIDDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
            qDebug() <<  ret << score << plugInInterface;
            HRESULT plugInResult = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID) &hidDeviceInterface);
#endif

            //ioReturnValue = IOCreatePlugInInterfaceForService(hidDevice, kIOHIDDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
            //    if (ioReturnValue == kIOReturnSuccess)
#if 0
            auto xx = hid_open(0x2C97, 0x0004, nullptr);

            while (true) {
                int r = hid_write(xx, (const unsigned char*)xxx.constData(), 64);
                qDebug() << "WRITE" << r;
                memset(buf, 0, 64);
                r = hid_read_timeout(xx, buf, 64, 1);
                qDebug() << "READ" << r;
                if (r == 64) break;
            }
            qDebug() << QByteArray((const char*)buf, 64).toHex();
            QByteArray yy((const char*)buf, 64);
            ParseGetApplicationResponse(yy);
#endif
//            auto x = IOHIDDeviceOpen(device->m_handles.value(0xFFA0), kIOHIDOptionsTypeSeizeDevice);
//            qDebug() << (x == kIOReturnSuccess);
//            IOHIDDeviceRegisterInputReportCallback(device->m_handles.value(0xFFA0), buf, 64, hid_report_callback, manager);
//            AskApplicationId(device->m_handles.value(0xFFA0));
        }
#endif

        device->propertiesChanged();
#endif
        return;
    }

    if (DeviceMatchesVendorAndProduct(handle, 0x1209, 0x53c1)) {
        qDebug("Hello Trezor Model T");
    }
}


static void DeviceRemovalCallback(void* context, IOReturn /* result */, void* sender, IOHIDDeviceRef handle)
{
    auto manager = static_cast<DeviceManagerMacos*>(context);

    // TODO use IOHIDDeviceConformsTo
    // Ledger Nano X
    if (DeviceMatchesVendorAndProduct(handle, 0x2C97, 0x0004)) {
        int32_t usage_page = DeviceGetPropertyInt32(handle, CFSTR(kIOHIDPrimaryUsagePageKey));
        if (usage_page == 0xF1D0) return;
        qDebug() << "LEDGER NANO X disconnected";
        manager->m_queues.remove(handle);

#if 0
        DeviceMacOs* device = manager->deviceWithHandle(usage_page, handle);
        if (!device) return;

        device->m_handles.remove(usage_page);

        qDebug() << "HANDLE COUNT" << device->m_handles.size();

        if (usage_page == 0xffA0) {
            //IOHIDDeviceClose(handle, kIOHIDOptionsTypeSeizeDevice);
            //IOHIDDeviceRegisterInputReportCallback(handle, buffer, 64, nullptr, nullptr);

            //IOHIDDeviceRegisterInputReportCallback(device->m_handles.value(0xffA0), buffer, 64, hid_report_callback, nullptr);
            //IOHIDDeviceRegisterInputReportCallback(handle, buffer, 64, nullptr, nullptr);
            //IOHIDDeviceUnscheduleFromRunLoop(handle, CFRunLoopGetMain(), kCFRunLoopDefaultMode);

            device->m_properties.insert("connected", false);

            QTimer::singleShot(2000, manager, [device, manager] {
                if (!device->m_properties.value("connected").toBool()) {
                    manager->removeDevice(device);
                    delete device;
                }
            });
        } else {
            device->m_properties.insert("app", false);
        }
        device->propertiesChanged();
#endif
    }
}

DeviceManager* DeviceManager::instance()
{
    static DeviceManagerMacos device_manager;
    return &device_manager;
}

DeviceManagerMacos::DeviceManagerMacos()
{
    m_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone);
    IOHIDManagerSetDeviceMatching(m_manager, NULL);
    IOHIDManagerRegisterDeviceMatchingCallback(m_manager, DeviceMatchingCallback, this);
    IOHIDManagerRegisterDeviceRemovalCallback(m_manager, DeviceRemovalCallback, this);
    IOHIDManagerScheduleWithRunLoop(m_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDManagerOpen(m_manager, kIOHIDOptionsTypeSeizeDevice);
    IOHIDManagerRegisterInputReportCallback(m_manager, hid_report_callback, this);


    //01010500000005b00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

    // Create a discovery agent and connect to its signals
//connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered, this, [this](QBluetoothDeviceInfo info) {
//    qDebug() << "BT DEVICE" << info.name();
//    if (info.name() != "Nano X 37FC") return;
//    auto serviceAgent = new QBluetoothServiceDiscoveryAgent(info.address(), this);
//    connect(serviceAgent, &QBluetoothServiceDiscoveryAgent::serviceDiscovered, [](const QBluetoothServiceInfo &info) {
//       qDebug() << "BT SERVICE" << info.device().name() << info.serviceName();
//    });
//    serviceAgent->start(QBluetoothServiceDiscoveryAgent::FullDiscovery);
//    new QBluetoothSocket()
//});
//discoveryAgent->start();
//
//    auto serviceAgent = new QBluetoothServiceDiscoveryAgent(this);
//    serviceAgent->setUuidFilter(QBluetoothUuid(QString("13D63400-2C97-0004-0000-4C6564676572")));
//    connect(serviceAgent, &QBluetoothServiceDiscoveryAgent::serviceDiscovered, [](const QBluetoothServiceInfo &info) {
//        qDebug() << info.device().name();
//    });
////    connect(serviceAgent, &QBluetoothServiceDiscoveryAgent::error, [](QBluetoothServiceDiscoveryAgent::Error error) {
////        qDebug() << "ERRPOR..." << error;
////    });
//    connect(serviceAgent, &QBluetoothServiceDiscoveryAgent::finished, [] {
//        qDebug() << "FINSIHED.";
//    });
//    serviceAgent->start();

}

DeviceManagerMacos::~DeviceManagerMacos()
{
    IOHIDManagerClose(m_manager, kIOHIDOptionsTypeNone);
}

DeviceMacOs* DeviceManagerMacos::deviceWithHandle(int32_t usage_page, IOHIDDeviceRef handle) const
{
//    for (auto dev : m_devices) {
//        auto device = static_cast<DeviceMacOs*>(dev);
//        if (device->m_handles.value(usage_page) == handle) {
//            return device;
//        }
//    }
    return nullptr;
}

void DeviceManagerMacos::addDevice(Device* device)
{
    m_devices.append(device);
    emit devicesChanged();
}

void DeviceManagerMacos::removeDevice(Device* device)
{
    m_devices.removeOne(device);
    emit devicesChanged();
}

bool DeviceManagerMacos::exchange(IOHIDDeviceRef device, Command *command)
{
    Q_ASSERT(QThread::currentThread() == thread());
    const bool send = m_queues[device].empty();
    if (send) {
        const auto payload = command->payload();
        qDebug() << "send " << payload.toHex();
        auto res = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, (const uint8_t*) payload.constData(), payload.size());
        if (res != kIOReturnSuccess) {
            qDebug() << "FAILED";
            delete command;
            return false;
        }
    }
    m_queues[device].enqueue(command);
    return true;
}

void DeviceManagerMacos::readHIDReport(IOHIDDeviceRef device, const QByteArray &data)
{
    //qDebug() << "read hid" << data.toHex();
    QDataStream stream(data);
    auto command = m_queues[device].head();
    int r = command->readHIDReport(stream);

    if (r == 2) return;
    if (r == 1) qWarning("command failed");

    m_queues[device].dequeue();
    if (!m_queues[device].empty()) {
        command = m_queues[device].head();
        const auto payload = command->payload();
        //qDebug() << "WRITE AFTER READ LAST\n" << payload.toHex();
        auto res = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, (const uint8_t*) payload.constData(), payload.size());
        Q_ASSERT(res == kIOReturnSuccess);
    }
}
