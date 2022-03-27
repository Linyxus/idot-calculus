Set Implicit Arguments.

Require Import Coq.Program.Equality.
Require Import Definitions Lookup Sequences.

(** * Operational Semantics *)

Definition matched_case γ p q A :=
  exists r T ds r0, γ ⟦ defp p ⤳* defv (ν[q↘A](T)ds) ⟧ /\  (* checks that runtime value of the path is matchable *)
                   γ ⟦ defp (open_path_p p q) ⤳* defp r0 ⟧ /\
                   γ ⟦ defp r ⤳* defp r0 ⟧.

(** Term-reduction relation *)
Reserved Notation "t1 '⟼' t2" (at level 40, t2 at level 39).

Inductive red : sta * trm -> sta * trm -> Prop :=

(** [γ ⊢ q ⤳* λ(T)t ]      #<br>#
    [―――――――――――――――――――――]      #<br>#
    [γ | q p ⟼ γ | tᵖ]      *)
| red_app: forall γ p q T t,
    γ ⟦ defp q ⤳* defv (λ(T) t) ⟧ ->
    (γ, trm_app q p) ⟼ (γ, open_trm_p p t)

(** [γ | let x = v in t ⟼ γ, x = v | tˣ] *)
| red_let_val : forall v t γ x,
    x # γ ->
    (γ, trm_let (trm_val v) t) ⟼ (γ & x ~ v, open_trm x t)

(** [γ | let y = p in t ⟼ γ | tᵖ] *)
| red_let_path : forall t γ p,
    (γ, trm_let (trm_path p) t) ⟼ (γ, open_trm_p p t)

(** [γ | t0 ⟼ γ' | t0']                            #<br>#
    [―――――――――――――――――――――――――――――――――――――――――――――――]  #<br>#
    [γ | let x = t0 in t ⟼ γ' | let x = t0' in t]  *)
| red_let_tgt : forall t0 t γ t0' γ',
    (γ, t0) ⟼ (γ', t0') ->
    (γ, trm_let t0 t) ⟼ (γ', trm_let t0' t)

(** [γ ⊢ p ⤳* ν[q.A](x: T)ds ]      #<br>#
    [―――――――――――――――――――――]      #<br>#
    [γ | case p of tag q.A y => t1 | else => t2 ⟼ γ | t1^p ]      *)
| red_case_match : forall γ p q A t1 t2,
    matched_case γ p q A ->
    (γ, trm_case p q A t1 t2) ⟼ (γ, open_trm_p p t1)

(** [γ ⊢ p ⤳* tag r1.A r2 ]      #<br>#
    [―――――――――――――――――――――]      #<br>#
    [γ | case p of tag q.A y => t1 | else => t2 ⟼ γ | t2 ]      *)
| red_case_else : forall γ p q A t1 t2,
    ~(matched_case γ p q A) ->
    (γ, trm_case p q A t1 t2) ⟼ (γ, t2)

where "t1 '⟼' t2" := (red t1 t2).

(** Reflexive, transitive closure of reduction relation *)
Notation "t1 '⟼*' t2" := (star red t1 t2) (at level 40).

(** ** Normal forms *)

(** Paths and values are considered to be in normal form. *)
Inductive norm_form: trm -> Prop :=
| nf_path: forall p, norm_form (trm_path p)
| nf_val: forall v, norm_form (trm_val v).

Hint Constructors red norm_form.
