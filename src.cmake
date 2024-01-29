SET(TARGET_SOURCES
	src/account.cpp
	src/accountcontroller.cpp
	src/accountlistmodel.cpp
	src/activity.cpp
	src/activitymanager.cpp
	src/address.cpp
	src/addresslistmodel.cpp
	src/analytics.cpp
	src/appupdatecontroller.cpp
	src/asset.cpp
	src/balance.cpp
	src/blogcontroller.cpp
	src/clipboard.cpp
	src/command.cpp
        src/context.cpp
        src/context.h
	src/controller.cpp
	src/controller.h
	src/convert.cpp
	src/convert.h
	src/createaccountcontroller.cpp
	src/device.cpp
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
	src/loader2.cpp
	src/loginwithpincontroller.cpp
	src/main.cpp
	src/navigation.cpp
	src/network.cpp
	src/networkmanager.cpp
	src/output.cpp
	src/outputlistmodel.cpp
	src/outputlistmodelfilter.cpp
	src/resolver.cpp
	src/restorecontroller.h src/restorecontroller.cpp
	src/session.h src/session.cpp
	src/settings.h src/settings.cpp
	src/signmessageresolver.cpp
	src/signupcontroller.cpp
	src/signupcontroller.h
	src/transaction.cpp
	src/transactionlistmodel.cpp
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
	src/controllers/ledgerdevicecontroller.cpp
	src/controllers/sendcontroller.cpp
	src/controllers/bumpfeecontroller.cpp
	src/controllers/exporttransactionscontroller.cpp
	src/controllers/exportaddressescontroller.cpp
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
  sa/kdsingleapplication.cpp
  sa/kdsingleapplication_localsocket.cpp
	src/task.h src/task.cpp
	src/createtransactioncontroller.h src/createtransactioncontroller.cpp
	src/signtransactioncontroller.h src/signtransactioncontroller.cpp
        src/notification.h src/notification.cpp
        src/application.h src/application.cpp
)

if (WIN32)
elseif (APPLE)
elseif (UNIX)
list(APPEND TARGET_SOURCES src/glibc_compat.cpp)
endif()
