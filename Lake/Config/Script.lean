/-
Copyright (c) 2021 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake.Config.Context

namespace Lake

/--
The type of a `Script`'s monad.
`IO` equipped information about the Lake configuration.
-/
abbrev ScriptM := LakeT IO

/--
The type of a `Script`'s function.
Similar to the `main` function's signature, except that its monad is
also equipped with information about the Lake configuration.
-/
abbrev ScriptFn := (args : List String) → ScriptM UInt32

/--
A package `Script` is a `ScriptFn` definition that is
indexed by a `String` key and can be be run by `lake run <key> [-- <args>]`.
-/
structure Script where
  fn : ScriptFn
  doc? : Option String
  deriving Inhabited

def Script.run (args : List String) (self : Script) : ScriptM UInt32 :=
  self.fn args
