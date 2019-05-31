local P = {}

P.package = "github.com/cellux/zz_libzip"

local LIBZIP_VER = "1.5.2"

P.native = {}

P.native.libzip = function(ctx)
   local LIBZIP_TGZ = sf("libzip-%s.tar.gz", LIBZIP_VER)
   local LIBZIP_URL = sf("https://libzip.org/download/%s", LIBZIP_TGZ)
   local LIBZIP_DIR = sf("libzip-%s", LIBZIP_VER)
   local LIBZIP_ROOT = sf("%s/%s", ctx.nativedir, LIBZIP_DIR)
   local LIBZIP_SRC = sf("%s/lib", LIBZIP_ROOT)
   local LIBZIP_BUILD = sf("%s/build", LIBZIP_ROOT)
   local LIBZIP_LIB = sf("%s/lib/libzip.a", LIBZIP_BUILD)
   local libzip_tgz = ctx:Target {
      dirname = ctx.nativedir,
      basename = LIBZIP_TGZ,
      build = function(self)
         ctx:download {
            src = LIBZIP_URL,
            dst = self,
         }
      end
   }
   local libzip_extracted = ctx:Target {
      dirname = LIBZIP_ROOT,
      basename = ".extracted",
      depends = libzip_tgz,
      build = function(self)
         ctx:extract {
            cwd = ctx.nativedir,
            src = libzip_tgz
         }
      end
   }
   local libzip_a = ctx:Target {
      dirname = sf("%s/lib", LIBZIP_BUILD),
      basename = "libzip.a",
      depends = libzip_extracted,
      build = function(self)
         ctx:system {
            cwd = LIBZIP_BUILD,
            command = {
               "cmake",
               "-DENABLE_COMMONCRYPTO=OFF",
               "-DENABLE_GNUTLS=OFF",
               "-DENABLE_MBEDTLS=OFF",
               "-DENABLE_OPENSSL=OFF",
               "-DENABLE_WINDOWS_CRYPTO=OFF",
               "-DENABLE_BZIP2=OFF",
               "-DBUILD_EXAMPLES=OFF",
               "-DBUILD_DOC=OFF",
               "-DBUILD_SHARED_LIBS=OFF",
               "-Wno-dev",
               ".."
            }
         }
         ctx:system {
            cwd = LIBZIP_BUILD,
            command = { "make" }
         }
         ctx:system {
            cwd = LIBZIP_BUILD,
            command = { "make", "test" }
         }
      end
   }
   return ctx:Target {
      dirname = ctx.libdir,
      basename = "libzip.a",
      depends = libzip_a,
      cflags = { "-iquote", LIBZIP_SRC },
      build = function(self)
         ctx:cp {
            src = libzip_a,
            dst = self,
         }
      end
   }
end

P.exports = { "libzip" }

P.ldflags = { "-lz" }

return P
