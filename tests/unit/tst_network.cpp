#include "network.h"

#include <QObject>
#include <QtTest/QtTest>

class NetworkTest : public QObject
{
    Q_OBJECT

private slots:
    void propertiesForEachNetworkCombination_data();
    void propertiesForEachNetworkCombination();
};

void NetworkTest::propertiesForEachNetworkCombination_data()
{
    QTest::addColumn<QString>("id");
    QTest::addColumn<bool>("mainnet");
    QTest::addColumn<bool>("liquid");
    QTest::addColumn<bool>("development");
    QTest::addColumn<QString>("serverType");
    QTest::addColumn<QString>("policyAsset");
    QTest::addColumn<bool>("includePolicyAsset");
    QTest::addColumn<QString>("explorerUrl");
    QTest::addColumn<QString>("key");
    QTest::addColumn<QString>("displayName");
    QTest::addColumn<QString>("deployment");
    QTest::addColumn<QString>("canonicalId");

    QTest::newRow("bitcoin mainnet")
        << QStringLiteral("electrum-bitcoin") << true << false << false
        << QStringLiteral("electrum") << QStringLiteral("btc") << true
        << QStringLiteral("https://example.com/tx/")
        << QStringLiteral("bitcoin") << QStringLiteral("Bitcoin") << QStringLiteral("mainnet")
        << QStringLiteral("bitcoin");
    QTest::newRow("liquid mainnet")
        << QStringLiteral("liquid") << true << true << false
        << QStringLiteral("green") << QStringLiteral("6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d") << true
        << QStringLiteral("https://example.com/liquid/tx/")
        << QStringLiteral("liquid") << QStringLiteral("Liquid") << QStringLiteral("mainnet")
        << QStringLiteral("liquid");
    QTest::newRow("bitcoin testnet")
        << QStringLiteral("testnet") << false << false << false
        << QStringLiteral("electrum") << QStringLiteral("btc") << true
        << QStringLiteral("https://example.com/testnet/tx/")
        << QStringLiteral("testnet") << QStringLiteral("Testnet") << QStringLiteral("testnet")
        << QStringLiteral("testnet");
    QTest::newRow("liquid testnet")
        << QStringLiteral("testnet-liquid") << false << true << false
        << QStringLiteral("green") << QStringLiteral("asset-id") << true
        << QStringLiteral("https://example.com/liquid-testnet/tx/")
        << QStringLiteral("testnet-liquid") << QStringLiteral("Testnet Liquid") << QStringLiteral("testnet")
        << QStringLiteral("testnet-liquid");
    QTest::newRow("localtest")
        << QStringLiteral("localtest") << false << false << true
        << QStringLiteral("green") << QStringLiteral("btc") << false
        << QString()
        << QStringLiteral("localtest") << QStringLiteral("Localtest") << QStringLiteral("development")
        << QStringLiteral("localtest");
    QTest::newRow("localtest-liquid")
        << QStringLiteral("localtest-liquid") << false << true << true
        << QStringLiteral("electrum") << QStringLiteral("policy") << true
        << QStringLiteral("https://example.com/localtest-liquid/tx/")
        << QStringLiteral("localtest-liquid") << QStringLiteral("Localtest Liquid") << QStringLiteral("development")
        << QStringLiteral("localtest-liquid");
}

void NetworkTest::propertiesForEachNetworkCombination()
{
    QFETCH(QString, id);
    QFETCH(bool, mainnet);
    QFETCH(bool, liquid);
    QFETCH(bool, development);
    QFETCH(QString, serverType);
    QFETCH(QString, policyAsset);
    QFETCH(bool, includePolicyAsset);
    QFETCH(QString, explorerUrl);
    QFETCH(QString, key);
    QFETCH(QString, displayName);
    QFETCH(QString, deployment);
    QFETCH(QString, canonicalId);

    QJsonObject data{
        {QStringLiteral("network"), id},
        {QStringLiteral("name"), QStringLiteral("Example")},
        {QStringLiteral("mainnet"), mainnet},
        {QStringLiteral("liquid"), liquid},
        {QStringLiteral("development"), development},
        {QStringLiteral("server_type"), serverType},
        {QStringLiteral("tx_explorer_url"), explorerUrl}
    };
    if (includePolicyAsset) {
        data.insert(QStringLiteral("policy_asset"), policyAsset);
    }

    Network network(data);
    QCOMPARE(network.id(), id);
    QCOMPARE(network.canonicalId(), canonicalId);
    QCOMPARE(network.key(), key);
    QCOMPARE(network.displayName(), displayName);
    QCOMPARE(network.name(), QStringLiteral("Example"));
    QCOMPARE(network.deployment(), deployment);
    QCOMPARE(network.isMainnet(), mainnet);
    QCOMPARE(network.isLiquid(), liquid);
    QCOMPARE(network.isDevelopment(), development);
    QCOMPARE(network.isElectrum(), serverType == QLatin1String("electrum"));
    QCOMPARE(network.policyAsset(), policyAsset);
    QCOMPARE(network.explorerUrl(), explorerUrl);
}

QTEST_GUILESS_MAIN(NetworkTest)
#include "tst_network.moc"
