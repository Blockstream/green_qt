#include "devicesession.h"

#include "device.h"

DeviceSession::DeviceSession(const QString& xpub_hash_id, Device* device)
    : QObject(device)
    , m_device(device)
    , m_xpub_hash_id(xpub_hash_id)
{
}
