#include "util.h"

#include <QObject>
#include <QtTest/QtTest>

class UtilTest : public QObject
{
    Q_OBJECT

private slots:
    void parsePathFromArray();
    void parsePathFromEmptyInputs();
    void parsePathFromJsonValue();
    void parseByteArrayFromHex();
    void parseByteArrayFromEmptyValue();
    void reverseByteArray();
    void reverseEmptyByteArray();
    void sha256String();
    void redactLog();
    void csv();
};

void UtilTest::parsePathFromArray()
{
    const QJsonArray input{1, 2, QJsonValue(qint64(2147483648ULL))};
    QCOMPARE(ParsePath(input), (QVector<uint32_t>{1, 2, 2147483648u}));
}

void UtilTest::parsePathFromEmptyInputs()
{
    QCOMPARE(ParsePath(QJsonArray{}).size(), 0);
    QCOMPARE(ParsePath(QJsonValue()).size(), 0);
    QCOMPARE(ParsePath(QJsonValue(QStringLiteral("not-an-array"))).size(), 0);
}

void UtilTest::parsePathFromJsonValue()
{
    const QJsonArray input{1, 2, QJsonValue(qint64(2147483648ULL))};
    QCOMPARE(ParsePath(QJsonValue(input)), ParsePath(input));
}

void UtilTest::parseByteArrayFromHex()
{
    const QByteArray result = ParseByteArray(QStringLiteral("0a0bff"));
    QCOMPARE(result.toHex(), QByteArray("0a0bff"));
}

void UtilTest::parseByteArrayFromEmptyValue()
{
    QCOMPARE(ParseByteArray(QJsonValue(QString())), QByteArray());
    QCOMPARE(ParseByteArray(QJsonValue()), QByteArray());
}

void UtilTest::reverseByteArray()
{
    const QByteArray input = QByteArray::fromHex("0011aaff");
    const QByteArray reversed = ReverseByteArray(input);
    QCOMPARE(reversed.toHex(), QByteArray("ffaa1100"));
}

void UtilTest::reverseEmptyByteArray()
{
    QCOMPARE(ReverseByteArray(QByteArray()), QByteArray());
}

void UtilTest::sha256String()
{
    QCOMPARE(
        Sha256(QStringLiteral("abc")),
        QStringLiteral("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"));
}

void UtilTest::redactLog()
{
    const QByteArray input =
        "create_session Object {\"genesis_hash\": String(\"1466275836220db2944ca059a3a10ef6fd2ea684b0688d2c379296888a206003\"), \"name\": String(\"Liquid (Electrum)\")}\n"
        "set_fingerprint input \"String(\\\"0d092f17\\\")\"\n"
        "core_descriptors\\\": Array [String(\\\"sh(wpkh([0d092f17/49'/0'/0']xpub6CY8uDa4wFbTeArh7KWQatTejbS58oFxVVmX6YsRxN8G2qQJ1a9yFHevLbxm2ayJnzga7KHo7qidjT8jRWqhgK4Uai\n"
        "\\\"address\\\": String(\\\"3NgVAdzq8orJhgdvv4GLkNMKh9nFw6NhmD\\\"), \\\"prevout_script\\\": String(\\\"76a9140c48ed70af9f7\n"
        "list_tx [\"748ffc30437a9c9000f253f682f13947b83e43b2df1fe715ef53b2540c3ab934\"] 3NgVAdzq8orJhgdvv4GLkNMKh9nFw6NhmD\n"
        "tip=(4138872, Elements(1466275836220db2944ca059a3a10ef6fd2ea684b0688d2c379296888a206003\n"
        "{\"block_hash\": String(\"00000000000000000000fbd5b279601b5535d2d840d85c98a91042888d872222\")}\n"
        "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4\n"
        "QJsonObject({\"address\":\"33LRM6Z1QyhFwefn6UsLnGaaRWakNaCTqM\",\"prevout_script\":\"5221\",\"satoshi\":647857})\n"
        "gdk/1676be221bc584263d67d0c7be67dfae8.sqliteaesgcm loaded correctly\n"
        "save_blob input \"Object {\\\"blob\\\": String(\\\"AAEC+/xyz=\\\"), \\\"hmac\\\": String(\\\"kga2NTa1qcVIR/1mwo=\\\"), \\\"requires_merge\\\": Bool(true)}\"\n"
        "load_blob output \"Ok(Object {\\\"blob\\\": String(\\\"\\\")})\"\n"
        "get_receive_address returning Ok(Object {\"address\": String(\"37Tch1i5HzKPtoFKvEdhEwQiBbEB63SwhA\"), \"blinding_key\": String(\"0201c48\n"
        "Context::getOrCreateAccount(Network *, const QJsonObject &) \"{\"name\":\"2FA Cosimo\",\"pointer\":1}\"\n"
        "CreateTransactionController::update() QJsonObject({\"previous_transaction\":{\"fee\":250,\"satoshi\":{\"btc\":-123456}},\"satoshi\":-42})\n"
        "get_transactions Object {\\\"satoshi\\\": Object {\\\"6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d\\\": Number(-7000), \\\"btc\\\": Number(500)}}\n"
        "QJsonObject({\"name\":\"Savings \\\"Alice\\\"\",\"pointer\":2})\n"
        "QJsonObject({\"name\":\"\\\"Bob\\\" C:\\\\x\\nnext\",\"pointer\":3})\n"
        "\"{\\\"name\\\":\\\"\\\\\\\"Carol\\\\\\\" \\\\\\\\ \\\\nnext \\xC3\\xA9\"\"1\\\",\\\"pointer\\\":4}\"\n"
        "get_subaccounts Object {\"name\": String(\"\\\"Dave\\\" \\\\ \\n\"), \"pointer\": Number(5)}\n"
        "get_subaccounts output \"Object {\\\"name\\\": String(\\\"\\\\\\\"Eve\\\\\\\" \\\\\\\\ \\\\n\\\"), \\\"pointer\\\": Number(6)}\"\n"
        "{\"name\": String(\"Frank \\\"the\n"
        "\\\"name\\\": String(\\\"Grace \\\\\\\"the\n"
        "Data directory: " + QDir::homePath().toUtf8() + "/.local/share\n";
    const QByteArray expected =
        "create_session Object {\"genesis_hash\": String(\"1466275836220db2944ca059a3a10ef6fd2ea684b0688d2c379296888a206003\"), \"name\": String(\"Liquid (Electrum)\")}\n"
        "set_fingerprint input \"String(\\\"<FP_1>\\\")\"\n"
        "core_descriptors\\\": Array [String(\\\"sh(wpkh([<FP_1>/49'/0'/0']<XPUB_1>\n"
        "\\\"address\\\": String(\\\"<ADDR_1>\\\"), \\\"prevout_script\\\": String(\\\"<HEX_1>\n"
        "list_tx [\"<HEX_2>\"] <ADDR_1>\n"
        "tip=(4138872, Elements(1466275836220db2944ca059a3a10ef6fd2ea684b0688d2c379296888a206003\n"
        "{\"block_hash\": String(\"00000000000000000000fbd5b279601b5535d2d840d85c98a91042888d872222\")}\n"
        "<ADDR_2>\n"
        "QJsonObject({\"address\":\"<ADDR_3>\",\"prevout_script\":\"<HEX_3>\",\"satoshi\":<SAT_1>})\n"
        "gdk/<HEX_4>.sqliteaesgcm loaded correctly\n"
        "save_blob input \"Object {\\\"blob\\\": String(\\\"<BLOB_1>\\\"), \\\"hmac\\\": String(\\\"<BLOB_2>\\\"), \\\"requires_merge\\\": Bool(true)}\"\n"
        "load_blob output \"Ok(Object {\\\"blob\\\": String(\\\"\\\")})\"\n"
        "get_receive_address returning Ok(Object {\"address\": String(\"<ADDR_4>\"), \"blinding_key\": String(\"<HEX_5>\n"
        "Context::getOrCreateAccount(Network *, const QJsonObject &) \"{\"name\":\"<NAME_1>\",\"pointer\":1}\"\n"
        "CreateTransactionController::update() QJsonObject({\"previous_transaction\":{\"fee\":250,\"satoshi\":{\"btc\":<SAT_3>}},\"satoshi\":<SAT_2>})\n"
        "get_transactions Object {\\\"satoshi\\\": Object {\\\"<HEX_6>\\\": Number(<SAT_4>), \\\"btc\\\": Number(<SAT_5>)}}\n"
        "QJsonObject({\"name\":\"<NAME_2>\",\"pointer\":2})\n"
        "QJsonObject({\"name\":\"<NAME_3>\",\"pointer\":3})\n"
        "\"{\\\"name\\\":\\\"<NAME_4>\\\",\\\"pointer\\\":4}\"\n"
        "get_subaccounts Object {\"name\": String(\"<NAME_5>\"), \"pointer\": Number(5)}\n"
        "get_subaccounts output \"Object {\\\"name\\\": String(\\\"<NAME_6>\\\"), \\\"pointer\\\": Number(6)}\"\n"
        "{\"name\": String(\"<NAME_7>\n"
        "\\\"name\\\": String(\\\"<NAME_8>\n"
        "Data directory: ~/.local/share\n";

    QBuffer in;
    in.setData(input);
    QVERIFY(in.open(QIODevice::ReadOnly));

    QByteArray output;
    QBuffer out(&output);
    QVERIFY(out.open(QIODevice::WriteOnly));
    QVERIFY(RedactLog(in, out));
    QCOMPARE(output, expected);
}

void UtilTest::csv()
{
    QCOMPARE(CsvText("=WEBSERVICE(\"x\")"), QString("\t'=WEBSERVICE(\"x\")"));
    QCOMPARE(CsvText("+1"), QString("\t'+1"));
    QCOMPARE(CsvText("-1"), QString("\t'-1"));
    QCOMPARE(CsvText("@a"), QString("\t'@a"));
    QCOMPARE(CsvText("\t=1"), QString("\t'\t=1"));
    QCOMPARE(CsvText("\r=1"), QString("\t'\r=1"));
    QCOMPARE(CsvText("\n=1"), QString("\t'\n=1"));
    for (const auto prefix : {u"\uFF1D", u"\uFF0B", u"\uFF0D", u"\uFF20"}) {
        const auto value = QString::fromUtf16(prefix) + "1";
        QCOMPARE(CsvText(value), "\t'" + value);
    }
    QCOMPARE(CsvText("rent"), QString("rent"));
    QCOMPARE(CsvText(""), QString());
    QCOMPARE(CsvLine({"a", "b,c", "d\"e", "f\ng"}), QString("\"a\",\"b,c\",\"d\"\"e\",\"f\ng\""));
}

QTEST_GUILESS_MAIN(UtilTest)
#include "tst_util.moc"
