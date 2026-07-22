#include "convert.h"
#include "recipient.h"

Recipient::Recipient(QObject* parent)
    : QObject(parent)
    , m_convert(new Convert(this))
{
    connect(m_convert, &Convert::resultChanged, this, &Recipient::changed);
}

void Recipient::setAddress(const QString& address)
{
    if (m_address == address) return;
    m_address = address;
    emit addressChanged();
    emit changed();
}

void Recipient::setGreedy(bool greedy)
{
    if (m_greedy == greedy) return;
    m_greedy = greedy;
    emit greedyChanged();
    emit changed();
}
