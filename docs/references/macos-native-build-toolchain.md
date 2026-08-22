# macOS native module builds: broken libc++ headers in Command Line Tools

Hit while running `npm install` for `procurement-core` (needs `better-sqlite3`,
which compiles a native addon). Documented here because it will resurface for
any future native `npm install` on this machine — Python native wheels, other
native Node addons — not just this one package.

## Symptom

```
../src/better_sqlite3.cpp:1:10: fatal error: 'climits' file not found
    1 | #include <climits>
```

`climits` is a totally standard C++ header. `make` fails immediately on the
first native `#include`.

## Root cause

```
$ xcode-select -p
/Library/Developer/CommandLineTools

$ clang++ -v -x c++ -E /dev/null -o /dev/null 2>&1 | grep -A5 'search starts here'
#include <...> search starts here:
 /Library/Developer/CommandLineTools/usr/bin/../include/c++/v1   <- searched FIRST
 /Library/Developer/CommandLineTools/usr/lib/clang/21/include
 /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk/usr/include
 ...
```

Clang always searches its own toolchain-bundled `usr/include/c++/v1` **before**
the active SDK's copy. On this machine that bundled directory is a stale,
incomplete leftover — dated Oct 2022, containing only a handful of `__*` helper
headers and none of the real ones (`climits`, `vector`, `string`, …):

```
$ find /Library/Developer/CommandLineTools/usr/include/c++/v1 -maxdepth 1
__bit  __charconv  __compare  __concepts        # that's ALL of it
```

Meanwhile the currently-selected SDK (`MacOSX26.5.sdk`, resolved via the
`MacOSX.sdk` symlink) has the complete, correct header set, `climits` included —
it's just never reached because clang stops at the first (broken) match.

This is a partial/mismatched Command Line Tools installation, not something
this project caused, and not something to "fix" by deleting system directories
without confirmation.

## Non-destructive fix used here

Force clang to search the SDK's complete headers ahead of the broken bundled
ones, via `CXXFLAGS`/`CPPFLAGS` — scoped to the install command, touches nothing
system-wide:

```bash
SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk   # or: xcrun --show-sdk-path
export CXXFLAGS="-isystem $SDK/usr/include/c++/v1 -isysroot $SDK"
export CPPFLAGS="-isystem $SDK/usr/include/c++/v1 -isysroot $SDK"
npm install
```

Verified with a minimal reproduction before touching the real install:

```bash
echo '#include <climits>
int main(){return 0;}' > /tmp/t.cpp
clang++ -isystem "$SDK/usr/include/c++/v1" -isysroot "$SDK" /tmp/t.cpp -o /tmp/t && echo OK
```

## The actual, permanent fix (not applied — needs your call)

The proper repair is reinstalling Command Line Tools, which requires `sudo` and
a multi-GB download — deliberately **not** run automatically:

```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

Until/unless that's done, any new native `npm install` on this machine needs the
`CXXFLAGS`/`CPPFLAGS` workaround above. Worth doing the real fix at some point
since the workaround has to be remembered and re-applied every time.
