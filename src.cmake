SET(TARGET_SOURCES
	src/account.cpp
	src/accountcontroller.cpp
	src/activity.h src/activity.cpp
	src/progress.h src/progress.cpp
	src/activitymanager.cpp
	src/address.cpp
	src/analytics.cpp
	src/appupdatecontroller.cpp
	src/asset.cpp
	src/clipboard.cpp
	src/command.cpp
        src/context.cpp
        src/context.h
	src/controllers/abstractcontroller.h src/controllers/abstractcontroller.cpp
	src/controller.h src/controller.cpp
	src/controllers/sessioncontroller.h src/controllers/sessioncontroller.cpp
	src/controllers/watchonlycontroller.h src/controllers/watchonlycontroller.cpp
	src/controllers/twofactorcontroller.h src/controllers/twofactorcontroller.cpp
	src/controllers/signmessagecontroller.h src/controllers/signmessagecontroller.cpp
	src/controllers/bcurcontroller.h src/controllers/bcurcontroller.cpp
	src/convert.cpp
	src/convert.h
	src/createaccountcontroller.cpp
	src/device.h src/device.cpp
	src/deviceactivities.h src/deviceactivities.cpp
	src/devicesession.h src/devicesession.cpp
	src/devicediscoveryagent.cpp
	src/devicediscoveryagent_linux.cpp
	src/devicediscoveryagent_macos.cpp
	src/devicediscoveryagent_win.cpp
	src/devicelistmodel.cpp
	src/devicemanager.cpp
	src/entity.cpp
	src/feeestimates.cpp
	src/ga.cpp
        src/green.h
	src/httpmanager.cpp
	src/httprequestactivity.cpp
	src/json.cpp
	src/loginwithpincontroller.cpp
	src/main.cpp
	src/network.cpp
	src/networkmanager.cpp
	src/output.cpp
	src/outputlistmodel.cpp
	src/outputlistmodelfilter.cpp
	src/resolver.cpp
	src/restorecontroller.h src/restorecontroller.cpp
	src/session.h src/session.cpp
	src/sessionmanager.h src/sessionmanager.cpp
        src/green_settings.h src/green_settings.cpp
	src/signmessageresolver.cpp
	src/signupcontroller.cpp
	src/signupcontroller.h
	src/transaction.cpp
	src/util.cpp
	src/wallet.cpp
	src/walletlistmodel.cpp
	src/walletmanager.cpp
	src/wally.cpp
	src/watchonlylogincontroller.cpp
        src/ledger/ledgerdevice.cpp
	src/ledger/ledgergetblindingkeyactivity.cpp
	src/ledger/ledgergetblindingnonceactivity.cpp
	src/ledger/ledgergetwalletpublickeyactivity.cpp
	src/ledger/ledgersignliquidtransactionactivity.cpp
	src/ledger/ledgersignmessageactivity.cpp
	src/ledger/ledgersigntransactionactivity.cpp
	src/controllers/receiveaddresscontroller.cpp
	src/jade/jadeconnection.cpp
	src/jade/jadebleimpl.cpp
	src/jade/jadeserialimpl.cpp
	src/jade/serviceinfo.cpp
	src/jade/jadeupdatecontroller.cpp
	src/jade/jadedevice.cpp
	src/jade/jadedeviceserialportdiscoveryagent.cpp
	src/jade/jadelogincontroller.cpp
	src/jade/jadeapi.cpp
	src/jade/deviceinfo.cpp
	src/task.h src/task.cpp
	src/createtransactioncontroller.h src/createtransactioncontroller.cpp
	src/signtransactioncontroller.h src/signtransactioncontroller.cpp
        src/notification.h src/notification.cpp
        src/application.h src/application.cpp
        src/applicationcontroller.h src/applicationcontroller.cpp
        src/zxing.h src/zxing.cpp
        src/redepositcontroller.h src/redepositcontroller.cpp
        src/jadeverifyaddresscontroller.h src/jadeverifyaddresscontroller.cpp
        src/promo.h src/promo.cpp
        src/requestsupportcontroller.h src/requestsupportcontroller.cpp
        src/breakpad.cpp
        src/chartpriceservice.h src/chartpriceservice.cpp
        src/buybitcoinquoteservice.h src/buybitcoinquoteservice.cpp
        src/payment.h src/payment.cpp
)

if (WIN32)
elseif (APPLE)
elseif (UNIX)
list(APPEND TARGET_SOURCES src/glibc_compat.cpp)
endif()
