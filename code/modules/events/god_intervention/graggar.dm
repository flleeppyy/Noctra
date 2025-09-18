/// Tracks culling pairings
GLOBAL_LIST_EMPTY(graggar_cullings)

/datum/culling_duel
	var/datum/weakref/challenger
	var/datum/weakref/target
	var/datum/weakref/challenger_heart
	var/datum/weakref/target_heart

/datum/culling_duel/New(mob/challenger, mob/target)
	. = ..()
	src.challenger = WEAKREF(challenger)
	src.target = WEAKREF(target)
	var/obj/item/organ/heart/c_heart = challenger.getorganslot(ORGAN_SLOT_HEART)
	var/obj/item/organ/heart/t_heart = target.getorganslot(ORGAN_SLOT_HEART)
	src.challenger_heart = WEAKREF(c_heart)
	src.target_heart = WEAKREF(t_heart)

/datum/culling_duel/Destroy()
	GLOB.graggar_cullings -= src
	return ..()

/datum/culling_duel/proc/handle_heart_destroyed(which_heart)
	var/mob/living/carbon/human/winner
	var/mob/living/carbon/human/loser

	if(which_heart == "target")
		winner = challenger.resolve()
		loser = target.resolve()
	else if(which_heart == "challenger")
		winner = target.resolve()
		loser = challenger.resolve()

	if(winner)
		winner.remove_stress(/datum/stress_event/graggar_culling_unfinished)
		winner.verbs -= /mob/living/carbon/human/proc/remember_culling
		winner.add_stress(/datum/stress_event/graggar_culling_finished)
		to_chat(winner, span_notice("Your rival's heart has been DESTROYED! While not the glorious consumption Graggar desired, he acknowledges you as not weak."))
		winner.adjust_triumphs(1)
	if(loser)
		loser.remove_stress(/datum/stress_event/graggar_culling_unfinished)
		loser.verbs -= /mob/living/carbon/human/proc/remember_culling
		to_chat(loser, span_red("You have FAILED Graggar for the LAST TIME!"))
		loser.gib()

	qdel(src)

/datum/culling_duel/proc/process_win(mob/living/winner, mob/living/loser)
	winner.remove_stress(/datum/stress_event/graggar_culling_unfinished)
	winner.verbs -= /mob/living/carbon/human/proc/remember_culling
	winner.set_stat_modifier("graggar_culling", STATKEY_STR, 2)
	winner.set_stat_modifier("graggar_culling", STATKEY_END, 2)
	winner.set_stat_modifier("graggar_culling", STATKEY_CON, 2)
	winner.set_stat_modifier("graggar_culling", STATKEY_PER, 2)
	winner.set_stat_modifier("graggar_culling", STATKEY_INT, 2)
	winner.set_stat_modifier("graggar_culling", STATKEY_SPD, 2)
	winner.set_stat_modifier("graggar_culling", STATKEY_LCK, 2)
	to_chat(winner, span_notice("You have proven your strength to Graggar by consuming your rival's heart! Your rival's power is now YOURS!"))
	winner.adjust_triumphs(3)
	winner.add_stress(/datum/stress_event/graggar_culling_finished)
	winner.playsound_local(winner, 'sound/misc/gods/graggar_omen.ogg', 100)

	if(loser)
		loser.remove_stress(/datum/stress_event/graggar_culling_unfinished)
		loser.verbs -= /mob/living/carbon/human/proc/remember_culling
		to_chat(loser, span_boldred("You have FAILED Graggar for the LAST TIME!"))
		loser.gib()

	qdel(src)

/// Verb for the graggar's culling contestants to remember their targets
/mob/living/carbon/human/proc/remember_culling()
	set name = "Graggar's Culling"
	set category = "Graggar"
	if(!mind)
		return
	mind.recall_culling(src)

/datum/round_event_control/graggar_culling
	name = "Graggar's Culling"
	track = EVENT_TRACK_INTERVENTION
	typepath = /datum/round_event/graggar_culling
	weight = 8
	earliest_start = 20 MINUTES
	max_occurrences = 1
	min_players = 35
	allowed_storytellers = list(/datum/storyteller/graggar)

/datum/round_event_control/graggar_culling/canSpawnEvent(players_amt, gamemode, fake_check)
	. = ..()
	if(!.)
		return FALSE
	if(GLOB.patron_follower_counts["Graggar"] < 3)
		return FALSE

/datum/round_event/graggar_culling/start()
	var/list/contenders = list()
	for(var/mob/living/carbon/human/human_mob in GLOB.player_list)
		if(!istype(human_mob) || human_mob.stat == DEAD || !human_mob.client)
			continue

		if(!human_mob.patron || !istype(human_mob.patron, /datum/patron/inhumen/graggar))
			continue

		var/obj/item/organ/heart/heart = human_mob.getorganslot(ORGAN_SLOT_HEART)
		if(!heart)
			continue

		contenders += human_mob

	if(length(contenders) < 2)
		return

	// 33% chance for grand culling (multiple pairs) unless ascendant, then it's guaranteed
	var/grand_culling = is_ascendant(EORA) || prob(33)
	var/max_pairs = grand_culling ? floor(length(contenders) / 2) : 1

	for(var/i in 1 to max_pairs)
		if(length(contenders) < 2)
			break

		var/mob/living/carbon/human/first_chosen = pick_n_take(contenders)
		var/mob/living/carbon/human/second_chosen = pick_n_take(contenders)

		var/datum/culling_duel/new_duel = new(first_chosen, second_chosen)
		GLOB.graggar_cullings += new_duel

		var/first_chosen_location = first_chosen.prepare_deathsight_message()
		var/second_chosen_location = second_chosen.prepare_deathsight_message()

		// Notify first chosen
		first_chosen.add_stress(/datum/stress_event/graggar_culling_unfinished)
		first_chosen.add_spell(/datum/action/cooldown/spell/extract_heart)
		first_chosen.verbs |= /mob/living/carbon/human/proc/remember_culling
		to_chat(first_chosen, span_userdanger("YOU ARE GRAGGAR'S CONTESTANT!"))
		to_chat(first_chosen, span_red("Weak should feed the strong, that is Graggar's will. Prove that you are not weak by eating the heart of [span_notice(second_chosen.real_name)], the [second_chosen.job] and gain unimaginable power in turn. Fail, and you will be the one eaten."))
		to_chat(first_chosen, span_red("[span_notice("[second_chosen.real_name]")], the [second_chosen.job] is somewhere in [span_notice("[second_chosen_location]")]. Eat their heart before they eat yours!"))
		if(grand_culling)
			to_chat(first_chosen, span_notice("Graggar has decreed a GRAND CULLING! Many hearts will feed the strong todae!"))
		first_chosen.playsound_local(first_chosen, 'sound/misc/gods/graggar_omen.ogg', 100)

		// Notify second chosen
		second_chosen.add_stress(/datum/stress_event/graggar_culling_unfinished)
		second_chosen.add_spell(/datum/action/cooldown/spell/extract_heart)
		second_chosen.verbs |= /mob/living/carbon/human/proc/remember_culling
		to_chat(second_chosen, span_userdanger("YOU ARE GRAGGAR'S CONTESTANT!"))
		to_chat(second_chosen, span_red("Weak should feed the strong, that is Graggar's will. Prove that you are not weak by eating the heart of [span_notice(first_chosen.real_name)], the [first_chosen.job] and gain unimaginable power in turn. Fail, and you will be the one eaten."))
		to_chat(second_chosen, span_red("[span_notice("[first_chosen.real_name]")], the [first_chosen.job] is somewhere in [span_notice("[first_chosen_location]")]. Eat their heart before they eat yours!"))
		if(grand_culling)
			to_chat(second_chosen, span_notice("Graggar has decreed a GRAND CULLING! Many hearts will feed the strong todae!"))
		second_chosen.playsound_local(second_chosen, 'sound/misc/gods/graggar_omen.ogg', 100)
