#include "jadebluetoothpairing_win.h"

#ifdef Q_OS_WIN

#include <QDebug>
#include <QThread>
#include <QTimer>

#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Foundation.h>

#include <mutex>
#include <thread>
#include <utility>

using namespace winrt::Windows::Devices::Bluetooth;
using namespace winrt::Windows::Devices::Enumeration;
using namespace winrt::Windows::Foundation;

static QString errorText(const winrt::hresult_error& error)
{
    return QString::fromWCharArray(error.message().c_str());
}

// WinRT completes on its own threads, and may do so after the QObject is gone,
// so the state is shared with the callbacks and everything is handed back to
// the object's thread before a signal goes out. The callbacks log directly, so
// the log tells what Windows did even if nothing reaches the object.
struct JadeBluetoothPairing::Private : std::enable_shared_from_this<Private>
{
    std::mutex mutex;
    // Guarded by mutex, cleared by the destructor before the object goes.
    JadeBluetoothPairing* q{nullptr};
    quint64 address{0};
    bool cancelled{false};
    IAsyncOperation<BluetoothLEDevice> lookup{nullptr};
    DeviceInformationCustomPairing pairing{nullptr};
    winrt::event_token token;
    IAsyncOperation<DevicePairingResult> operation{nullptr};
    DevicePairingRequestedEventArgs args{nullptr};
    Deferral deferral{nullptr};

    template <typename F>
    void post(F f)
    {
        std::lock_guard lock(mutex);
        if (!q) return;
        // Delivered to q, so it only runs while q is alive.
        QMetaObject::invokeMethod(q, [self = shared_from_this(), f = std::move(f)] {
            f();
        }, Qt::QueuedConnection);
    }

    void finish(bool paired, const QString& reason = {})
    {
        post([this, paired, reason] {
            if (paired) {
                qDebug() << "JadeBluetoothPairing: paired";
            } else {
                qWarning() << "JadeBluetoothPairing: pairing failed:" << reason;
            }
            emit q->finished(paired);
        });
    }

    void start()
    {
        auto self = shared_from_this();
        qDebug() << "JadeBluetoothPairing: pairing" << QString::number(address, 16) << "thread" << QThread::currentThreadId();
        try {
            auto lookupOperation = BluetoothLEDevice::FromBluetoothAddressAsync(address);
            {
                std::lock_guard lock(mutex);
                lookup = lookupOperation;
            }
            lookupOperation.Completed([self](const IAsyncOperation<BluetoothLEDevice>& op, AsyncStatus status) {
                bool cancelled;
                {
                    std::lock_guard lock(self->mutex);
                    self->lookup = nullptr;
                    cancelled = self->cancelled;
                }
                if (cancelled) return self->finish(false, "cancelled");
                BluetoothLEDevice device{nullptr};
                if (status == AsyncStatus::Completed) device = op.GetResults();
                qDebug() << "JadeBluetoothPairing: device lookup status" << int(status) << "found" << bool(device) << "thread" << QThread::currentThreadId();
                if (!device) return self->finish(false, "device not found");
                self->pair(device);
            });
        } catch (const winrt::hresult_error& error) {
            finish(false, errorText(error));
        }
    }

    void pair(const BluetoothLEDevice& device)
    {
        auto self = shared_from_this();
        bool cancelled;
        {
            std::lock_guard lock(mutex);
            cancelled = this->cancelled;
        }
        if (cancelled) return finish(false, "cancelled");
        try {
            auto custom = device.DeviceInformation().Pairing().Custom();
            auto requestedToken = custom.PairingRequested([self](const DeviceInformationCustomPairing&, const DevicePairingRequestedEventArgs& args) {
                self->requested(args);
            });
            {
                std::lock_guard lock(mutex);
                pairing = custom;
                token = requestedToken;
            }
            // Only the code comparison: Jade requires MITM protection, so any other
            // ceremony means a downgrade or a different device, and it is refused.
            // The protection level is left to Windows, as Settings and Qt do.
            auto pairOperation = custom.PairAsync(DevicePairingKinds::ConfirmPinMatch);
            bool cancelNow;
            {
                std::lock_guard lock(mutex);
                operation = pairOperation;
                cancelNow = this->cancelled;
            }
            // cancel() may have run while PairAsync was being started.
            if (cancelNow) pairOperation.Cancel();
            pairOperation.Completed([self](const IAsyncOperation<DevicePairingResult>& op, AsyncStatus status) {
                DeviceInformationCustomPairing pairing{nullptr};
                winrt::event_token token;
                {
                    std::lock_guard lock(self->mutex);
                    pairing = std::exchange(self->pairing, nullptr);
                    token = self->token;
                }
                if (pairing) pairing.PairingRequested(token);
                if (status != AsyncStatus::Completed) {
                    qWarning() << "JadeBluetoothPairing: PairAsync ended with async status" << int(status) << "error" << QString::number(uint32_t(op.ErrorCode()), 16) << "thread" << QThread::currentThreadId();
                    return self->finish(false, QString("async status %1").arg(int(status)));
                }
                const auto result = op.GetResults();
                qDebug() << "JadeBluetoothPairing: PairAsync completed, result status" << int(result.Status()) << "protection level" << int(result.ProtectionLevelUsed()) << "thread" << QThread::currentThreadId();
                if (result.Status() != DevicePairingResultStatus::Paired) return self->finish(false, QString("result status %1").arg(int(result.Status())));
                self->finish(true);
            });
        } catch (const winrt::hresult_error& error) {
            finish(false, errorText(error));
        }
    }

    void requested(const DevicePairingRequestedEventArgs& args)
    {
        qDebug() << "JadeBluetoothPairing: pairing requested, kind" << int(args.PairingKind()) << "thread" << QThread::currentThreadId();
        // Not accepted, so the pairing fails.
        if (args.PairingKind() != DevicePairingKinds::ConfirmPinMatch) {
            qWarning() << "JadeBluetoothPairing: refusing pairing kind" << int(args.PairingKind());
            return;
        }
        {
            std::lock_guard lock(mutex);
            // Not accepted either, so nobody is left holding the code prompt.
            if (cancelled) return;
            deferral = args.GetDeferral();
            this->args = args;
        }
        const auto pin = QString::fromWCharArray(args.Pin().c_str());
        post([this, pin] {
            qDebug() << "JadeBluetoothPairing: code to confirm" << pin;
            emit q->pinRequested(pin);
        });
    }

    void cancel()
    {
        IAsyncOperation<BluetoothLEDevice> lookup{nullptr};
        IAsyncOperation<DevicePairingResult> operation{nullptr};
        {
            std::lock_guard lock(mutex);
            cancelled = true;
            lookup = this->lookup;
            operation = this->operation;
        }
        try {
            if (lookup) lookup.Cancel();
            if (operation) {
                qDebug() << "JadeBluetoothPairing: cancelling, status" << int(operation.Status());
                operation.Cancel();
            }
        } catch (const winrt::hresult_error& error) {
            qWarning() << "JadeBluetoothPairing: cancelling failed:" << errorText(error);
        }
    }
};

JadeBluetoothPairing::JadeBluetoothPairing(const QBluetoothAddress& address, QObject* parent)
    : QObject(parent)
    , d(std::make_shared<Private>())
{
    d->q = this;
    d->address = address.toUInt64();
}

JadeBluetoothPairing::~JadeBluetoothPairing()
{
    {
        std::lock_guard lock(d->mutex);
        d->q = nullptr;
    }
    d->cancel();
    confirmPin(false);
}

void JadeBluetoothPairing::start()
{
    d->start();
    // Windows keeps a pairing pending while the other side never answers, and
    // has been seen taking a couple of minutes on its own.
    QTimer::singleShot(180000, this, [this] {
        qWarning() << "JadeBluetoothPairing: timed out";
        d->cancel();
    });
}

void JadeBluetoothPairing::confirmPin(bool match)
{
    Deferral deferral{nullptr};
    DevicePairingRequestedEventArgs args{nullptr};
    {
        std::lock_guard lock(d->mutex);
        std::swap(deferral, d->deferral);
        std::swap(args, d->args);
    }
    if (deferral) {
        qDebug() << "JadeBluetoothPairing: code confirmed" << match << "thread" << QThread::currentThreadId();
        try {
            if (match) {
                args.Accept();
                qDebug() << "JadeBluetoothPairing: accepted";
            }
        } catch (const winrt::hresult_error& error) {
            qWarning() << "JadeBluetoothPairing: confirming failed:" << errorText(error);
        }
        // The deferral has to be completed from an MTA thread. Done from this
        // STA thread, the Device Association Service hangs and the pairing
        // never finishes, as Chromium notes in bluetooth_pairing_winrt.cc.
        std::thread([deferral = std::move(deferral)] {
            try {
                winrt::init_apartment(winrt::apartment_type::multi_threaded);
                deferral.Complete();
                qDebug() << "JadeBluetoothPairing: deferral completed, thread" << QThread::currentThreadId();
            } catch (const winrt::hresult_error& error) {
                qWarning() << "JadeBluetoothPairing: completing the deferral failed:" << errorText(error);
            }
        }).detach();
    }
    if (!match) d->cancel();
}

#endif // Q_OS_WIN
