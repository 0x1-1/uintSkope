// uintSkope — smoke test for the NifSkopeVersion parsing/comparison logic.
//
// Exercises the version utility that the application relies on for settings
// migration and window-title formatting. Compiling src/version.cpp here also
// acts as a guard that its Qt 6 port stays buildable.

#include "version.h"

#include <QString>
#include <cstdio>

static int g_failures = 0;

#define CHECK(cond)                                                            \
    do {                                                                       \
        if (!(cond)) {                                                         \
            std::printf("  FAIL: %s  (line %d)\n", #cond, __LINE__);           \
            ++g_failures;                                                      \
        }                                                                      \
    } while (0)

#define CHECK_EQ(actual, expected)                                             \
    do {                                                                       \
        const QString _a = (actual);                                           \
        const QString _e = (expected);                                         \
        if (_a != _e) {                                                        \
            std::printf("  FAIL: %s == \"%s\" but got \"%s\"  (line %d)\n",    \
                        #actual, _e.toUtf8().constData(),                      \
                        _a.toUtf8().constData(), __LINE__);                    \
            ++g_failures;                                                      \
        }                                                                      \
    } while (0)

int main()
{
    std::printf("uintSkope version_logic smoke test\n");

    // MAJ.MIN extraction (used for window titles / app name).
    CHECK_EQ(NifSkopeVersion::rawToMajMin("2.0.dev7"), "2.0");
    CHECK_EQ(NifSkopeVersion::rawToMajMin("1.2.3"), "1.2");

    // Three-part comparison returns {-1,0,1}.
    CHECK(NifSkopeVersion::compare("1.2.0", "1.2.1") == -1);
    CHECK(NifSkopeVersion::compare("1.2.1", "1.2.1") == 0);
    CHECK(NifSkopeVersion::compare("1.3.0", "1.2.9") == 1);

    // Greater/less helpers.
    CHECK(NifSkopeVersion::compareGreater("2.0.0", "1.9.9"));
    CHECK(NifSkopeVersion::compareLess("1.0.0", "1.0.1"));
    CHECK(!NifSkopeVersion::compareGreater("1.0.0", "1.0.0"));

    // Display formatting of a pre-release dev string.
    CHECK_EQ(NifSkopeVersion::rawToDisplay("2.0.dev7", true), "2.0 Dev 7");
    CHECK_EQ(NifSkopeVersion::rawToDisplay("1.2.0", true), "1.2.0");

    // Object comparison operators.
    NifSkopeVersion a("1.2.0");
    NifSkopeVersion b("1.2.1");
    CHECK(a < b);
    CHECK(b > a);
    CHECK(a != b);

    if (g_failures == 0) {
        std::printf("OK: all version checks passed\n");
        return 0;
    }
    std::printf("FAILED: %d version check(s)\n", g_failures);
    return 1;
}
