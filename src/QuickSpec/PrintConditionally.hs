{-# LANGUAGE FlexibleContexts #-}
module QuickSpec.PrintConditionally where

import QuickSpec
import Twee.Term hiding (lookup)
import Twee.Pretty
import Data.List

printConditionally :: [(Constant, [Constant])] -> Signature -> IO ()
printConditionally preds sig =
  mapM_ (prettyPrint . prettyRename sig . conditionalise preds) (background sig)

conditionalise :: [(Constant, [Constant])] -> Prop -> Prop
conditionalise preds ([] :=>: t :=: u) =
  lhs :=>: build (subst (singleton t)) :=: build (subst (singleton u))
  where
    lhs =
      usort
      [ predicate p :@: map snd sels
      | (p, sels, x) <- conditionSubst ]
    
    conditions =
      usort
      [ (p, sels, x)
      | (p, sels) <- preds,
        App f [x] <- subterms t ++ subterms u,
        generalise f `elem` sels ]

    conditionSubst = go (bound t `max` bound u) conditions
      where
        go _ [] = []
        go n ((p, sels, x):xs) =
          (p, zipWith (makeSel x) sels [n..], x):go (n+length sels) xs
        makeSel x sel n =
          (sel, app (Id (typ (apply (app sel []) x))) [build (var (MkVar n))])

    selectorSubst = [((sel, t), x) | (_, sels, t) <- conditionSubst, (sel, x) <- sels]

    subst Empty = mempty
    subst (Cons (App sel [t]) ts)
      | Just x <- lookup (generalise sel, t) selectorSubst =
        builder x `mappend` subst ts
    subst (Cons (Fun f ts) us) =
      fun f (subst ts) `mappend` subst us
    subst (Cons (Var x) ts) = var x `mappend` subst ts

    predicate p =
      Predicate (conName p) (termStyle p) (typ p) (poly (typ (conGeneralValue p)))

    generalise f@Constant{} = f { conValue = unPoly (conGeneralValue f), conArity = 0 }
    generalise f = f

