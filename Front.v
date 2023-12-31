Require Import Nat.
Require Import Bool.
Require Import Arith.
Require Import Arith.Compare.

From CritBit Require Import KeyUtil.
From CritBit Require Import PrefixCritical.
From CritBit Require Import SeqAccess.

Section Critbit.

Context (X : Type).

(* a CBT (non-empty) *)
Inductive CBT : Type :=
  | Leaf (k : list bool) (v : X)
  | Branch (i : nat) (l r : CBT).

(* precond: one-terminated k *)
(* precond: t is a valid tree w.r.t. CBT_valid *)
Fixpoint lookup (k : list bool) (t : CBT) : option X :=
  match t with
  | Leaf k' v => if key_eqb k k' then Some v else None
  | Branch i l r => if ith_zer i k then lookup k r else lookup k l
  end.

Fixpoint find_best_key (k : list bool) (t : CBT) : (list bool) :=
  match t with
  | Leaf k' _ => k'
  | Branch i l r => find_best_key k (if ith_zer i k then r else l)
  end.

Definition seed (k : list bool) (v : X) : CBT :=
  Leaf k v.

Definition is_beforeb (pos : option nat) (bound : nat) : bool :=
  match pos with
  | None => false
  | Some i => i <? bound
  end.

Definition insert_as_branch (k : list bool) (v : X) (i : nat) (t : CBT) : CBT :=
  if ith_zer i k then Branch i t (Leaf k v) else Branch i (Leaf k v) t.

(* precond: t is a valid tree w.r.t. CBT_valid *)
(* precond: i is the critical bit of k w.r.t. t *)
Fixpoint insert_at (k : list bool) (v : X) (i : option nat) (t : CBT) : CBT :=
  match t with
  | Leaf k' v' =>  match i with
                   | None => Leaf k v
                   | Some cbit => insert_as_branch k v cbit t
                   end
  | Branch j l r => if is_beforeb i j
      then match i with
           | None => Leaf k v (* shoud never happen *)
           | Some cbit => insert_as_branch k v cbit t
           end
      else (if ith_zer j k
            then Branch j l (insert_at k v i r)
            else Branch j (insert_at k v i l) r)
  end.

Definition critical_bit_CBT (k : list bool) (t : CBT) : option nat :=
  critical_bit_zer k (find_best_key k t).

(* precond: one-terminated k *)
Definition insert (k : list bool) (v : X) (t : CBT) : CBT :=
  insert_at k v (critical_bit_CBT k t) t.

End Critbit.
