/-
Copyright (c) 2021 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake.Task

open System
namespace Lake

--------------------------------------------------------------------------------
-- # Build Monad Definition
--------------------------------------------------------------------------------

-- Involves trickery patterned after `MacroM`
-- to allow `BuildMethods` to refer to `BuildM`

constant BuildMethodsRefPointed : PointedType.{0}
def BuildMethodsRef : Type := BuildMethodsRefPointed.type

structure BuildContext where
  methodsRef : BuildMethodsRef

abbrev BuildM := ReaderT BuildContext IO

structure BuildMethods where
  logInfo : String → BuildM PUnit
  logError : String → BuildM PUnit
  deriving Inhabited

namespace BuildMethodsRef

unsafe def mkImp (methods : BuildMethods) : BuildMethodsRef :=
  unsafeCast methods

@[implementedBy mkImp]
constant mk (methods : BuildMethods) : BuildMethodsRef :=
  BuildMethodsRefPointed.val

instance : Coe BuildMethods BuildMethodsRef := ⟨mk⟩
instance : Inhabited BuildMethodsRef := ⟨mk arbitrary⟩

unsafe def getImp (self : BuildMethodsRef) : BuildMethods :=
  unsafeCast self

@[implementedBy getImp]
constant get (self : BuildMethodsRef) : BuildMethods

end BuildMethodsRef

--------------------------------------------------------------------------------
-- # Build Monad Utilities
--------------------------------------------------------------------------------

namespace BuildContext

deriving instance Inhabited for BuildContext

def io : BuildContext where
  methodsRef := BuildMethodsRef.mk {
    logInfo  := fun msg => IO.println msg
    logError := fun msg => IO.eprintln msg
  }

def methods (self : BuildContext) : BuildMethods :=
  self.methodsRef.get

end BuildContext

namespace BuildM

def getMethods : BuildM BuildMethods :=
  read >>= (·.methods)

def logInfo (msg : String) : BuildM PUnit := do
  (← getMethods).logInfo msg

def logError (msg : String) : BuildM PUnit := do
  (← getMethods).logError msg

def runIn (ctx : BuildContext) (self : BuildM α) : IO α :=
  self ctx

def run (self : BuildM α) : IO PUnit :=
  runIn BuildContext.io do try discard self catch e =>
    /-
      Remark: Actual error should have already been logged earlier.
      However, if the error was thrown by something that did not know it was
      in `BuildM` (e.g., a general `Target`), it may have not been.

      TODO: Use an `OptionT` in `BuildM` to properly record build failures.
    -/
    BuildM.logError s!"build error: {toString e}"
    throw <| IO.userError "build failed"

end BuildM

def failOnImportCycle : Except (List Lean.Name) α → BuildM α
| Except.ok a => a
| Except.error cycle => do
  let cycle := cycle.map (s!"  {·}")
  let msg := s!"import cycle detected:\n{"\n".intercalate cycle}"
  BuildM.logError msg
  throw <| IO.userError msg

abbrev BuildTask := IOTask

instance : HAndThen (BuildTask α) (BuildM β) (BuildM (BuildTask β)) :=
  ⟨fun x y => seqRightAsync x (y ())⟩
