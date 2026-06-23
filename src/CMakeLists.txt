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
    account.cpp
    activity.h activity.cpp
    progress.h progress.cpp
    asset.cpp
    address.cpp
    entity.cpp
    network.cpp
    output.cpp
    payment.h payment.cpp
    session.h session.cpp
    transaction.cpp
    wallet.cpp
)

target_sources(${APP_TARGET} PRIVATE
    accountcontroller.cpp
    controller.h controller.cpp
    createaccountcontroller.cpp
    loginwithpincontroller.cpp
    logging.h logging.cpp
    restorecontroller.h restorecontroller.cpp
    signupcontroller.h signupcontroller.cpp
    watchonlylogincontroller.cpp
    controllers/abstractcontroller.h controllers/abstractcontroller.cpp
    controllers/bcurcontroller.h controllers/bcurcontroller.cpp
    controllers/receiveaddresscontroller.cpp
    controllers/sessioncontroller.h controllers/sessioncontroller.cpp
    controllers/signmessagecontroller.h controllers/signmessagecontroller.cpp
    controllers/twofactorcontroller.h controllers/twofactorcontroller.cpp
    controllers/watchonlycontroller.h controllers/watchonlycontroller.cpp
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
    appupdatecontroller.cpp
    ga.cpp
    httpmanager.cpp
    httprequestactivity.cpp
    activitymanager.cpp
    analytics.cpp
    buybitcoinquoteservice.h buybitcoinquoteservice.cpp
    chartpriceservice.h chartpriceservice.cpp
    feeestimates.cpp
    networkmanager.cpp
    breakpad.cpp
    notification.h notification.cpp
    promo.h promo.cpp
)

target_sources(${APP_TARGET} PRIVATE
    clipboard.cpp
    convert.h convert.cpp
    json.cpp
    command.cpp
    task.h task.cpp
    zxing.h zxing.cpp
    signmessageresolver.cpp
    resolver.cpp
    paymentparser.h paymentparser.cpp
    swap.h swap.cpp
)

target_sources(${APP_TARGET} PRIVATE
    device.h device.cpp
    deviceactivities.h deviceactivities.cpp
    devicesession.h devicesession.cpp
    devicediscoveryagent.cpp
    devicediscoveryagent_linux.cpp
    devicediscoveryagent_macos.cpp
    devicediscoveryagent_win.cpp
    devicelistmodel.cpp
    devicemanager.cpp
    jade/jadeconnection.cpp
    jade/jadebleimpl.cpp
    jade/jadeserialimpl.cpp
    jade/serviceinfo.cpp
    jade/jadeupdatecontroller.cpp
    jade/jadedevice.cpp
    jade/jadedeviceserialportdiscoveryagent.cpp
    jade/jadelogincontroller.cpp
    jade/jadeapi.cpp
    jade/deviceinfo.cpp
)

target_sources(${APP_TARGET} PRIVATE
    ledger/ledgerdevice.cpp
    ledger/ledgergetblindingkeyactivity.cpp
    ledger/ledgergetblindingnonceactivity.cpp
    ledger/ledgergetwalletpublickeyactivity.cpp
    ledger/ledgersignliquidtransactionactivity.cpp
    ledger/ledgersignmessageactivity.cpp
    ledger/ledgersigntransactionactivity.cpp
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
    lightning/lightningcontroller.cpp lightning/lightningcontroller.h
    lightning/lightningsession.cpp lightning/lightningsession.h
    lightning/lightningtask.h lightning/lightningtask.cpp
)

target_sources(${APP_TARGET} PRIVATE
    outputlistmodel.cpp
    outputlistmodelfilter.cpp
    walletlistmodel.cpp
    walletmanager.cpp
    sessionmanager.h sessionmanager.cpp
    wally.cpp
)

if(UNIX AND NOT APPLE AND NOT WIN32)
    target_sources(${APP_TARGET} PRIVATE glibc_compat.cpp)
endif()
