// uintSkope — smoke test: the shipped NIF/KFM format definitions are present
// and parse as well-formed XML. This does not validate semantics (that needs the
// full NifModel), but it catches a missing/empty/corrupt nif.xml or kfm.xml,
// which would otherwise fail only at GUI startup.

#include <QFile>
#include <QString>
#include <QXmlStreamReader>
#include <cstdio>

static bool parseWellFormed(const char *path)
{
    QFile f(QString::fromUtf8(path));
    if (!f.open(QIODevice::ReadOnly)) {
        std::printf("  FAIL: cannot open %s\n", path);
        return false;
    }

    QXmlStreamReader xml(&f);
    qint64 elements = 0;
    while (!xml.atEnd()) {
        if (xml.readNext() == QXmlStreamReader::StartElement)
            ++elements;
    }

    if (xml.hasError()) {
        std::printf("  FAIL: %s — XML error: %s\n", path,
                    xml.errorString().toUtf8().constData());
        return false;
    }
    if (elements == 0) {
        std::printf("  FAIL: %s — parsed but contained no elements\n", path);
        return false;
    }

    std::printf("  OK: %s (%lld elements)\n", path,
                static_cast<long long>(elements));
    return true;
}

int main()
{
    std::printf("uintSkope xml_wellformed smoke test\n");

    bool ok = true;
    ok &= parseWellFormed(UINTSKOPE_NIF_XML);
    ok &= parseWellFormed(UINTSKOPE_KFM_XML);

    if (ok) {
        std::printf("OK: NIF/KFM XML well-formed\n");
        return 0;
    }
    std::printf("FAILED: XML well-formedness check\n");
    return 1;
}
