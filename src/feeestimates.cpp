#include "session.h"
#include "feeestimates.h"
#include "ga.h"
#include "session.h"

FeeEstimates::FeeEstimates(QObject* parent)
    : QObject(parent)
{
    connect(&m_update_timer, &QTimer::timeout, this, &FeeEstimates::update);
}

void FeeEstimates::setSession(Session* session)
{
    if (m_session == session) return;
    m_session = session;
    emit sessionChanged();
    if (m_session) {
        update();
        m_update_timer.start(60 * 1000);
    } else {
        m_update_timer.stop();
    }
}

void FeeEstimates::update()
{
    if (!m_session) return;
    const auto fees = gdk::get_fee_estimates(m_session->m_session);
    if (m_fees == fees) return;
    m_fees = fees;
    emit feesChanged();
}
