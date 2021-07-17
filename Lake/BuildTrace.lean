/-
Copyright (c) 2021 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/

namespace Lake

-- # Hash Traces

def Hash := UInt64

instance : OfNat Hash n := inferInstanceAs (OfNat UInt64 n)
instance : Inhabited Hash := inferInstanceAs (Inhabited UInt64)
instance : BEq Hash := inferInstanceAs (BEq UInt64)

def Hash.ofNat (n : Nat) := UInt64.ofNat n
def Hash.foldList (init : Hash) (hashes : List Hash) :=
  List.foldl mixHash init hashes

-- # Modification Time Traces

open IO.FS (SystemTime)

def MTime := SystemTime

instance : Inhabited MTime := ⟨⟨0,0⟩⟩
instance : OfNat MTime (nat_lit 0) := ⟨⟨0,0⟩⟩
instance : BEq MTime := inferInstanceAs (BEq SystemTime)
instance : Repr MTime := inferInstanceAs (Repr SystemTime)
instance : Ord MTime := inferInstanceAs (Ord SystemTime)
instance : LT MTime := ltOfOrd
instance : LE MTime := leOfOrd

def MTime.listMax (mtimes : List MTime) := mtimes.maximum?.getD 0

class GetMTime (α) where
  getMTime : α → IO MTime

export GetMTime (getMTime)

instance : GetMTime System.FilePath where
  getMTime file := do (← file.metadata).modified

-- # Combined Trace

structure LeanTrace where
  hash : Hash
  mtime : MTime
  deriving Inhabited

namespace LeanTrace

def fromHash (hash : Hash) : LeanTrace :=
  LeanTrace.mk hash 0

def fromMTime (mtime : MTime) : LeanTrace :=
  LeanTrace.mk 0 mtime

end LeanTrace