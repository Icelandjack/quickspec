{-# LANGUAGE CPP #-}
module QuickSpec.Prop where

#include "errors.h"
import Control.Monad
import qualified Data.DList as DList
import Data.Ord
import QuickSpec.Term
import QuickSpec.Type
import QuickSpec.Utils
import qualified Data.Map as Map
import Twee.Pretty

data Prop a =
  (:=>:) {
    lhs :: [Literal a],
    rhs :: Literal a } deriving Show

instance Ord a => Eq (Prop a) where
  x == y = x `compare` y == EQ
instance Ord a => Ord (Prop a) where
  compare = comparing (\p -> (usort (lhs p), rhs p))

infix 4 :=>:

literals :: Prop a -> [Literal a]
literals p = rhs p:lhs p

unitProp :: Literal a -> Prop a
unitProp p = [] :=>: p

instance Typed a => Typed (Prop a) where
  typ _ = boolType
  otherTypesDL p = DList.fromList (literals p) >>= typesDL
  typeReplace sub (lhs :=>: rhs) =
    map (typeReplace sub) lhs :=>: typeReplace sub rhs

instance Pretty a => Pretty (Prop a) where
  pPrint ([] :=>: rhs) = pPrint rhs
  pPrint p =
    sep [
      fsep
        (punctuate (text "" <+> text "&")
          (map pPrint (lhs p))) <+> text "=>",
      nest 2 (pPrint (rhs p))]

data Literal a = a :=: a | Predicate :@: [a] deriving (Show, Eq, Ord)

infix 5 :@:
infix 5 :=:

instance Typed a => Typed (Literal a) where
  typ _ = boolType
  otherTypesDL l = literalTermsDL l >>= typesDL
  typeReplace sub (x :=: y) = typeReplace sub x :=: typeReplace sub y
  typeReplace sub (p :@: ts) = typeReplace sub p :@: map (typeReplace sub) ts

propTerms :: Prop a -> [a]
propTerms p = literals p >>= DList.toList . literalTermsDL

literalTermsDL :: Literal a -> DList.DList a
literalTermsDL (t :=: u) = return u `mplus` return t
literalTermsDL (p :@: ts) = DList.fromList ts

propType :: Typed a => Prop a -> Type
propType (_ :=>: p :@: ts) = typ p
propType (_ :=>: t :=: u) = typ t

instance Pretty a => Pretty (Literal a) where
  pPrint (x :=: y) = hang (pPrint x <+> text "=") 2 (pPrint y)
  pPrint (p :@: xs) = pPrint p <> parens (sep (punctuate comma (map pPrint xs)))

data Predicate = Predicate {
  predName :: String,
  predType :: Type,
  predGeneralType :: Poly Type }
  deriving (Eq, Ord, Show)

instance Pretty Predicate where
  pPrint = text . predName

instance Typed Predicate where
  typ = predType
  typeReplace sub (Predicate x ty pty) = Predicate x (typeReplace sub ty) pty

boolType :: Type
boolType = typeOf (undefined :: Bool)
