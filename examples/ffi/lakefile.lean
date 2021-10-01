import Lake
open System Lake DSL

def cDir : FilePath := "c"
def addSrc := cDir / "add.cpp"

def buildDir := defaultBuildDir
def addO := buildDir / cDir / "add.o"
def cLib := buildDir / cDir / "libadd.a"

def addOTarget (pkgDir : FilePath) : FileTarget :=
  oFileTarget (pkgDir / addO) (pkgDir / addSrc : FilePath)

def cLibTarget (pkgDir : FilePath) : FileTarget :=
  staticLibTarget (pkgDir / cLib) #[addOTarget pkgDir]

package (pkgDir) (args) {
  name := "ffi"
  -- customize layout
  srcDir := "lib"
  libRoots := #[`Add]
  binName := "add"
  binRoot := `Main
  -- specify the lib as an additional target
  moreLibTargets := #[cLibTarget pkgDir]
}
