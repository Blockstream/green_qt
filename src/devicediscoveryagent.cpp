#include "device.h"
#include "devicediscoveryagent.h"
#include "devicediscoveryagent_macos.h"
#include "devicediscoveryagent_linux.h"
#include "devicediscoveryagent_win.h"
#include "devicemanager.h"

DeviceDiscoveryAgent::DeviceDiscoveryAgent(QObject *parent)
    : QObject(parent)
    , d(new DeviceDiscoveryAgentPrivate(this))
{
}

DeviceDiscoveryAgent::~DeviceDiscoveryAgent()
{
    delete d;
}
