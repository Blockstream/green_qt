target_sources(${APP_TARGET} PRIVATE
    account.h account.cpp
    address.h address.cpp
    asset.h asset.cpp
    context.h context.cpp
    contextmodel.h contextmodel.cpp
    limitmodel.h limitmodel.cpp
    output.h output.cpp
    transaction.h transaction.cpp
    wallet.h wallet.cpp
    walletlistmodel.h walletlistmodel.cpp
    walletmanager.h walletmanager.cpp
)

target_include_directories(${APP_TARGET} PRIVATE .)
