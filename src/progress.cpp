#include "progress.h"

Progress::Progress(QObject* parent)
    : QObject(parent)
{
}

void Progress::setFrom(qreal from)
{
    if (m_from == from) return;
    m_from = from;
    emit fromChanged(m_from);
}

void Progress::setTo(qreal to)
{
    if (m_to == to) return;
    m_to = to;
    emit toChanged(m_to);
}

void Progress::setValue(qreal value)
{
    if (m_value == value) return;
    m_value = value;
    emit valueChanged(m_value);
}

void Progress::setIndeterminate(bool indeterminate)
{
    if (m_indeterminate == indeterminate) return;
    m_indeterminate = indeterminate;
    emit indeterminateChanged(m_indeterminate);
}

void Progress::incrementValue(int inc)
{
    setValue(value() + inc);
}
