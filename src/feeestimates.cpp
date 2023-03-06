#include "feeestimates.h"
#include "ga.h"
#include "wallet.h"

FeeEstimates::FeeEstimates(QObject* parent) :
    QObject(parent)
{
    connect(&m_update_timer, &QTimer::timeout, this, &FeeEstimates::update);
}

void FeeEstimates::setWallet(Wallet* wallet)
{
    if (!m_wallet.update(wallet)) return;
    if (m_wallet) {
        update();
        m_update_timer.start(120000);
    } else {
        m_update_timer.stop();
    }
}

void FeeEstimates::update()
{
    if (!m_wallet->session()) return;
    const auto fees = gdk::get_fee_estimates(m_wallet->session()->m_session);
    if (fees.isEmpty() || m_fees == fees) return;
    m_fees = fees;
    emit feesChanged(m_fees);
}
