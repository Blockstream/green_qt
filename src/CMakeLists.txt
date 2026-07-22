add_subdirectory(core)
target_link_libraries(${APP_TARGET} PRIVATE blockstream_core)

target_sources(${APP_TARGET} PRIVATE
    main.cpp
    application.h application.cpp
    applicationcontroller.h applicationcontroller.cpp
    context.h context.cpp
    contextmodel.h contextmodel.cpp
    limitmodel.h limitmodel.cpp
    green.h
    green_settings.h green_settings.cpp
)

target_sources(${APP_TARGET} PRIVATE
    account.h account.cpp
    activity.h activity.cpp
    progress.h progress.cpp
    asset.h asset.cpp
    address.h address.cpp
    connectable.h
    network.h network.cpp
    output.h output.cpp
    payment.h payment.cpp
    session.h session.cpp
    transaction.h transaction.cpp
    wallet.h wallet.cpp
)

target_sources(${APP_TARGET} PRIVATE
    accountcontroller.h accountcontroller.cpp
    controller.h controller.cpp
    createaccountcontroller.h createaccountcontroller.cpp
    loginwithpincontroller.h loginwithpincontroller.cpp
    logging.h logging.cpp
    restorecontroller.h restorecontroller.cpp
    signupcontroller.h signupcontroller.cpp
    watchonlylogincontroller.h watchonlylogincontroller.cpp
    controllers/createpsetcontroller.h controllers/createpsetcontroller.cpp
    controllers/amp2signcontroller.h controllers/amp2signcontroller.cpp
    controllers/lwkamp2accountcontroller.h controllers/lwkamp2accountcontroller.cpp
    controllers/bcurcontroller.h controllers/bcurcontroller.cpp
    controllers/receiveaddresscontroller.h controllers/receiveaddresscontroller.cpp
    controllers/sessioncontroller.h controllers/sessioncontroller.cpp
    controllers/signmessagecontroller.h controllers/signmessagecontroller.cpp
    controllers/twofactorcontroller.h controllers/twofactorcontroller.cpp
    controllers/watchonlycontroller.h controllers/watchonlycontroller.cpp
    recipient.h recipient.cpp
    createtransactioncontroller.h createtransactioncontroller.cpp
    signtransactioncontroller.h signtransactioncontroller.cpp
    airgappedsigncontroller.h airgappedsigncontroller.cpp
    redepositcontroller.h redepositcontroller.cpp
    jadeverifyaddresscontroller.h jadeverifyaddresscontroller.cpp
    requestsupportcontroller.h requestsupportcontroller.cpp
    invoicecontroller.h invoicecontroller.cpp
    submarinecontroller.h submarinecontroller.cpp
    swapquotecontroller.h swapquotecontroller.cpp
    chainswapcontroller.h chainswapcontroller.cpp
)

target_sources(${APP_TARGET} PRIVATE
    appupdatecontroller.h appupdatecontroller.cpp
    ga.h ga.cpp
    httpmanager.h httpmanager.cpp
    httprequestactivity.h httprequestactivity.cpp
    activitymanager.h activitymanager.cpp
    analytics.h analytics.cpp
    buybitcoinquoteservice.h buybitcoinquoteservice.cpp
    chartpriceservice.h chartpriceservice.cpp
    feeestimates.h feeestimates.cpp
    networkmanager.h networkmanager.cpp
    breakpad.cpp
    notification.h notification.cpp
    promo.h promo.cpp
)

target_sources(${APP_TARGET} PRIVATE
    clipboard.h clipboard.cpp
    convert.h convert.cpp
    json.h json.cpp
    command.h command.cpp
    task.h task.cpp
    zxing.h zxing.cpp
    signmessageresolver.h signmessageresolver.cpp
    resolver.h resolver.cpp
    paymentparser.h paymentparser.cpp
    swap.h swap.cpp
)

target_sources(${APP_TARGET} PRIVATE
    device.h device_p.h device.cpp
    deviceactivities.h deviceactivities.cpp
    devicesession.h devicesession.cpp
    devicediscoveryagent.h devicediscoveryagent.cpp
    devicediscoveryagent_linux.h devicediscoveryagent_linux.cpp
    devicediscoveryagent_macos.h devicediscoveryagent_macos.cpp
    devicediscoveryagent_win.h devicediscoveryagent_win.cpp
    devicelistmodel.h devicelistmodel.cpp
    devicemanager.h devicemanager.cpp
    jade/jadeconnection.h jade/jadeconnection.cpp
    jade/jadebleimpl.h jade/jadebleimpl.cpp
    jade/jadeserialimpl.h jade/jadeserialimpl.cpp
    jade/serviceinfo.h jade/serviceinfo.cpp
    jade/jadeupdatecontroller.h jade/jadeupdatecontroller.cpp
    jade/jadedevice.h jade/jadedevice.cpp
    jade/jadedeviceserialportdiscoveryagent.h jade/jadedeviceserialportdiscoveryagent.cpp
    jade/jadelogincontroller.h jade/jadelogincontroller.cpp
    jade/jadeapi.h jade/jadeapi.cpp
    jade/deviceinfo.h jade/deviceinfo.cpp
)

target_sources(${APP_TARGET} PRIVATE
    ledger/ledgerdevice.h ledger/ledgerdevice.cpp
    ledger/ledgergetblindingkeyactivity.h ledger/ledgergetblindingkeyactivity.cpp
    ledger/ledgergetblindingnonceactivity.h ledger/ledgergetblindingnonceactivity.cpp
    ledger/ledgergetwalletpublickeyactivity.h ledger/ledgergetwalletpublickeyactivity.cpp
    ledger/ledgersignliquidtransactionactivity.h ledger/ledgersignliquidtransactionactivity.cpp
    ledger/ledgersignmessageactivity.h ledger/ledgersignmessageactivity.cpp
    ledger/ledgersigntransactionactivity.h ledger/ledgersigntransactionactivity.cpp
)

target_sources(${APP_TARGET} PRIVATE
    lwk/lwk.cpp
    lwk/lwk.hpp
    lwk/lwk_scaffolding.hpp
    boltzcreatesessiontask.h boltzcreatesessiontask.cpp
    boltzloadswapstask.h boltzloadswapstask.cpp
)

target_sources(${APP_TARGET} PRIVATE
    glsdk/glsdk.cpp
    glsdk/glsdk.hpp
    glsdk/glsdk_scaffolding.hpp
)

target_sources(${APP_TARGET} PRIVATE
    lightning/lightningclient.cpp lightning/lightningclient.h
    lightning/lightningenablecontroller.cpp lightning/lightningenablecontroller.h
    lightning/lightningreceivecontroller.h lightning/lightningreceivecontroller.cpp
    lightning/lightningsendcontroller.h lightning/lightningsendcontroller.cpp
    lightning/lightningsession.cpp lightning/lightningsession.h
    lightning/lightningtask.h lightning/lightningtask.cpp
    lightning/lightningutil.h
)

target_sources(${APP_TARGET} PRIVATE
    outputlistmodel.h outputlistmodel.cpp
    outputlistmodelfilter.h outputlistmodelfilter.cpp
    walletlistmodel.h walletlistmodel.cpp
    walletmanager.h walletmanager.cpp
    sessionmanager.h sessionmanager.cpp
    wally.h wally.cpp
)

if(UNIX AND NOT APPLE AND NOT WIN32)
    target_sources(${APP_TARGET} PRIVATE glibc_compat.cpp)
endif()
