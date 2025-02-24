(** ** Tarski Completeness *)

From FOL Require Import FragmentSyntax Theories.
From Undecidability.Synthetic Require Import Definitions DecidabilityFacts EnumerabilityFacts ListEnumerabilityFacts ReducibilityFacts.
From Undecidability Require Import Shared.ListAutomation Shared.Dec.
From Stdlib Require Import Vector List Lia.
Import ListAutomationNotations ListAutomationHints ListAutomationInstances ListAutomationFacts.
From FOL.Completeness Require Export TarskiConstructions EnumerationUtils.
From FOL.Utils Require Import MPFacts.
(* ** Completeness *)

(* ** Standard Models **)

Section Completeness.
  Context {Σf : funcs_signature} {Σp : preds_signature}.
  Context {HdF : eq_dec Σf} {HdP : eq_dec Σp}.
  Variable eF : nat -> option Σf.
  Context {HeF : enumerator__T eF Σf}.
  Variable eP : nat -> option Σp.
  Context {HeP : enumerator__T eP Σp}.

  #[local] Hint Constructors bounded : core.

  Section BotModel.
    #[local] Existing Instance falsity_on | 0.
    Variable T : theory.
    Hypothesis T_closed : closed_T T.

    Definition input_bot : ConstructionInputs :=
      {|
        NBot := ⊥ ;
        NBot_closed := bounded_falsity 0;

        variant := falsity_on ;

        In_T := T ;
        In_T_closed := T_closed ;
        TarskiConstructions.enum := form_enum_with_default ⊥;
        TarskiConstructions.enum_enum := form_default_is_enum _;
        TarskiConstructions.enum_bounded := form_default_is_bounded (bounded_falsity _)
      |}.

    Definition output_bot := construct_construction input_bot.

    Instance model_bot : interp term :=
      {| i_func := func; i_atom := fun P v => atom P v ∈ Out_T output_bot|}.

    Lemma eval_ident rho (t : term) :
      eval rho t = subst_term rho t.
    Proof.
      induction t in rho|-*.
      - easy.
      - cbn. easy.
    Qed.
    Hypothesis Hcon : consistent class T.

    Lemma model_bot_correct phi rho :
      (phi[rho] ∈ Out_T output_bot <-> rho ⊨ phi).
    Proof.
      revert rho. induction phi using form_ind_falsity; intros rho. 1,2,3: cbn.
      - split; try tauto. intros H. apply Hcon.
        apply Out_T_econsistent with output_bot. exists [⊥].
        split; try apply Ctx. 2: now left. intros a [<-|[]]; easy.
      - erewrite (Vector.map_ext_in _ _ _ (eval rho)). 1:easy.
        easy.
      - destruct b0. rewrite <- IHphi1. rewrite <- IHphi2. apply Out_T_impl.
      - destruct q. cbn. setoid_rewrite <- IHphi. setoid_rewrite Out_T_all.
        split; intros H t; asimpl; specialize (H t); now asimpl in H.
    Qed. 

    Lemma model_bot_classical :
      classical model_bot.
    Proof.
      intros rho phi psi. apply model_bot_correct, Out_T_prv.
      use_theory (nil : list form). apply Pc.
    Qed.

    Lemma valid_T_model_bot phi :
      phi ∈ T -> var ⊨ phi.
    Proof.
      intros H % (Out_T_sub output_bot). apply model_bot_correct. now rewrite subst_id.
    Qed.
  End BotModel.

  Section StandardCompleteness.
    Variables (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on).
    Hypothesis (HT : closed_T T) (Hphi : closed phi).

    Lemma semi_completeness_standard_classical_model :
      valid_theory_C (classical (ff:=falsity_on)) T phi -> ~ ~ T ⊢TC phi.
    Proof.
      intros Hval Hcons. rewrite refutation_prv in Hcons. 
      assert (Hcl : closed_T (T ⋄ (¬ phi))) by (apply closed_T_extend; try econstructor; eauto).
      unshelve eapply (model_bot_correct (T_closed := Hcl) Hcons (¬ phi) var).
      - apply Out_T_sub. cbn. right. now asimpl.
      - apply Hval. 1: apply model_bot_classical, Hcons. intros ? ?. apply valid_T_model_bot; intuition auto with contains_theory.
    Qed.

    Lemma semi_completeness_standard :
      valid_theory T phi -> ~ ~ T ⊢TC phi.
    Proof.
      intros H. apply semi_completeness_standard_classical_model.
      intros D I rho _. apply (H D I rho).
    Qed.

    Definition stable P := ~~P -> P.

    Lemma completeness_standard_stability :
      stable (T ⊢TC phi) -> valid_theory T phi -> T ⊢TC phi.
    Proof.
      intros Hstab Hsem. now apply Hstab, semi_completeness_standard.
    Qed.

    Lemma completeness_classical_stability :
      stable (T ⊢TC phi) -> valid_theory_C (classical (ff := falsity_on)) T phi -> T ⊢TC phi.
    Proof.
      intros Hstab Hsem. now apply Hstab, semi_completeness_standard_classical_model.
    Qed.

    Lemma completeness_standard_stability' :
      (valid_theory_C (classical (ff := falsity_on)) T phi -> T ⊢TC phi) -> stable (T ⊢TC phi).
    Proof.
      intros Hcomp Hdn. apply Hcomp.
      intros D I rho Hclass Hsat. unfold classical in Hclass. cbn in Hclass.
      eapply (Hclass _ _ ⊥). intros Hsat2. exfalso. apply Hdn. intros [A [HA Hc]]. apply Hsat2.
      eapply sound_for_classical_model.
      - easy.
      - exact Hc.
      - intros a Ha. apply Hsat. apply HA, Ha.
    Qed.
  End StandardCompleteness.

  Section ExplodingCompletenessConstr.
    Variables (T : @theory _ _ _ falsity_on).
    Hypothesis (HT : closed_T T).

    Definition expl_interp := (model_bot HT).
    Existing Instance expl_interp.

    Lemma model_expl_correct phi rho :
      (phi[rho] ∈ Out_T (output_bot HT) <-> sat_bot (falsity ∈ Out_T (output_bot HT)) rho phi).
    Proof.
      revert rho. induction phi using form_ind_falsity; intros rho. 1,2,3: cbn.
      - easy.
      - erewrite (Vector.map_ext_in _ _ _ (eval rho)). 1:easy.
        easy.
      - destruct b0. unfold sat_bot in *. rewrite <- IHphi1. rewrite <- IHphi2. apply Out_T_impl.
      - destruct q. cbn. unfold sat_bot in *. setoid_rewrite <- IHphi. setoid_rewrite Out_T_all.
        split; intros H t; asimpl; specialize (H t); now asimpl in H.
    Qed.

    Lemma model_bot_exploding :
      FragmentFacts.exploding (model_bot HT) (falsity ∈ Out_T (output_bot HT)).
    Proof.
      intros rho phi. cbn. intros H. apply model_expl_correct.
      apply (Out_T_impl (output_bot HT) ⊥ (phi[rho])). 2: easy.
      apply Out_T_prv. exists []. split.
      - intros ? [].
      - apply II. apply FragmentND.Exp. apply Ctx. now left.
    Qed.

    Lemma valid_T_model_exploding phi :
      phi ∈ T -> sat_bot (falsity ∈ Out_T (output_bot HT)) var phi.
    Proof.
      intros H % (Out_T_sub (output_bot HT)). apply model_expl_correct. now rewrite subst_id.
    Qed.
  End ExplodingCompletenessConstr.
  Section ExplodingCompleteness.

    #[local] Existing Instance falsity_on | 0.
    Lemma semi_completeness_exploding T phi :
      closed_T T -> closed phi -> valid_exploding_theory T phi -> T ⊢TC phi.
    Proof.
      intros HT Hphi Hval.
      assert (Hcl : closed_T (T ⋄ (¬ phi))).
      1: { intros ? ?; subst; eauto. destruct H as [Hl| ->].
           + apply HT, Hl.
           + repeat econstructor. apply Hphi. }
      apply refutation_prv.
      apply (@Out_T_econsistent _ _ _ (output_bot Hcl)).
      use_theory [⊥]. 2: { apply Ctx. now left. }
      intros ? [<-|[]].
      specialize (Hval term (model_bot Hcl) (falsity ∈ Out_T (output_bot Hcl)) var (@model_bot_exploding _ Hcl)).
      rewrite <- (@subst_id _ _ _ _ ⊥ var). 2: easy.
      apply (@model_expl_correct _ Hcl (¬ phi) var).
      - apply Out_T_sub. cbn. rewrite subst_id. 2:easy. now right.
      - apply Hval. intros psi Hpsi. apply model_expl_correct. rewrite subst_id; [|easy].
        apply Out_T_sub. left. apply Hpsi.
    Qed.

  End ExplodingCompleteness.


  Section FragmentCompleteness.
    #[local] Existing Instance falsity_off | 0.
  End FragmentCompleteness.
 

  Section MPStrongCompleteness.
    Hypothesis mp : MP.
    Variables (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on).
    Hypothesis (HT : closed_T T) (Hphi : closed phi).
    Hypothesis (He : list_enumerable T).

    Lemma mp_tprv_stability :
      ~ ~ T ⊢TC phi -> T ⊢TC phi.
    Proof.
      apply (MP_stable_enumerable mp). 2: apply dec_form; eauto.
      apply list_enumerable_enumerable. destruct He as [L HL]. eexists. apply enum_tprv. apply HL.
      all: cbn; intros ??; unfold dec; decide equality.
    Qed.

    Lemma mp_standard_completeness :
      valid_theory T phi -> T ⊢TC phi.
    Proof.
      apply completeness_standard_stability; eauto. unfold stable.
      apply mp_tprv_stability.
    Qed.
  End MPStrongCompleteness.

(* *** Minimal Models **)

  Section FragmentModel.
    #[local] Existing Instance falsity_off | 0.
    Variable T : theory.
    Hypothesis T_closed : closed_T T.

    Variable GBot : form.
    Hypothesis GBot_closed : closed GBot.

    Definition input_fragment :=
      {|
        NBot := GBot ;
        NBot_closed := GBot_closed ;

        variant := falsity_off ;

        In_T := T ;
        In_T_closed := T_closed ;

        TarskiConstructions.enum := form_enum_with_default GBot;
        TarskiConstructions.enum_enum := form_default_is_enum _;
        TarskiConstructions.enum_bounded := form_default_is_bounded (GBot_closed)
      |}.

    Definition output_fragment := construct_construction input_fragment.

    Instance model_fragment : interp term :=
      {| i_func := func; i_atom := fun P v => atom P v ∈ Out_T output_fragment|}.

    Lemma model_fragment_correct phi rho :
      (phi[rho] ∈ Out_T output_fragment <-> rho ⊨ phi).
    Proof.
      revert rho. unfold model_fragment, output_fragment, input_fragment in *; cbn in *.
      remember falsity_off as ff eqn:Hff.
      induction phi; intros rho. 1,2,3: cbn.
      - split; try tauto. discriminate Hff.
      - erewrite (Vector.map_ext_in _ _ _ (eval rho)). 1:easy.
        easy.
      - destruct b0. rewrite <- IHphi1. rewrite <- IHphi2. apply Out_T_impl. 1-2:congruence.
      - destruct q. cbn. setoid_rewrite <- IHphi. setoid_rewrite Out_T_all. 2:congruence.
        split; intros H t; asimpl; specialize (H t); now asimpl in H.
    Qed.

    Lemma model_fragment_classical :
      classical model_fragment.
    Proof.
      intros rho phi psi. apply model_fragment_correct, Out_T_prv.
      use_theory (nil : list form). apply Pc.
    Qed.

    Lemma valid_T_fragment phi :
      phi ∈ T -> var ⊨ phi.
    Proof.
      intros H % (Out_T_sub output_fragment). apply model_fragment_correct. rewrite subst_id. 1:easy. easy.
    Qed.
  End FragmentModel.

  Section FragmentCompleteness.
    #[local] Existing Instance falsity_off | 0.
    Lemma semi_completeness_fragment T phi :
      closed_T T -> closed phi -> valid_theory T phi -> T ⊢TC phi.
    Proof.
      intros HT Hphi Hval.
      apply (@Out_T_econsistent _ _ _ (@output_fragment T HT phi Hphi)).
      use_theory [phi[var]]. 2: apply Ctx; left; now rewrite subst_id.
      intros ? [<- | []].
      apply (@model_fragment_correct T HT phi Hphi phi var).
      apply Hval. intros psi Hpsi.
      apply valid_T_fragment, Hpsi.
    Qed.
  End FragmentCompleteness.

  Section LEM_Equivalence.
    Definition completeness_arbitrary := 
      forall (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on),
             closed_T T -> closed phi ->
             valid_theory_C (classical (ff := falsity_on)) T phi -> T ⊢TC phi.
    Definition LEM := forall (P:Prop), P \/ ~ P.

    Lemma bot_valid_stable (T : @theory _ _ _ falsity_on) : closed_T T -> stable (valid_theory_C (classical (ff := falsity_on)) T ⊥).
    Proof.
      intros Hclosed HH D I rho Hclass H.
      apply HH. intros Hc. apply (Hc D I rho Hclass H).
    Qed.
    Lemma bot_deriv_stable (T : @theory _ _ _ falsity_on) : completeness_arbitrary -> closed_T T -> stable (@tprv _ _ _ class T ⊥).
    Proof.
      intros Hcomp Hclosed Hc. apply (Hcomp T ⊥). 1: eauto. 1: econstructor.
      apply bot_valid_stable. 1:easy. intros Hd. apply Hc. intros [L [HT HL]]. apply Hd.
      intros D I rho Hclass Harg.
      eapply sound_for_classical_model; try easy. 1: exact HL.
      intros l Hl. apply Harg. now apply HT.
    Qed.
    Existing Instance falsity_on.
    Lemma arbitrary_completeness_is_LEM : completeness_arbitrary -> LEM.
    Proof.
      intros HC P.
      pose (fun x : form => closed x /\ (P \/ ~P)) as T.
      assert (closed_T T) as Hclosed by (intros k; cbv; tauto).
      pose proof (@bot_deriv_stable T HC Hclosed).
      enough (T ⊢TC ⊥) as [[|lx lr] [HL HL']].
      - exfalso. eapply consistent_ND. apply HL'.
      - eapply HL. now left.
      - enough (~~ (P \/ ~P)).
        + apply H. intros Hc. apply H0. intros Hc2. apply Hc. exists [⊥]. split; try (apply Ctx; now left).
          intros ? [<- | []]. cbv. split; try apply Hc2. econstructor.
        + tauto.
    Qed.

    Lemma LEM_is_arbitrary_completeness : LEM -> completeness_arbitrary.
    Proof.
      intros Hlem T phi HT Hphi Hvalid.
      apply completeness_classical_stability; eauto.
      intros H. destruct (Hlem (T ⊢TC phi)); tauto.
    Qed.
  End LEM_Equivalence.

  Section MP_prop_Equivalence.

    Definition Sigma_0_1 {X} (p : X -> Prop) :=
      exists A : X -> nat -> Prop, (forall x n, A x n \/ ~ A x n) /\ forall x, p x <-> exists n, A x n.

    Definition MP_prop := forall A : nat -> Prop, (forall n, A n \/ ~ A n) -> ~~ (exists n, A n) -> exists n, A n.

    Definition MP_pred :=
      forall X, forall p : X -> Prop, Sigma_0_1 p ->
                        forall x, ~~ p x -> p x.

    Lemma MP_prop_to_MP_pred :
      MP_prop -> MP_pred.
    Proof.
      intros mp X p [A [HA H]] x Hx.
      rewrite H in *. eapply mp; eauto.
    Qed.

    Definition completeness_Sigma_0_1 :=
      forall (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on),
             closed_T T -> closed phi -> Sigma_0_1 T ->
             valid_theory_C (classical (ff := falsity_on)) T phi -> T ⊢TC phi.

    Lemma bot_deriv_stable_Sigma_0_1 (T : @theory _ _ _ falsity_on) : completeness_Sigma_0_1 -> closed_T T -> Sigma_0_1 T -> stable (@tprv _ _ _ class T ⊥).
    Proof.
      intros Hcomp Hclosed Hsig Hc. apply (Hcomp T ⊥). 1: eauto. 1: econstructor. auto.
      apply bot_valid_stable. 1:easy. intros Hd. apply Hc. intros [L [HT HL]]. apply Hd.
      intros D I rho Hclass Harg.
      eapply sound_for_classical_model; try easy. 1: exact HL.
      intros l Hl. apply Harg. now apply HT.
    Qed.

    Existing Instance falsity_on.
    Lemma arbitrary_completeness_is_MP_prop : completeness_Sigma_0_1 -> MP_prop.
    Proof.
      intros HC A HA Hneg.
      pose (fun x : form => x = ⊥ /\ exists n, A n) as T.
      assert (closed_T T) as Hclosed. { intros k [-> ?]. econstructor. }
      pose proof (@bot_deriv_stable_Sigma_0_1 T HC Hclosed).
      enough (T ⊢TC ⊥) as [[|lx lr] [HL HL']].
      - exfalso. eapply consistent_ND. apply HL'.
      - subst T. cbn in HL.
        intros. eapply HL. now left.
      - apply H. { exists (fun x n => x = ⊥ /\ A n). split. 2: firstorder.
                   intros x n. destruct (HA n). 2: firstorder.
                   revert x n H0. clear.
                   induction x using form_ind_falsity; cbn; intros; firstorder congruence.
        }
        intros Hc. apply Hneg. intros Hc2. apply Hc. exists [⊥]. split; try (apply Ctx; now left).
        intros ? [<- | []]. cbv. split; try apply Hc2. econstructor.
    Qed.

    Section T_sigma.

      Notation ldec A := (A \/ ~ A).

      Lemma dec_in_ex {X} (p : X -> Prop) L :
        eq_dec X ->
        (forall x, ldec (p x)) ->
        ldec (exists x : X, In x L /\ p x).
      Proof using.
        intros eX dp.
        induction L; cbn.
        - firstorder.
        - destruct IHL. 1: firstorder.
          destruct (dp a).
          + firstorder.
          + right. intros (? & [-> | ] & ?); firstorder.
      Qed.

      Lemma ldec_forall {X} (p : X -> Prop) L :
        eq_dec X ->
        (forall x, ldec (p x)) ->
        ldec (forall x : X, In x L -> p x).
      Proof.
        intros eX dp.
        induction L; cbn.
        - firstorder.
        - destruct IHL.
          + destruct (dp a). 1: left; now firstorder subst. 
            firstorder.
          + firstorder.
      Qed.

      Lemma ldec_bounded (p : nat -> Prop) n :
        (forall m, m <= n -> ldec (p m)) ->
        ldec (exists m, m <= n /\ p m).
      Proof.
        intros dp.
        induction n; cbn.
        - destruct (dp 0). lia. left. exists 0. eauto.
          right. intros (? & ? & ?). inversion H0; subst. auto.
        - destruct IHn.
          + intros. eapply dp. lia.
          + destruct H as (? & ? & ?). left. exists x. split. lia. auto.
          + destruct (dp (S n)). lia.
            left. exists (S n). split. lia. auto.
            right. intros (? & ? & ?). inversion H1; subst. auto.
            apply H. exists x. auto.
      Qed.

      Context {Σ_funcs : funcs_signature} {Σ_preds : preds_signature} [list_Funcs : nat -> list Σ_funcs] (enum_Funcs' : list_enumerator__T list_Funcs Σ_funcs)
        [list_Preds : nat -> list Σ_preds] (enum_Preds' : list_enumerator__T list_Preds Σ_preds) (eq_dec_Funcs : eq_dec Σ_funcs) (eq_dec_Preds : eq_dec Σ_preds)
        {b : falsity_flag} [T : form -> Prop] [L : nat -> list form]  (enum_form : list_enumerator__T L form).
      Context
        { ed_binop : eq_dec binop}
        {ed_quantop : eq_dec quantop}.

      Existing Instance class.

      Hypothesis T_cls : closed_T T.
      Hypothesis A_T : form -> nat -> Prop.
      Hypothesis A_T_cumul : (forall x n1 n2, A_T x n1 -> n2 >= n1 -> A_T x n2).
      Hypothesis HA_T : (forall (x : form) (n : nat), A_T x n \/ ~ A_T x n).
      Hypothesis A_matches_T : (forall x, T x <-> (exists n : nat, A_T x n)).

      Fixpoint A phi n :=
        match n with
        | 0 => False
        | S n => A phi n \/ exists G, In G (L_list L n) /\ (forall phi, In phi G -> exists m, m <= n /\ A_T phi m) /\ In phi (cumul (L_ded enum_Funcs' enum_Preds' eq_dec_Funcs eq_dec_Preds G) n)
        end.

      Lemma or_ldec A B : ldec A -> ldec B -> ldec (A \/ B).
      Proof.
        tauto.
      Qed.

      Lemma and_ldec A B : ldec A -> ldec B -> ldec (A /\ B).
      Proof.
        tauto.
      Qed.

      Lemma cumul_list_max {X} {A : X -> nat -> Prop} L' :
        (forall x n1 n2, A x n1 -> n2 >= n1 -> A x n2) ->
        (forall x, In x L' -> exists n, A x n) ->
        exists m, forall x, In x L' -> A x m.
      Proof using.
        intros Hcumul Hall.
        induction L'.
        - exists 0. firstorder.
        - destruct IHL' as [m Hm].
          + firstorder.
          + destruct (Hall a) as [n Hn]. auto.
            exists (n + m). intros ? [-> | ? % Hm].
            eapply Hcumul. exact Hn. lia.
            eapply Hcumul. exact H. lia.
      Qed.
      
      Theorem T_prv_sig : Sigma_0_1 (fun phi : form => exists A : list form, (forall psi : form, psi el A -> T psi) /\ A ⊢C phi).
      Proof.
        exists A. split.
        - intros x n. revert x.
          induction n; intros x.
          + tauto.
          + eapply or_ldec. eauto.
            eapply dec_in_ex. exact _. intros. eapply and_ldec.
            * eapply ldec_forall.
              eapply dec_form; auto.
              intros. eapply ldec_bounded with (p := A_T x1).
              intros. eapply HA_T.
            * clear - ed_binop ed_quantop. induction n; cbn.
              -- auto.
              --rewrite in_app_iff.
                eapply or_ldec. auto.
                edestruct in_dec.
                2:{ left. exact i. }
                2: auto.
                eapply dec_form; auto.
        - intros phi. split.
          + intros [G [HG H]].
            unshelve edestruct (enumerator__T_list L) as [n Hn].
            exact G. auto.
            setoid_rewrite A_matches_T in HG.
            eapply enum_prv in H as [k Hk].
            eapply cumul_list_max in HG as [m Hm].
            exists (S (S (n + k + m))).  (* add all of the n from HG here *)
            right. exists G. repeat split; auto.
            eapply cum_ge'; eauto. lia.
            intros ? ? % Hm.
            exists m. split; auto. lia.
            eapply cum_ge'. eapply to_cumul_cumulative.
            eapply cumul_In. exact Hk.
            lia. auto.
          + intros [n HA].
            induction n; cbn in *. 
            * auto.
            * destruct HA. 1: eapply IHn; auto.
              destruct H as (G & Gn & Gall & Hphi).
              exists G. split.
              -- intros ? (m & H1 & H2) % Gall.
                 eapply A_matches_T; eauto.
              -- eapply In_cumul in Hphi.
                 eapply enum_prv; eauto.
      Qed.

    End T_sigma.
    
    Lemma Sigma_0_1_cumul X p :
      Sigma_0_1 p ->
      exists A : X -> nat -> Prop,
        (forall x n1 n2, A x n1 -> n2 >= n1 -> A x n2) /\    
        (forall (x : X) (n : nat), A x n \/ ~ A x n) /\
          (forall x : X, p x <-> (exists n : nat, A x n)).
    Proof.
      intros [A [HA Hsig]]. exists (fun x n => exists m, m <= n /\ A x m).
      repeat split.
      - firstorder. eexists. split. 2: eauto. lia.
      - intros. induction n.
        + destruct (HA x 0). 1: firstorder.
          right. intros (? & ? & ?).
          destruct x0; try lia. auto.
        + destruct IHn. left. firstorder lia.
          destruct (HA x (S n)). left. firstorder.
          right. intros (? & ? & ?).
          inversion H1; subst. auto.
          firstorder.
      - rewrite Hsig. firstorder. exists x0. firstorder.
      - rewrite Hsig. firstorder.
    Qed.

    Lemma MP_prop_is_arbitrary_completeness : MP_prop -> completeness_Sigma_0_1.
    Proof.
      intros mp % MP_prop_to_MP_pred T' phi HT Hphi Hvalid.
      edestruct enumT_form' as [eform Hform].
      eexists; eauto.
      eexists; eauto.
      exists (fun _ => Some Impl). red. intros []. now exists 0.
      exists (fun _ => Some All). red. intros []. now exists 0.
      apply completeness_classical_stability; eauto.
      intros H. eapply mp; auto. revert Hvalid.
      unfold tprv. intros.
      eapply Sigma_0_1_cumul in Hvalid.
      destruct Hvalid as [A [Hcumul [HA Hsig]]].
      eapply T_prv_sig; auto.
      1-3: eapply enumerator__T_of_list; eauto.
      exact _.
      exact _.
      auto.
    Qed.

  End MP_prop_Equivalence.

  Section MP_Equivalence.
    Definition completeness_enumerable := 
      forall (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on),
             closed_T T -> closed phi -> enumerable T ->
             valid_theory_C (classical (ff := falsity_on)) T phi -> T ⊢TC phi.

    Lemma bot_deriv_stable_enum (T : @theory _ _ _ falsity_on) : completeness_enumerable -> closed_T T -> enumerable T ->
      stable (@tprv _ _ _ class T ⊥).
    Proof.
      intros Hcomp Hclosed Henum Hc. apply (Hcomp T ⊥). 1: eauto. 1: econstructor. 1: apply Henum.
      apply bot_valid_stable. 1:easy. intros Hd. apply Hc. intros [L [HT HL]]. apply Hd.
      intros D I rho Hclass Harg.
      eapply sound_for_classical_model; try easy. 1: exact HL.
      intros l Hl. apply Harg. now apply HT.
    Qed.
    Existing Instance falsity_on.

    Lemma MP_is_enumerable_completeness : MP -> completeness_enumerable.
    Proof.
      intros Hmp T phi HT Hphi Henum Hvalid.
      apply completeness_classical_stability; eauto. unfold stable.
      eapply mp_tprv_stability; try tauto. now eapply enumerable_list_enumerable.
    Qed.

    Lemma enumerable_completeness_is_MP : completeness_enumerable -> MP.
    Proof.
      intros HC f Hf.
      pose (fun x : form => exists n, x = ⊥ /\ f n = true) as T.
      assert (closed_T T) as Hclosed by now intros k [n [-> Hn]].
      assert (enumerable T) as Henum.
      { exists (fun n => if f n then Some (⊥) else None). intros phi; split; intros H.
        + destruct H as (n & Heq & Hfn). exists n. rewrite Hfn. now rewrite Heq.
        + destruct H as (n & Hn). unfold T. exists n. destruct (f n); try congruence.
          split; try easy. congruence.
       }
      pose proof (@bot_deriv_stable_enum T HC Hclosed Henum).
      enough (T ⊢TC ⊥) as [[|lx lr] [HL HL']].
      - exfalso. eapply consistent_ND. apply HL'.
      - destruct (HL lx) as (n & Heq & Hfn). 1:now left. now exists n.
      - apply H. intros Hc. apply Hf. intros [n Hn]. apply Hc. exists [⊥]. split.
        + intros ? [<- | []]. unfold T. exists n. split; try easy.
        + apply Ctx; now left.
    Qed.

  End MP_Equivalence.

End Completeness.

(* ** Extending the Completeness Results *)
(*
Section FiniteCompleteness.
  Context {Sigma : Signature}.
  Context {HdF : eq_dec Funcs} {HdP : eq_dec Preds}.
  Context {HeF : enumT Funcs} {HeP : enumT Preds}.

  Lemma list_completeness_standard A phi :
    ST__f -> valid_L SM A phi -> A ⊢CE phi.
  Proof.
    intros stf Hval % valid_L_to_single. apply prv_from_single.
    apply con_T_correct. apply completeness_standard_stability.
    1: intros ? ? []. 1: apply close_closed. 2: now apply valid_L_valid_T in Hval.
    apply stf, fin_T_con_T.
    - intros ? ? [].
    - eapply close_closed.
  Qed.

  Lemma list_completeness_expl A phi :
    valid_L EM A phi -> A ⊢CE phi.
  Proof.
    intros Hval % valid_L_to_single. apply prv_from_single.
    apply tprv_list_T. apply completeness_expl. 1: intros ? ? [].
    1: apply close_closed. now apply valid_L_valid_T in Hval.
  Qed.

  Lemma list_completeness_fragment A phi :
    valid_L BLM A phi -> A ⊢CL phi.
  Proof.
    intros Hval % valid_L_to_single. apply prv_from_single.
    apply tprv_list_T. apply semi_completeness_fragment. 1: intros ? ? [].
    1: apply close_closed. now apply valid_L_valid_T in Hval.
  Qed.
End FiniteCompleteness.

Section StrongCompleteness.
  Context {Sigma : Signature}.
  Context {HdF : eq_dec Funcs} {HdP : eq_dec Preds}.
  Context {HeF : enumT Funcs} {HeP : enumT Preds}.

  Lemma dn_inherit (P Q : Prop) :
    (P -> Q) -> ~ ~ P -> ~ ~ Q.
  Proof. tauto. Qed.

  Lemma strong_completeness_standard (S : stab_class) T phi :
    (forall (T : theory) (phi : form), S Sigma T -> stable (tmap (fun psi : form => (sig_lift psi)[ext_c]) T ⊢TC phi)) -> @map_closed S Sigma (sig_ext Sigma) (fun phi => (sig_lift phi)[ext_c]) -> S Sigma T -> T ⊫S phi -> T ⊢TC phi.
  Proof.
    intros sts cls HT Hval. apply sig_lift_out_T. apply completeness_standard_stability.
    1: apply lift_ext_c_closes_T. 1: apply lift_ext_c_closes. 2: apply (sig_lift_subst_valid droppable_S Hval).
    now apply sts.
  Qed.

  Lemma strong_completeness_expl T phi :
    T ⊫E phi -> T ⊢TC phi.
  Proof.
    intros Hval. apply sig_lift_out_T, completeness_expl.
    1: apply lift_ext_c_closes_T. 1: apply lift_ext_c_closes.
    apply (sig_lift_subst_valid droppable_E Hval).
  Qed.

  Lemma strong_completeness_fragment T phi :
    T ⊫M phi -> T ⊩CL phi.
  Proof.
    intros Hval. apply sig_lift_out_T, semi_completeness_fragment.
    1: apply lift_ext_c_closes_T. 1: apply lift_ext_c_closes.
    apply (sig_lift_subst_valid droppable_BL Hval).
  Qed.

End StrongCompleteness.

*)
