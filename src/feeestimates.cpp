#include "account.h"
#include "feeestimates.h"
#include "ga.h"
#include "session.h"

FeeEstimates::FeeEstimates(QObject* parent) :
    QObject(parent)
{
    connect(&m_update_timer, &QTimer::timeout, this, &FeeEstimates::update);
}

void FeeEstimates::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    if (m_account) {
        update();
        m_update_timer.start(120000);
    } else {
        m_update_timer.stop();
    }
}

void FeeEstimates::update()
{
    if (!m_account) return;
    const auto session = m_account->session();
    const auto fees = gdk::get_fee_estimates(session->m_session);
    if (fees.isEmpty() || m_fees == fees) return;
    m_fees = fees;
    emit feesChanged();
}
