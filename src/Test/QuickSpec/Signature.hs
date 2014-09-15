-- Signatures, collecting and finding witnesses, etc.
{-# LANGUAGE CPP, ConstraintKinds, ExistentialQuantification, ScopedTypeVariables, DeriveDataTypeable, StandaloneDeriving #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Test.QuickSpec.Signature where

#include "errors.h"
import Data.Constraint
import Test.QuickSpec.Base
import Test.QuickSpec.Term
import Test.QuickSpec.Type
import Test.QuickSpec.Utils
import Data.Functor.Identity
import Data.Monoid
import Test.QuickCheck
import Control.Monad
import Data.Maybe
import Data.List

data Instance c = forall a. Typeable a => Instance (Dict (c a))
data Signature =
  Signature {
    constants :: [Constant],
    ords      :: [Instance Ord],
    arbs      :: [Instance Arbitrary] }

instance Monoid Signature where
  mempty = Signature [] [] []
  Signature cs os as `mappend` Signature cs' os' as' = Signature (cs++cs') (os++os') (as++as')

constant :: Typeable a => String -> a -> Signature
constant name x = Signature [Constant name (toValue (Identity x))] [] []

-- :)
deriving instance Typeable Ord
deriving instance Typeable Arbitrary

ord :: forall a. (Typeable a, Ord a) => a -> Signature
ord _ = Signature [] [Instance (Dict :: Dict (Ord a))] []

arb :: forall a. (Typeable a, Arbitrary a) => a -> Signature
arb _ = Signature [] [] [Instance (Dict :: Dict (Arbitrary a))]

findInstance :: forall c. Type -> [Instance c] -> Maybe (Instance c)
findInstance ty is =
  listToMaybe [ i | i@(Instance (_ :: Dict (c a))) <- is, typeOf (undefined :: a) == ty ]

-- Testing!
sig :: Signature
sig = mconcat [
  constant "rev" (reverse :: [Int] -> [Int]),
  constant "app" ((++) :: [Int] -> [Int] -> [Int]),
  constant "[]" ([] :: [Int]),
  constant "sort" (sort :: [Int] -> [Int]),
  --constant "usort" (usort :: [Int] -> [Int]),
  ord (undefined :: [Int]),
  arb (undefined :: [Int])]