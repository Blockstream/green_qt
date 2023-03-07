#include "context.h"
#include "feeestimates.h"
#include "ga.h"
#include "session.h"
#include "wallet.h"

FeeEstimates::FeeEstimates(QObject* parent) :
    QObject(parent)
{
    connect(&m_update_timer, &QTimer::timeout, this, &FeeEstimates::update);
}

void FeeEstimates::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
    if (m_context) {
        update();
        m_update_timer.start(120000);
    } else {
        m_update_timer.stop();
    }
}

void FeeEstimates::update()
{
    if (!m_context || !m_context->session()) return;
    const auto fees = gdk::get_fee_estimates(m_context->session()->m_session);
    if (fees.isEmpty() || m_fees == fees) return;
    m_fees = fees;
    emit feesChanged();
}
